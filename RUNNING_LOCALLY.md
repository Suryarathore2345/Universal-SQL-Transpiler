# Running the Universal SQL Transpiler Locally (PowerShell)

Two servers, two terminals: backend (FastAPI, port 8000) and frontend (Vite, port 5173).
The frontend proxies `/api/*` to the backend, so **start the backend first**.

All commands below are relative to the repository root (the directory containing this file).

---

## Terminal 1 — Backend

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

You should see:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
... UST started — N dialects loaded
INFO:     Application startup complete.
```

Leave this terminal running. Verify it's alive (optional, in any terminal):
```powershell
curl http://127.0.0.1:8000/api/dialects
```

> If `.\.venv\Scripts\Activate.ps1` fails with a script-execution error, run this once (per PowerShell session, or permanently with `-Scope CurrentUser`):
> ```powershell
> Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
> ```

> If the `.venv` folder doesn't exist yet, create it first:
> ```powershell
> cd backend
> python -m venv .venv
> .\.venv\Scripts\Activate.ps1
> pip install -r requirements.txt
> ```

---

## Terminal 2 — Frontend

Open a **new** PowerShell window/tab (keep the backend running in Terminal 1), starting again from the repository root:

```powershell
cd frontend
npm run dev
```

You should see:
```
VITE v5.4.21  ready in ... ms
➜  Local:   http://localhost:5173/
```

> If `node_modules` is missing or you get module-not-found errors:
> ```powershell
> cd frontend
> npm install
> npm run dev
> ```

---

## Use it

Open **http://localhost:5173/** in your browser.

If you see `http proxy error: ECONNREFUSED` in the frontend terminal, it means the backend (Terminal 1) isn't running — go back and start it first, then refresh the page.

---

## Stopping everything

In each terminal, press `Ctrl+C` to stop the server. Then optionally:
```powershell
deactivate
```
to exit the Python virtual environment in Terminal 1.

---

## Running the backend test suite

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
python -m pytest tests/ -q
```

---

## Quick start (Windows convenience scripts)

From the repository root, `start-backend.cmd` and `start-frontend.cmd` wrap the two commands above (each `cd`s to the correct subfolder relative to its own location, so they work regardless of where the repo is cloned).
