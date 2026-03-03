#!/bin/bash
# GradeBridge App - Quick Setup Script
# Run this to get your app running!

echo "=========================================="
echo "  GradeBridge - Quick Setup"
echo "=========================================="
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null
then
    echo "❌ Flutter is not installed!"
    echo "📥 Download from: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version)"
echo ""

# Step 1: Get dependencies
echo "📦 Step 1: Installing dependencies..."
flutter pub get
if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed successfully!"
else
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo ""

# Step 2: Run the app
echo "🚀 Step 2: Starting app with hot reload..."
echo "   • Save files → Hot reload automatically"
echo "   • Press 'R' → Manual hot reload"
echo "   • Press 'Shift+R' → Full restart"
echo "   • Press 'q' → Quit"
echo ""
echo "Starting Flutter app..."
echo ""

flutter run

echo ""
echo "=========================================="
echo "  App stopped! Run again: flutter run"
echo "=========================================="
