#!/bin/bash

# CivicConnect Setup Script
# This script automates the setup of the CivicConnect project

set -e

echo "🏙️  CivicConnect Setup"
echo "====================="
echo ""

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+"
    exit 1
fi
echo "✅ Node.js $(node -v)"

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.9+"
    exit 1
fi
echo "✅ Python $(python3 --version)"

echo ""
echo "📦 Installing Frontend Dependencies..."
npm install

echo ""
echo "🐍 Setting up Python Backend..."
python3 -m venv venv

# Activate virtual environment
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    source venv/Scripts/activate
else
    source venv/bin/activate
fi

echo "✅ Virtual environment created"

echo ""
echo "📚 Installing Backend Dependencies..."
pip install -r requirements.txt

echo ""
echo "📝 Setting up Environment Files..."

if [ ! -f ".env.local" ]; then
    cp .env.local.example .env.local
    echo "✅ Created .env.local"
else
    echo "ℹ️  .env.local already exists"
fi

echo ""
echo "🎉 Setup Complete!"
echo ""
echo "Next steps:"
echo "==========="
echo ""
echo "1. Frontend Development:"
echo "   npm run dev"
echo "   → Open http://localhost:3000"
echo ""
echo "2. Backend Development (in another terminal):"
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo "   venv\\Scripts\\activate"
else
    echo "   source venv/bin/activate"
fi
echo "   python -m uvicorn backend_api:app --reload"
echo "   → Open http://localhost:8000/docs"
echo ""
echo "3. View this project's structure:"
echo "   - Frontend: src/app (Next.js App Router)"
echo "   - Components: src/components (React Components)"
echo "   - Services: src/services (API integration)"
echo "   - Backend: backend_api.py (FastAPI)"
echo ""
echo "📚 Documentation: See README.md"
echo ""
