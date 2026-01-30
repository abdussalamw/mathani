#!/bin/bash
# Setup script for Mathani

echo "🚀 Setting up Mathani Project..."

# Clean
echo "Cleaning project..."
flutter clean

# Get dependencies
echo "📦 Installing dependencies..."
flutter pub get

# Generate code
echo "⚙️  Generating code (Isar, etc)..."
flutter pub run build_runner build --delete-conflicting-outputs

echo "✅ Setup Complete! You can now run 'flutter run'"
