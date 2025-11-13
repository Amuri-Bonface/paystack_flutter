#!/bin/bash

# Flutter Paystack Kenya Enhanced v2.1.0 - Git Repository Setup Script
# Run this script from the project directory

echo "🚀 Setting up Git repository for Flutter Paystack Kenya Enhanced v2.1.0..."

# Navigate to project directory (assuming current directory)
echo "📁 Current directory: $(pwd)"

# Initialize Git repository
echo "🔧 Initializing Git repository..."
git init

# Add all files
echo "📦 Adding all files to Git..."
git add .

# Create initial commit
echo "💾 Creating initial commit..."
git commit -m "🎉 Initial commit: Flutter Paystack Kenya Enhanced v2.1.0

✨ Features:
- 🏦 Pesalink support (instant bank transfers up to KES 999,999)
- 📱 5 Kenya payment methods (M-PESA, Airtel Money, Pesalink, Cards)
- 🤖 Smart payment routing and auto-detection
- 🔧 Complete Android, iOS, and Web implementation
- 📖 Comprehensive documentation and examples
- 🚀 Production-ready for Kenyan market"

echo "✅ Git repository setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Create a new repository on GitHub"
echo "2. Add the remote origin: git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git"
echo "3. Push to GitHub: git push -u origin main"
echo ""
echo "🔗 For pub.dev publishing, follow the DEPLOYMENT_GUIDE.md instructions"