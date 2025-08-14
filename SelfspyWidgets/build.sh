#!/bin/bash
# Build script for SelfspyWidgets
# Native macOS desktop widgets for Selfspy

set -e  # Exit on any error

echo "🔨 Building SelfspyWidgets..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: This application only runs on macOS"
    exit 1
fi

# Check if Xcode command line tools are installed
if ! command -v clang &> /dev/null; then
    echo "❌ Error: Xcode command line tools not found"
    echo "Please install with: xcode-select --install"
    exit 1
fi

# Clean any previous build
echo "🧹 Cleaning previous build..."
make clean 2>/dev/null || true

# Build the application
echo "⚙️  Compiling native Objective-C application..."
make release

# Check if build was successful
if [[ -f "SelfspyWidgets" ]]; then
    echo "✅ Build successful!"
    echo "📱 Run with: ./SelfspyWidgets"
    echo "📦 Install system-wide with: sudo make install"
    
    # Make executable
    chmod +x SelfspyWidgets
    
    echo ""
    echo "🎉 SelfspyWidgets is ready to use!"
    echo ""
    echo "Usage:"
    echo "  ./SelfspyWidgets           # Run the desktop widgets"
    echo "  sudo make install         # Install system-wide"
    echo "  make run                  # Build and run in one step"
    echo ""
    
else
    echo "❌ Build failed!"
    exit 1
fi