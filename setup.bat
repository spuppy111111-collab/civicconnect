@echo off
REM CivicConnect Setup Script for Windows
REM This script automates the setup of the CivicConnect project

echo.
echo 🏙️  CivicConnect Setup
echo =====================
echo.

REM Check Node.js
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed. Please install Node.js 18+
    exit /b 1
)
for /f "tokens=*" %%i in ('node -v') do set NODE_VERSION=%%i
echo ✅ Node.js %NODE_VERSION%

REM Check Python
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Python 3 is not installed. Please install Python 3.9+
    exit /b 1
)
for /f "tokens=*" %%i in ('python --version') do set PYTHON_VERSION=%%i
echo ✅ Python %PYTHON_VERSION%

echo.
echo 📦 Installing Frontend Dependencies...
call npm install

echo.
echo 🐍 Setting up Python Backend...
python -m venv venv
call venv\Scripts\activate.bat

echo ✅ Virtual environment created

echo.
echo 📚 Installing Backend Dependencies...
pip install -r requirements.txt

echo.
echo 📝 Setting up Environment Files...

if not exist ".env.local" (
    copy .env.local.example .env.local
    echo ✅ Created .env.local
) else (
    echo ℹ️  .env.local already exists
)

echo.
echo 🎉 Setup Complete!
echo.
echo Next steps:
echo ===========
echo.
echo 1. Frontend Development:
echo    npm run dev
echo    → Open http://localhost:3000
echo.
echo 2. Backend Development (in another terminal):
echo    venv\Scripts\activate
echo    python -m uvicorn backend_api:app --reload
echo    → Open http://localhost:8000/docs
echo.
echo 3. View this project's structure:
echo    - Frontend: src/app (Next.js App Router)
echo    - Components: src/components (React Components)
echo    - Services: src/services (API integration)
echo    - Backend: backend_api.py (FastAPI)
echo.
echo 📚 Documentation: See README.md
echo.
pause
