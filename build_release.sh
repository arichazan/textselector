#!/bin/bash

# SnapText Release Build Script
set -e

echo "🔨 Building SnapText in release mode..."
swift build -c release

echo "📦 Creating app bundle structure..."
rm -rf SnapText.app
mkdir -p SnapText.app/Contents/MacOS
mkdir -p SnapText.app/Contents/Resources

echo "📋 Copying executable..."
cp ./.build/release/SnapText SnapText.app/Contents/MacOS/

echo "📄 Creating Info.plist..."
cat > SnapText.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>SnapText</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.snaptext</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>SnapText</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>© 2024 SnapText</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

echo "✅ SnapText.app created successfully!"
echo "📍 Location: $(pwd)/SnapText.app"
echo "🚀 You can now double-click SnapText.app to run it"
echo "📦 To distribute, compress SnapText.app into a zip file"