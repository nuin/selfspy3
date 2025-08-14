#!/bin/bash
# Create macOS App Bundle for SelfspyWidgets

set -e

APP_NAME="SelfspyWidgets"
BUNDLE_NAME="${APP_NAME}.app"
EXECUTABLE="ModernSelfspyWidgets"

echo "🔨 Creating macOS App Bundle: ${BUNDLE_NAME}"

# Clean up existing bundle
rm -rf "${BUNDLE_NAME}"

# Create bundle directory structure
mkdir -p "${BUNDLE_NAME}/Contents/MacOS"
mkdir -p "${BUNDLE_NAME}/Contents/Resources"

# Copy executable
cp "${EXECUTABLE}" "${BUNDLE_NAME}/Contents/MacOS/${APP_NAME}"
chmod +x "${BUNDLE_NAME}/Contents/MacOS/${APP_NAME}"

# Create Info.plist
cat > "${BUNDLE_NAME}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.selfspy.widgets</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
    <key>NSHumanReadableCopyright</key>
    <string>© 2025 Selfspy Project</string>
    <key>CFBundleDocumentTypes</key>
    <array/>
</dict>
</plist>
EOF

# Create app icon (using system icons for now)
# In a real app, you'd create custom .icns files
mkdir -p "${BUNDLE_NAME}/Contents/Resources"

echo "✅ App bundle created: ${BUNDLE_NAME}"
echo "🚀 Run with: open ${BUNDLE_NAME}"
echo "📱 Or double-click the app in Finder"

# Make the bundle executable
chmod -R 755 "${BUNDLE_NAME}"