#!/bin/bash
# Build script for Odin Selfspy implementation

echo "Building Selfspy (Odin implementation)..."

# Check if Odin compiler is available
if ! command -v odin &> /dev/null; then
    echo "Error: Odin compiler not found. Please install Odin from https://odin-lang.org/"
    exit 1
fi

# Build the application
odin build selfspy.odin -file -out:selfspy

if [ $? -eq 0 ]; then
    echo "✅ Build successful! Executable: ./selfspy"
    echo ""
    echo "Usage examples:"
    echo "  ./selfspy start"
    echo "  ./selfspy stats --days 7"
    echo "  ./selfspy check"
else
    echo "❌ Build failed"
    exit 1
fi