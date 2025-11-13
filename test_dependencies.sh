#!/bin/bash

# Flutter Paystack Dependency Fix Script
# Run this to test the dependency fix

echo "🔧 Flutter Paystack Dependency Fix"
echo "=================================="

# Check current directory
echo "📁 Current directory: $(pwd)"

# Show current package version
echo "📦 Package version: $(cat pubspec.yaml | grep version | cut -d':' -f2 | tr -d ' ')"

# Show intl dependency
echo "🔗 Intl dependency: $(cat pubspec.yaml | grep intl | cut -d':' -f2 | tr -d ' ')"

echo ""
echo "🧪 Testing dependency resolution..."

# Test dependency resolution
flutter pub deps 2>&1 | grep -E "(intl|flutter_paystack|error|failed)" || echo "✅ No dependency conflicts found!"

echo ""
echo "📋 Recommended next steps:"
echo "1. Run: flutter pub get"
echo "2. Run: flutter analyze"  
echo "3. Test: flutter run"
echo ""
echo "🔗 For more help, see: DEPENDENCY_CONFLICT_SOLUTION.md"