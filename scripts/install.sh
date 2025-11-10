#!/usr/bin/env bash
# Install Panda locally
set -euo pipefail

# Determine the bundle directory
if [ -d "build/linux/x64/release/bundle" ]; then
    BUNDLE_DIR="build/linux/x64/release/bundle"
elif [ -d "." ] && [ -f "./panda" ]; then
    # Running from extracted package directory
    BUNDLE_DIR="."
else
    echo "Error: Could not find Panda bundle"
    echo "Run this from the project root after building, or from an extracted package"
    exit 1
fi

echo "Installing Panda to ~/.local/share/panda..."
rm -rf ~/.local/share/panda
mkdir -p ~/.local/share
cp -r "$BUNDLE_DIR" ~/.local/share/panda
chmod +x ~/.local/share/panda/panda

echo "Creating symlink in ~/.local/bin..."
mkdir -p ~/.local/bin
ln -sf ~/.local/share/panda/panda ~/.local/bin/panda

echo "Installing icon..."
if [ -f ~/.local/share/panda/data/flutter_assets/assets/icon.png ]; then
    cp ~/.local/share/panda/data/flutter_assets/assets/icon.png \
       ~/.local/share/panda/icon.png
else
    echo "Warning: Icon not found, skipping icon installation"
fi

echo "Creating desktop entry..."
mkdir -p ~/.local/share/applications
ICON_PATH="$HOME/.local/share/panda/icon.png"
cat > ~/.local/share/applications/com.brettchalupa.panda.desktop <<EOF
[Desktop Entry]
Name=Panda
Comment=Jellyfin Music Player
Exec=panda
Icon=$ICON_PATH
Terminal=false
Type=Application
Categories=AudioVideo;Audio;Player;
StartupNotify=true
StartupWMClass=com.brettchalupa.panda
EOF

chmod +x ~/.local/share/applications/com.brettchalupa.panda.desktop

# Update desktop database if available
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database ~/.local/share/applications
fi

echo "✓ Installation complete!"
echo "  Launch with: panda"
echo "  Or search for 'Panda' in your application menu"
echo ""
echo "Note: Make sure ~/.local/bin is in your PATH"
