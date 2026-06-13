# Universal SQL Transpiler — Frontend

React + Vite + Monaco Editor frontend.

## Quick start

```bash
# 1. Install dependencies
npm install

# 2. Start the FastAPI backend first (in a separate terminal)
#    cd ../backend && uvicorn app.main:app --reload --port 8000

# 3. Start the dev server
npm run dev
# → opens at http://localhost:5173
```

## Build for production

```bash
npm run build
# Output in dist/
```

## Environment

The Vite dev server proxies `/api` to `http://localhost:8000` automatically.
No CORS configuration needed in development.
