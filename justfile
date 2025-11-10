# Panda - Jellyfin Music Player
# Just commands for development and deployment

# Default recipe - show available commands
default:
    @just --list

# Run the app in development mode
run:
    flutter run

# Format all Dart code
fmt:
    dart format lib/

# Check code formatting without modifying files
fmt-check:
    dart format --output=none --set-exit-if-changed lib/

# Analyze code for issues
analyze:
    flutter analyze

# Run tests
test:
    flutter test

# Run all checks (format check + analyze + tests)
check: fmt-check analyze test
    @echo "✓ All checks passed!"

# Alias for check
ok: check

# Build release version for Linux
build:
    flutter build linux --release

# Build and create optimized release
release: clean build
    @echo "✓ Release build complete: build/linux/x64/release/bundle/panda"

# Install the app locally to ~/.local
install:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Installing Panda to ~/.local/share/panda..."
    rm -rf ~/.local/share/panda
    mkdir -p ~/.local/share
    cp -r build/linux/x64/release/bundle ~/.local/share/panda
    chmod +x ~/.local/share/panda/panda

    echo "Creating symlink in ~/.local/bin..."
    mkdir -p ~/.local/bin
    ln -sf ~/.local/share/panda/panda ~/.local/bin/panda

    echo "Creating desktop entry..."
    mkdir -p ~/.local/share/applications
    cat > ~/.local/share/applications/com.brettchalupa.panda.desktop << 'EOF'
    [Desktop Entry]
    Name=Panda
    Comment=Jellyfin Music Player
    Exec=panda
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

# Uninstall the app
uninstall:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Uninstalling Panda..."
    rm -rf ~/.local/share/panda
    rm -f ~/.local/bin/panda
    rm -f ~/.local/share/applications/com.brettchalupa.panda.desktop

    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database ~/.local/share/applications
    fi

    echo "✓ Uninstall complete!"

# Build, install, and launch
release-and-install: release install
    @echo "✓ Build and install complete!"
    @echo "Launching Panda..."
    panda &

# Clean build artifacts
clean:
    flutter clean
    @echo "✓ Build artifacts cleaned"

# Get Flutter dependencies
deps:
    flutter pub get

# Upgrade Flutter dependencies
deps-upgrade:
    flutter pub upgrade

# Run Flutter doctor to check environment
doctor:
    flutter doctor -v

# Show app version info
version:
    @grep "version:" pubspec.yaml

# Create a release tarball
package:
    ./scripts/package.sh

# Launch the installed app
launch:
    panda &

# View logs (if running)
logs:
    journalctl --user -f | grep -i panda
