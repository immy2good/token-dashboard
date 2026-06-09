# Bug Fixes Applied

All 7 bugs identified in the code review have been fixed. Here's what was corrected:

## Fixed Issues

### 1. ✅ IndexError in `scanner.py` – Missing empty-parts check
**File:** `token_dashboard/scanner.py`, `_project_slug()` function
- **Issue:** `return rel.parts[0]` would crash if a JSONL file is directly in `projects_root`
- **Fix:** Added check for empty `rel.parts`, returns `"root"` as fallback slug
```python
def _project_slug(file_path: Path, projects_root: Path) -> str:
    rel = file_path.relative_to(projects_root)
    if not rel.parts:
        return "root"
    return rel.parts[0]
```

---

### 2. ✅ Path Traversal Vulnerability in `server.py` – Weak symlink/escape check
**File:** `token_dashboard/server.py`, `_serve_static()` function
- **Issue:** String prefix matching was brittle; path escapes could bypass the check
- **Fix:** Replaced string prefix check with `Path.relative_to()` for robust validation
```python
try:
    p.relative_to(WEB_ROOT.resolve())
except ValueError:
    handler.send_response(404)
    handler.end_headers()
    return
```

---

### 3. ✅ Integer Parsing Without Error Handling in `cli.py`
**File:** `cli.py`, `cmd_dashboard()` function
- **Issue:** `int(os.environ.get("PORT", "8080"))` would crash on invalid PORT values
- **Fix:** Added `_get_port()` helper with try/except and stderr warning
```python
def _get_port(default: int = 8080) -> int:
    try:
        return int(os.environ.get("PORT", str(default)))
    except ValueError:
        print(f"Warning: PORT environment variable is not a valid integer, using {default}", file=sys.stderr)
        return default
```

---

### 4. ✅ Missing Dictionary Key Defaults in `pricing.py`
**File:** `token_dashboard/pricing.py`, `cost_for()` function
- **Issue:** `rates["cache_create_5m"]` etc. would cause `KeyError` if pricing.json is incomplete
- **Fix:** Changed all dictionary accesses to use `.get()` with default value of `0`
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

### 5. ✅ Silent Truncation in `scanner.py` – Data Loss Warning
**File:** `token_dashboard/scanner.py`, `_target()` function
- **Issue:** Long file paths/URLs truncated to 500 chars without any warning
- **Fix:** Added warning message to stderr when truncation occurs
```python
def _target(name: str, inp: dict) -> Optional[str]:
    MAX_LEN = 500
    field = _TARGET_FIELDS.get(name)
    if field and isinstance(inp, dict):
        v = inp.get(field)
        if isinstance(v, str):
            if len(v) > MAX_LEN:
                print(f"Warning: {name} target truncated from {len(v)} to {MAX_LEN} chars", file=sys.stderr)
            return v[:MAX_LEN]
    return None
```

---

### 6. ✅ SSE Stream Error Handling in `server.py`
**File:** `token_dashboard/server.py`, SSE stream endpoint
- **Issue:** Limited exception handling on client disconnect
- **Fix:** Added `OSError` to exception tuple and logging for debugging
```python
except (BrokenPipeError, ConnectionResetError, OSError) as e:
    logging.debug(f"SSE client disconnected: {e}")
    return
```

---

### 7. ✅ Improved Import for Logging
**File:** `token_dashboard/server.py`
- **Issue:** Missing logging import for SSE debugging
- **Fix:** Added `import logging` and `import sys` where needed

---

## Verification

All fixed files have been validated with `python3 -m py_compile`:
- ✅ `cli.py`
- ✅ `token_dashboard/scanner.py`
- ✅ `token_dashboard/server.py`
- ✅ `token_dashboard/pricing.py`

No syntax errors detected.

## Summary

| Bug | Severity | Status |
|-----|----------|--------|
| IndexError in _project_slug | High | ✅ Fixed |
| Path traversal weakness | High | ✅ Fixed |
| Port parsing crash | Medium | ✅ Fixed |
| Missing dict defaults | Medium | ✅ Fixed |
| Silent truncation | Low-Medium | ✅ Fixed |
| SSE error handling | Low | ✅ Fixed |
| Logging improvements | Low | ✅ Fixed |

All code is now more robust and production-ready.
