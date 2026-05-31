#!/bin/bash
set -e

echo "=== Flutter V1 Embedding Complete Fix with Android SDK Setup ==="
echo "This script sets up Android SDK and completely regenerates your Android project for v2 embedding"
echo ""

# Check if Android SDK is installed
if [ -z "$ANDROID_SDK_ROOT" ] && [ -z "$ANDROID_HOME" ]; then
    echo "⚠️  Android SDK not found. Setting up Android SDK path..."
    
    # Common Android SDK locations
    if [ -d "$HOME/Android/sdk" ]; then
        export ANDROID_SDK_ROOT="$HOME/Android/sdk"
        export ANDROID_HOME="$HOME/Android/sdk"
        echo "✅ Found Android SDK at: $ANDROID_SDK_ROOT"
    elif [ -d "/opt/android-sdk" ]; then
        export ANDROID_SDK_ROOT="/opt/android-sdk"
        export ANDROID_HOME="/opt/android-sdk"
        echo "✅ Found Android SDK at: $ANDROID_SDK_ROOT"
    else
        echo "❌ Android SDK not found. Please install Android Studio or Android SDK."
        echo "Visit: https://developer.android.com/studio"
        exit 1
    fi
else
    echo "✅ Android SDK already configured:"
    echo "   ANDROID_SDK_ROOT: $ANDROID_SDK_ROOT"
    echo "   ANDROID_HOME: $ANDROID_HOME"
fi

# Add Android SDK tools to PATH
export PATH="$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/tools/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

echo ""
echo "[1/7] Verifying Flutter installation..."
flutter --version

echo ""
echo "[2/7] Cleaning Flutter..."
flutter clean

echo ""
echo "[3/7] Removing Android build artifacts..."
rm -rf android/
rm -rf build/
rm -rf .dart_tool/
rm -rf pubspec.lock

echo ""
echo "[4/7] Getting fresh dependencies..."
flutter pub cache clean
flutter pub get --no-offline

echo ""
echo "[5/7] Regenerating Android project with v2 embedding..."
flutter create . --platforms=android

echo ""
echo "[6/7] Applying custom configurations..."
mkdir -p android/app/src/main/kotlin/com/tenku/app

cat > android/app/src/main/kotlin/com/tenku/app/MainActivity.kt << 'EOF'
package com.tenku.app

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity()
EOF

echo ""
echo "[7/7] Building appbundle..."
flutter build appbundle --debug

echo ""
echo "=== ✅ Build Complete ==="
echo "Your app has been successfully built with v2 embedding!"
echo ""
echo "Environment variables set:"
echo "  ANDROID_SDK_ROOT: $ANDROID_SDK_ROOT"
echo "  ANDROID_HOME: $ANDROID_HOME"
