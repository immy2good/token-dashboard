FROM python:3.12-slim

# Create non-root user
RUN useradd -m -u 1000 appuser

WORKDIR /app

# Copy project files
COPY --chown=appuser:appuser . .

# Set environment variables
ENV HOST=0.0.0.0 \
    PORT=8080 \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Create directories for data persistence
RUN mkdir -p /claude/projects && \
    chown -R appuser:appuser /claude

# Switch to non-root user
USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080').close()" || exit 1

CMD ["python", "cli.py", "dashboard", "--no-open"]
