# Stingray - Jellyfin Music Player
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

# Run all checks (format check + analyze)
check: fmt-check analyze
    @echo "✓ All checks passed!"

# Alias for check
ok: check

# Build release version for Linux
build:
    flutter build linux --release

# Build and create optimized release
release: clean build
    @echo "✓ Release build complete: build/linux/x64/release/bundle/stingray"

# Install the app locally to ~/.local
install:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Installing Stingray to ~/.local/share/stingray..."
    rm -rf ~/.local/share/stingray
    mkdir -p ~/.local/share
    cp -r build/linux/x64/release/bundle ~/.local/share/stingray
    chmod +x ~/.local/share/stingray/stingray

    echo "Creating symlink in ~/.local/bin..."
    mkdir -p ~/.local/bin
    ln -sf ~/.local/share/stingray/stingray ~/.local/bin/stingray

    echo "Creating desktop entry..."
    mkdir -p ~/.local/share/applications
    cat > ~/.local/share/applications/stingray.desktop << 'EOF'
    [Desktop Entry]
    Name=Stingray
    Comment=Jellyfin Music Player
    Exec=stingray
    Terminal=false
    Type=Application
    Categories=AudioVideo;Audio;Player;
    StartupNotify=true
    EOF

    chmod +x ~/.local/share/applications/stingray.desktop

    # Update desktop database if available
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database ~/.local/share/applications
    fi

    echo "✓ Installation complete!"
    echo "  Launch with: stingray"
    echo "  Or search for 'Stingray' in your application menu"
    echo ""
    echo "Note: Make sure ~/.local/bin is in your PATH"

# Uninstall the app
uninstall:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Uninstalling Stingray..."
    rm -rf ~/.local/share/stingray
    rm -f ~/.local/bin/stingray
    rm -f ~/.local/share/applications/stingray.desktop

    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database ~/.local/share/applications
    fi

    echo "✓ Uninstall complete!"

# Build, install, and launch
release-and-install: release install
    @echo "✓ Build and install complete!"
    @echo "Launching Stingray..."
    stingray &

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

# Launch the installed app
launch:
    stingray &

# View logs (if running)
logs:
    journalctl --user -f | grep -i stingray
