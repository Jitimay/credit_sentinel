#!/bin/bash

# Flutter Production Build Script
set -e

echo "🏗️  Building CreditSentinel™ for Production..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Build for Web (Production)
echo "🌐 Building for Web..."
flutter build web --release --dart-define=API_URL=https://api.creditsentinel.com

# Build for Linux Desktop
echo "🐧 Building for Linux Desktop..."
flutter build linux --release --dart-define=API_URL=https://api.creditsentinel.com

# Build for Windows (if on Windows)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    echo "🪟 Building for Windows..."
    flutter build windows --release --dart-define=API_URL=https://api.creditsentinel.com
fi

# Build for macOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Building for macOS..."
    flutter build macos --release --dart-define=API_URL=https://api.creditsentinel.com
fi

echo "✅ Production builds completed!"
echo "📁 Web build: build/web/"
echo "📁 Linux build: build/linux/x64/release/bundle/"
