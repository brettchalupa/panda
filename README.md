# Stingray

A native desktop music player for Jellyfin, built with Flutter. Inspired by
Plexamp, Stingray provides a high-quality music listening experience with
seamless Jellyfin integration, native media key support, and a clean, functional
interface.

## Features

- **Native Jellyfin Integration**: Connect directly to your Jellyfin server
- **Secure Authentication**: Encrypted token storage with session persistence
- **Music Library Browsing**: Browse albums with artwork and metadata
- **Audio Playback**: Full playback controls with progress tracking
- **Media Key Support**: System-wide media controls via MPRIS (Linux)
- **Play Count Tracking**: Jellyfin playback reporting for statistics
- **Favorites**: Mark and browse your favorite tracks
- **Persistent Now Playing Bar**: Seamless playback across navigation
- **Album Art Display**: High-quality artwork with optimized loading
- **Queue Management**: Navigate through your current playlist

## Screenshots

_(Coming soon)_

## Installation

### Prerequisites

**System Dependencies (Linux)**:

Fedora/RHEL:

```bash
sudo dnf install gstreamer1-devel gstreamer1-plugins-base-devel gstreamer1-plugins-good gstreamer1-plugins-bad-free libsecret-devel
```

Ubuntu/Debian:

```bash
sudo apt-get install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-good gstreamer1.0-plugins-bad libsecret-1-dev
```

**Flutter SDK**:

- Install Flutter SDK from
  [flutter.dev](https://flutter.dev/docs/get-started/install)
- Enable Linux desktop support: `flutter config --enable-linux-desktop`

**Just (Task Runner)**:

```bash
# Install just from https://github.com/casey/just
cargo install just
# or
sudo dnf install just  # Fedora
sudo apt install just  # Ubuntu/Debian
```

### Building from Source

1. **Clone the repository**:

   ```bash
   git clone https://github.com/brettchalupa/stingray.git
   cd stingray
   ```

2. **Get dependencies**:

   ```bash
   just deps
   ```

3. **Build and install**:
   ```bash
   just release-and-install
   ```

The app will be installed to `~/.local/share/stingray` with a launcher in your
application menu.

### Running from Source

For development:

```bash
just run
```

## Usage

1. **Launch Stingray** from your application menu or run `stingray` in terminal
2. **Configure Server**: Enter your Jellyfin server URL (e.g.,
   `http://localhost:8096`)
3. **Sign In**: Authenticate with your Jellyfin credentials
4. **Browse & Play**: Browse albums and start listening!

### Keyboard Shortcuts

- **Escape**: Navigate back
- **Media Keys**: Play/pause, next, previous (via system media controls)

## Development

### Quick Start

```bash
# Check code formatting and analyze
just ok

# Format code
just fmt

# Run the app
just run

# Build release version
just build

# Build and install locally
just release-and-install
```

### Project Structure

```
stingray/
├── lib/                    # Application source code
│   ├── main.dart          # App entry point
│   ├── jellyfin_api.dart  # Jellyfin API client
│   ├── audio_player_service.dart  # Audio playback service
│   └── ...                # Screens and utilities
├── test/                  # Test files
├── ref/                   # Reference documentation (Jellyfin API spec)
├── justfile              # Task automation
└── pubspec.yaml          # Dependencies
```

### Key Technologies

- **Flutter**: Cross-platform UI framework
- **audioplayers**: Audio playback with GStreamer backend
- **audio_service**: Media session integration
- **audio_service_mpris**: Linux MPRIS support for media keys
- **flutter_secure_storage**: Encrypted token storage
- **cached_network_image**: Optimized image loading and caching

### Contributing

1. Work in small, testable chunks
2. Run `just ok` before committing
3. Write tests for new features
4. Follow Flutter/Dart conventions
5. Reference `CLAUDE.md` for detailed development guidelines

## Roadmap

- [x] Server configuration and authentication
- [x] Music library browsing
- [x] Audio playback with progress tracking
- [x] Native media key support (Linux)
- [x] Album artwork display
- [x] Favorites management
- [x] Playback reporting to Jellyfin
- [ ] Advanced queue management
- [ ] Seek controls
- [ ] Search functionality
- [ ] Playlist support
- [ ] Cross-platform support (macOS, Windows)
- [ ] Offline mode/caching
- [ ] Gapless playback
- [ ] Audio normalization

## Platform Support

| Platform | Status       |
| -------- | ------------ |
| Linux    | ✅ Supported |
| macOS    | 🚧 Planned   |
| Windows  | 🚧 Planned   |

Possibly Android and iOS releases to come. We'll see.

## Requirements

- **Jellyfin Server**: Version 10.8.0 or newer
- **Flutter SDK**: 3.0 or newer
- **Linux Desktop**: Tested on Fedora and Ubuntu

## Unlicense

This is free and unencumbered software released into the public domain.

## Acknowledgments

- Inspired by [Plexamp](https://plexamp.com/)
- Built with [Flutter](https://flutter.dev/)
- Powered by [Jellyfin](https://jellyfin.org/)

## Support

For bugs and feature requests, please
[open an issue](https://github.com/brettchalupa/stingray/issues).

For development guidance, see [CLAUDE.md](CLAUDE.md).
