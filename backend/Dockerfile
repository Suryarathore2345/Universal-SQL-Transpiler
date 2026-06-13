# ── Universal SQL Transpiler — Backend ──────────────────────────────────────
# Official Python base image docs: https://hub.docker.com/_/python
FROM python:3.12-slim

WORKDIR /app

# Install deps first for layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source
COPY app/ ./app/

# Expose the FastAPI port
EXPOSE 8000

# Run with uvicorn; workers=1 keeps it simple for the container
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
