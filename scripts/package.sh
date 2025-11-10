#!/usr/bin/env bash
# Package Panda for release
set -euo pipefail

# Get version from pubspec.yaml
VERSION=$(grep "version:" pubspec.yaml | cut -d' ' -f2 | cut -d'+' -f1)

echo "Creating release package for version $VERSION..."

# Build release
echo "Cleaning build artifacts..."
flutter clean > /dev/null
echo "Building release..."
flutter build linux --release

# Create release directory structure
mkdir -p build/release
RELEASE_DIR="build/release/panda-${VERSION}-linux-x64"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# Copy files
echo "Copying files..."
cp -r build/linux/x64/release/bundle/* "$RELEASE_DIR/"
cp README.md "$RELEASE_DIR/"
cp CHANGELOG.md "$RELEASE_DIR/" 2>/dev/null || echo "Note: CHANGELOG.md not found, skipping"
cp scripts/install.sh "$RELEASE_DIR/"
chmod +x "$RELEASE_DIR/install.sh"

# Create tarball
echo "Creating tarball..."
cd build/release
tar -czf "panda-${VERSION}-linux-x64.tar.gz" "panda-${VERSION}-linux-x64"
cd ../..

echo "✓ Release package created: build/release/panda-${VERSION}-linux-x64.tar.gz"
echo "  To install: tar -xzf build/release/panda-${VERSION}-linux-x64.tar.gz"
echo "              cd panda-${VERSION}-linux-x64 && ./install.sh"
