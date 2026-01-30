#!/bin/bash
# Build script for production APK

echo "🏗️  Building Production APK..."

flutter build apk --release

echo "✅ Build Complete! APK can be found in build/app/outputs/flutter-apk/app-release.apk"
