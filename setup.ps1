# =============================================================================
# Universal SQL Transpiler - Windows Setup Script (PowerShell)
# =============================================================================
# Prerequisites: Python 3.11+, Node.js 18+
# Run from the project root:  .\setup.ps1
# =============================================================================

# Use Continue so that native-command stderr does not throw terminating errors.
# We check $LASTEXITCODE manually after each critical command instead.
$ErrorActionPreference = "Continue"

function Write-Step { param([string]$msg) Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-OK   { param([string]$msg) Write-Host "    [OK]  $msg" -ForegroundColor Green }
function Fail       { param([string]$msg) Write-Host "`n    [ERR] $msg`n" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "  Universal SQL Transpiler - Setup" -ForegroundColor Magenta
Write-Host "  ==================================" -ForegroundColor Magenta
Write-Host ""

# -----------------------------------------------------------------------------
# 1. Check Python >= 3.11
# -----------------------------------------------------------------------------
Write-Step "Checking Python version..."

$pythonCmd = $null
foreach ($cmd in @("python", "python3", "py")) {
    $ver = & $cmd --version 2>&1
    if ($LASTEXITCODE -eq 0 -and "$ver" -match "Python (\d+)\.(\d+)") {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        if ($major -eq 3 -and $minor -ge 11) {
            $pythonCmd = $cmd
            Write-OK "$ver  (using '$cmd')"
            break
        }
    }
}

if (-not $pythonCmd) {
    Fail "Python 3.11+ not found. Download from https://www.python.org/downloads/"
}

# -----------------------------------------------------------------------------
# 2. Check Node.js >= 18
# -----------------------------------------------------------------------------
Write-Step "Checking Node.js version..."

# Check standard PATH first, then common portable / per-user locations
$nodeLocations = @(
    "node",
    "$env:USERPROFILE\node\node.exe",
    "$env:APPDATA\npm\node.exe",
    "$env:ProgramFiles\nodejs\node.exe",
    "${env:ProgramFiles(x86)}\nodejs\node.exe"
)

$nodeFound = $false
foreach ($loc in $nodeLocations) {
    $nodeVer = & $loc --version 2>&1
    if ($LASTEXITCODE -eq 0 -and "$nodeVer" -match "v(\d+)") {
        $nodeMajor = [int]$Matches[1]
        if ($nodeMajor -ge 18) {
            $nodeFound = $true
            Write-OK "Node.js $nodeVer  (at '$loc')"
            # Add folder to PATH so npm works for the rest of this session
            $nodeDir = Split-Path $loc -Parent
            if ($env:PATH -notlike "*$nodeDir*") {
                $env:PATH = "$nodeDir;$env:PATH"
            }
            break
        }
    }
}

if (-not $nodeFound) {
    Fail "Node.js 18+ not found. Download from https://nodejs.org/en/download (LTS recommended)."
}

# -----------------------------------------------------------------------------
# 3. Backend - create virtual environment
# -----------------------------------------------------------------------------
Write-Step "Creating Python virtual environment in backend\.venv ..."

$venvPath  = "backend\.venv"
$venvPy    = "$venvPath\Scripts\python.exe"

if (Test-Path $venvPy) {
    Write-OK "Virtual environment already exists - skipping creation"
} else {
    & $pythonCmd -m venv $venvPath
    if ($LASTEXITCODE -ne 0) { Fail "Failed to create virtual environment." }
    Write-OK "Created $venvPath"
}

# -----------------------------------------------------------------------------
# 4. Backend - install Python dependencies
# -----------------------------------------------------------------------------
Write-Step "Installing Python dependencies..."

# --trusted-host flags work around a Windows pip bug where paths containing
# spaces (e.g. OneDrive folders) prevent pip from finding its TLS CA bundle.
& $venvPy -m pip install -r backend\requirements.txt `
    --trusted-host pypi.org `
    --trusted-host pypi.python.org `
    --trusted-host files.pythonhosted.org `
    2>&1 | Where-Object { "$_" -notmatch "^WARNING: Cache entry" } | Write-Host

if ($LASTEXITCODE -ne 0) {
    Fail "pip install failed. Check internet connectivity."
}
Write-OK "All Python packages installed"

# -----------------------------------------------------------------------------
# 5. Frontend - install Node dependencies
# -----------------------------------------------------------------------------
Write-Step "Installing Node.js dependencies..."

Push-Location frontend
& npm install --prefer-offline 2>&1 | Select-Object -Last 5 | Write-Host
$npmExit = $LASTEXITCODE
Pop-Location

if ($npmExit -ne 0) { Fail "npm install failed." }
Write-OK "node_modules installed"

# -----------------------------------------------------------------------------
# 6. Smoke test - import the transpiler
# -----------------------------------------------------------------------------
Write-Step "Running smoke test..."

$env:PYTHONPATH = (Resolve-Path "backend").Path
$smoke = & $venvPy -c "from app.transpiler import Transpiler; d=Transpiler.supported_dialects(); print(f'Loaded {len(d)} dialects: {d}')" 2>&1
if ($LASTEXITCODE -ne 0) {
    Fail "Smoke test failed:`n$smoke"
}
Write-OK $smoke

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "  Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  HOW TO RUN (local development)" -ForegroundColor Yellow
Write-Host "  --------------------------------"
Write-Host "  Backend  (terminal 1):"
Write-Host "    cd backend"
Write-Host "    .\.venv\Scripts\Activate.ps1"
Write-Host "    uvicorn app.main:app --reload"
Write-Host ""
Write-Host "  Frontend (terminal 2):"
Write-Host "    cd frontend"
Write-Host "    npm run dev"
Write-Host ""
Write-Host "  Open: http://localhost:5173"
Write-Host "  API:  http://localhost:8000/api/docs"
Write-Host ""
Write-Host "  HOW TO RUN (Docker)"
Write-Host "  --------------------"
Write-Host "  docker compose up --build"
Write-Host "  Open: http://localhost:80"
Write-Host ""
Write-Host "  HOW TO TEST"
Write-Host "  -----------"
Write-Host "  cd backend"
Write-Host "  .\.venv\Scripts\Activate.ps1"
Write-Host "  pytest"
Write-Host ""
