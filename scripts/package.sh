#!/usr/bin/env bash
# Package Stingray for release
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
RELEASE_DIR="build/release/stingray-${VERSION}-linux-x64"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# Copy files
echo "Copying files..."
cp -r build/linux/x64/release/bundle/* "$RELEASE_DIR/"
cp README.md "$RELEASE_DIR/"
cp CHANGELOG.md "$RELEASE_DIR/" 2>/dev/null || echo "Note: CHANGELOG.md not found, skipping"

# Create install script
cat > "$RELEASE_DIR/install.sh" << 'EOFINSTALL'
#!/usr/bin/env bash
set -euo pipefail

echo "Installing Stingray to ~/.local/share/stingray..."
rm -rf ~/.local/share/stingray
mkdir -p ~/.local/share
cp -r . ~/.local/share/stingray
chmod +x ~/.local/share/stingray/stingray

echo "Creating symlink in ~/.local/bin..."
mkdir -p ~/.local/bin
ln -sf ~/.local/share/stingray/stingray ~/.local/bin/stingray

echo "Creating desktop entry..."
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/com.brettchalupa.stingray.desktop << 'EOF'
[Desktop Entry]
Name=Stingray
Comment=Jellyfin Music Player
Exec=stingray
Terminal=false
Type=Application
Categories=AudioVideo;Audio;Player;
StartupNotify=true
StartupWMClass=com.brettchalupa.stingray
EOF

chmod +x ~/.local/share/applications/com.brettchalupa.stingray.desktop

if command -v update-desktop-database &> /dev/null; then
    update-desktop-database ~/.local/share/applications
fi

echo "✓ Installation complete!"
echo "  Launch with: stingray"
echo "  Or search for 'Stingray' in your application menu"
echo ""
echo "Note: Make sure ~/.local/bin is in your PATH"
EOFINSTALL

chmod +x "$RELEASE_DIR/install.sh"

# Create tarball
echo "Creating tarball..."
cd build/release
tar -czf "stingray-${VERSION}-linux-x64.tar.gz" "stingray-${VERSION}-linux-x64"
cd ../..

echo "✓ Release package created: build/release/stingray-${VERSION}-linux-x64.tar.gz"
echo "  To install: tar -xzf build/release/stingray-${VERSION}-linux-x64.tar.gz"
echo "              cd stingray-${VERSION}-linux-x64 && ./install.sh"
