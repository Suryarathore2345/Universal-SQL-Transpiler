@echo off
cd /d "%~dp0backend"
echo Starting Universal SQL Transpiler backend on http://localhost:8000 ...
echo Press Ctrl+C to stop.
if exist ".venv\Scripts\python.exe" (
    .venv\Scripts\python.exe -m uvicorn app.main:app --reload --port 8000 --host 0.0.0.0
) else (
    python -m uvicorn app.main:app --reload --port 8000 --host 0.0.0.0
)
