#!/usr/bin/env bash
# =============================================================================
# Universal SQL Transpiler — Linux / macOS Setup Script
# =============================================================================
# Prerequisites: Python 3.11+, Node.js 18+, pip
# Run from the project root:  bash setup.sh
# =============================================================================

set -euo pipefail

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'; RESET='\033[0m'

step()  { echo -e "\n${CYAN}==> $*${RESET}"; }
ok()    { echo -e "    ${GREEN}OK  $*${RESET}"; }
fail()  { echo -e "    ${RED}ERR $*${RESET}"; exit 1; }

echo ""
echo -e "${MAGENTA}  Universal SQL Transpiler — Setup${RESET}"
echo -e "${MAGENTA}  ==================================${RESET}"
echo ""

# -----------------------------------------------------------------------------
# 1. Check Python >= 3.11
# -----------------------------------------------------------------------------
step "Checking Python version..."

PYTHON_CMD=""
for cmd in python3 python; do
    if command -v "$cmd" &>/dev/null; then
        ver=$("$cmd" --version 2>&1)
        # Extract major.minor
        if echo "$ver" | grep -qP 'Python 3\.(1[1-9]|[2-9]\d)'; then
            PYTHON_CMD="$cmd"
            ok "$ver  (using '$cmd')"
            break
        fi
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    fail "Python 3.11+ not found. Install via https://www.python.org/downloads/ or your package manager."
fi

# -----------------------------------------------------------------------------
# 2. Check Node.js >= 18
# -----------------------------------------------------------------------------
step "Checking Node.js version..."

if ! command -v node &>/dev/null; then
    fail "Node.js not found. Install from https://nodejs.org/en/download (LTS recommended)."
fi

NODE_VER=$(node --version)
NODE_MAJOR=$(echo "$NODE_VER" | grep -oP '\d+' | head -1)
if [ "$NODE_MAJOR" -lt 18 ]; then
    fail "Node.js 18+ required, found $NODE_VER"
fi
ok "Node.js $NODE_VER"

# -----------------------------------------------------------------------------
# 3. Backend — create virtual environment
# -----------------------------------------------------------------------------
step "Creating Python virtual environment in backend/.venv ..."

VENV="backend/.venv"
if [ -f "$VENV/bin/python" ]; then
    ok "Virtual environment already exists — skipping creation"
else
    "$PYTHON_CMD" -m venv "$VENV"
    ok "Created $VENV"
fi

PIP="$VENV/bin/pip"
PYTHON="$VENV/bin/python"

# -----------------------------------------------------------------------------
# 4. Backend — install Python dependencies
# -----------------------------------------------------------------------------
step "Installing Python dependencies..."

"$PIP" install --upgrade pip --quiet
"$PIP" install -r backend/requirements.txt --quiet
ok "All Python packages installed"

# -----------------------------------------------------------------------------
# 5. Frontend — install Node dependencies
# -----------------------------------------------------------------------------
step "Installing Node.js dependencies..."

(cd frontend && npm install --prefer-offline 2>&1 | tail -5)
ok "node_modules installed"

# -----------------------------------------------------------------------------
# 6. Smoke test — import the transpiler
# -----------------------------------------------------------------------------
step "Running smoke test..."

SMOKE=$(PYTHONPATH=backend "$PYTHON" -c "
from app.transpiler import Transpiler
dialects = Transpiler.supported_dialects()
print(f'Loaded {len(dialects)} dialects: {dialects}')
" 2>&1) || fail "Smoke test failed:\n$SMOKE"
ok "$SMOKE"

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
echo ""
echo -e "${GREEN}  Setup complete!${RESET}"
echo ""
echo -e "${YELLOW}  HOW TO RUN  (local development)${RESET}"
echo    "  --------------------------------"
echo    "  Backend  (terminal 1):"
echo    "    cd backend"
echo    "    source .venv/bin/activate"
echo    "    uvicorn app.main:app --reload"
echo ""
echo    "  Frontend (terminal 2):"
echo    "    cd frontend"
echo    "    npm run dev"
echo ""
echo    "  Open: http://localhost:5173"
echo    "  API:  http://localhost:8000/api/docs"
echo ""
echo    "  HOW TO RUN  (Docker)"
echo    "  --------------------"
echo    "  docker compose up --build"
echo    "  Open: http://localhost:80"
echo ""
echo    "  HOW TO TEST"
echo    "  -----------"
echo    "  cd backend && source .venv/bin/activate && pytest"
echo    "  Regenerate golden snapshots:  pytest --regen-golden"
echo ""
