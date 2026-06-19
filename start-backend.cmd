@echo off
cd /d "%~dp0universal-sql-transpiler\backend"
echo Starting Universal SQL Transpiler backend on http://localhost:8000 ...
echo Press Ctrl+C to stop.
python -m uvicorn app.main:app --reload --port 8000 --host 0.0.0.0
