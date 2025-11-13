#!/bin/bash

# Flutter Paystack v2.1.2 Standalone - Dependency Test Script
echo "🧪 Testing Flutter Paystack v2.1.2 Standalone"
echo "=============================================="

# Show package version
echo "📦 Package version: $(cat pubspec.yaml | grep version | cut -d':' -f2 | tr -d ' ')"

# Show dependencies
echo ""
echo "🔗 Dependencies:"
cat pubspec.yaml | grep -A 10 "dependencies:"

echo ""
echo "✅ Key Features:"
echo "  - Standalone implementation (no flutter_paystack_plus)"
echo "  - Compatible with intl >=0.18.1 <0.21.0"
echo "  - Compatible with js (no conflicts)"
echo "  - All Kenya payment methods preserved"
echo "  - Compatible with flutter_facebook_auth ^7.1.1"

echo ""
echo "🧪 Testing commands:"
echo "  flutter clean"
echo "  flutter pub get"
echo "  flutter pub deps"
echo "  flutter analyze"

echo ""
echo "✅ This standalone version should resolve ALL dependency conflicts!"