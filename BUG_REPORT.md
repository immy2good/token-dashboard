# Code Review: Bug Report

## Critical Bugs

### 1. **IndexError in `scanner.py` – Missing empty-parts check**
**File:** `token_dashboard/scanner.py`, line 169
**Severity:** High
**Issue:** 
```python
def _project_slug(file_path: Path, projects_root: Path) -> str:
    rel = file_path.relative_to(projects_root)
    return rel.parts[0]  # ❌ IndexError if rel.parts is empty
```
If a JSONL file is directly in `projects_root` (not in a subdirectory), `rel.parts` will be empty.

**Fix:**
```python
def _project_slug(file_path: Path, projects_root: Path) -> str:
    rel = file_path.relative_to(projects_root)
    if not rel.parts:
        return "root"  # Or raise a more informative error
    return rel.parts[0]
```

---

### 2. **Path Traversal Vulnerability in `server.py` – Weak symlink/escape check**
**File:** `token_dashboard/server.py`, line 91
**Severity:** High
**Issue:**
```python
p = (WEB_ROOT / rel).resolve()
if not str(p).startswith(str(WEB_ROOT.resolve())) or not p.is_file():
```
String prefix matching is brittle. Relative path escapes like `../../../etc/passwd` could potentially bypass the check.

**Fix (Python 3.9+):**
```python
p = (WEB_ROOT / rel).resolve()
try:
    p.relative_to(WEB_ROOT.resolve())  # Raises ValueError if not a child
except ValueError:
    handler.send_response(404)
    handler.end_headers()
    return
if not p.is_file():
    handler.send_response(404)
    handler.end_headers()
    return
```

Or use `os.path.commonpath()` for earlier Python versions.

---

### 3. **Integer Parsing Without Error Handling in `cli.py`**
**File:** `token_dashboard/cli.py`, line 56
**Severity:** Medium
**Issue:**
```python
port = int(os.environ.get("PORT", "8080"))
```
If `PORT` env var is set to a non-integer (e.g., "abc"), the program crashes without a helpful message.

**Fix:**
```python
def _get_port(default: int = 8080) -> int:
    try:
        return int(os.environ.get("PORT", str(default)))
    except ValueError:
        print(f"Warning: PORT env var is not an integer, using {default}")
        return default

# In cmd_dashboard():
port = _get_port()
```

---

### 4. **Missing Dictionary Key Defaults in `pricing.py`**
**File:** `token_dashboard/pricing.py`, lines 47–50
**Severity:** Medium
**Issue:**
```python
bd = {
    "input":           usage["input_tokens"]            * rates["input"]           / 1_000_000,
    "output":          usage["output_tokens"]           * rates["output"]          / 1_000_000,
    "cache_read":      usage["cache_read_tokens"]       * rates["cache_read"]      / 1_000_000,
    "cache_create_5m": usage["cache_create_5m_tokens"]  * rates["cache_create_5m"] / 1_000_000,
    "cache_create_1h": usage["cache_create_1h_tokens"]  * rates["cache_create_1h"] / 1_000_000,
}
```
If `pricing.json` is missing `cache_create_5m` or `cache_create_1h` keys, `KeyError` will crash the server.

**Fix:**
```python
bd = {
    "input":           usage.get("input_tokens", 0)            * rates.get("input", 0)           / 1_000_000,
    "output":          usage.get("output_tokens", 0)           * rates.get("output", 0)          / 1_000_000,
    "cache_read":      usage.get("cache_read_tokens", 0)       * rates.get("cache_read", 0)      / 1_000_000,
    "cache_create_5m": usage.get("cache_create_5m_tokens", 0)  * rates.get("cache_create_5m", 0) / 1_000_000,
    "cache_create_1h": usage.get("cache_create_1h_tokens", 0)  * rates.get("cache_create_1h", 0) / 1_000_000,
}
```

---

### 5. **Silent Truncation in `scanner.py` – Data Loss**
**File:** `token_dashboard/scanner.py`, line 106
**Severity:** Low-Medium
**Issue:**
```python
def _target(name: str, inp: dict) -> Optional[str]:
    field = _TARGET_FIELDS.get(name)
    if field and isinstance(inp, dict):
        v = inp.get(field)
        if isinstance(v, str):
            return v[:500]  # ⚠️ Silent truncation
    return None
```
Long file paths or URLs are silently truncated to 500 chars, potentially losing critical information without any warning.

**Fix:**
```python
def _target(name: str, inp: dict) -> Optional[str]:
    MAX_LEN = 500
    field = _TARGET_FIELDS.get(name)
    if field and isinstance(inp, dict):
        v = inp.get(field)
        if isinstance(v, str):
            if len(v) > MAX_LEN:
                print(f"Warning: {name} target truncated from {len(v)} to {MAX_LEN} chars")
            return v[:MAX_LEN]
    return None
```

---

## Minor Issues

### 6. **SSE Stream Error Handling**
**File:** `token_dashboard/server.py`, lines 186–196
**Severity:** Low
**Issue:** While `BrokenPipeError` and `ConnectionResetError` are caught, other exceptions could occur (e.g., `OSError` on Windows). The broad exception handling is adequate, but logging would help debugging.

**Fix:** Add logging:
```python
import logging
except (BrokenPipeError, ConnectionResetError, OSError) as e:
    logging.debug(f"SSE client disconnected: {e}")
    return
```

---

### 7. **Incomplete Type Hints**
**File:** Various files
**Severity:** Low
**Issue:** Some functions lack type hints for better IDE support and documentation.

**Example fix in `scanner.py`:**
```python
def scan_file(path: Path, project_slug: str, conn: sqlite3.Connection, start_byte: int = 0) -> dict:
```

---

## Summary

| Bug | File | Severity | Impact |
|-----|------|----------|--------|
| Missing empty-parts check | `scanner.py` | High | Crash on files in root directory |
| Path traversal weak check | `server.py` | High | Potential file disclosure |
| Port parsing crash | `cli.py` | Medium | Crash on bad env var |
| Missing dict defaults | `pricing.py` | Medium | Crash on incomplete pricing.json |
| Silent truncation | `scanner.py` | Low-Medium | Data loss without warning |
| SSE error logging | `server.py` | Low | Harder debugging |
| Type hints | Multiple | Low | Reduced IDE support |

