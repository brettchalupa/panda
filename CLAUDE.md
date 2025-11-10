# Panda - Development Guide for Claude

## Project Overview

Panda is a native music player for Jellyfin, inspired by Plexamp. The goal is
to create a high-quality desktop music player with native media key support and
seamless integration with Jellyfin music libraries.

**Current Focus**: Linux desktop development **Primary Target Platform**: Linux
(will expand to other platforms later)

## System Requirements (Linux)

Before building, install these system dependencies:

**Fedora/RHEL**:

```bash
sudo dnf install gstreamer1-devel gstreamer1-plugins-base-devel gstreamer1-plugins-good gstreamer1-plugins-bad-free libsecret-devel
```

**Ubuntu/Debian**:

```bash
sudo apt-get install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-good gstreamer1.0-plugins-bad libsecret-1-dev
```

**What they're for**:

- GStreamer: Required for `audioplayers` package (audio playback)
- libsecret: Required for `flutter_secure_storage` package (encrypted token
  storage)

## Development Philosophy

**Work in small chunks!** This is critical. Break down features into the
smallest possible increments that can be tested and verified independently.

## Project Structure

```
panda/
├── lib/
│   ├── main.dart              # Main app entry point and home screen
│   └── settings_screen.dart   # Server configuration screen
├── test/
│   ├── widget_test.dart       # Main app widget tests
│   └── settings_screen_test.dart  # Settings screen tests
├── ref/
│   └── jellyfin-openapi-stable.json  # Jellyfin API OpenAPI spec
├── ok                         # Quick check script (format, analyze, test)
└── pubspec.yaml              # Dependencies
```

## Key Technical Details

### Dependencies

- `http: ^1.2.0` - For API requests to Jellyfin server
- `shared_preferences: ^2.2.2` - For storing user configuration (server URL,
  etc.)
- `flutter_secure_storage: ^9.0.0` - For securely storing authentication tokens
- `audioplayers: ^6.0.0` - For audio playback (requires GStreamer on Linux)
- `audio_service: ^0.18.15` - For media session integration and background
  playback
- `audio_service_mpris: ^0.1.3` - For Linux MPRIS support (media keys)
- `provider: ^6.1.0` - For global state management
- `cupertino_icons: ^1.0.8` - Icon fonts

### Development Tools

#### Just Commands (`justfile`)

**Purpose**: Task automation and fast feedback loop for developers **Location**:
`justfile` in project root

**Key Commands**:

- `just` or `just --list` - Show all available commands
- `just ok` - Run all checks (format check + analyze + tests)
- `just test` - Run tests only
- `just fmt` - Format all Dart code
- `just run` - Run the app in development mode
- `just build` - Build release version for Linux
- `just release` - Clean and build optimized release
- `just install` - Install app to `~/.local/share/panda`
- `just release-and-install` - Build, install, and launch
- `just launch` - Launch the installed app
- `just uninstall` - Remove the installed app
- `just clean` - Clean build artifacts
- `just deps` - Get Flutter dependencies
- `just doctor` - Run Flutter doctor

**The `just ok` Command**:

Fast feedback loop that runs:

1. Format check (`dart format --output=none --set-exit-if-changed`)
2. Static analysis (`flutter analyze`)
3. Tests (`flutter test`)

**Important**: Optimized for frequent use during development. Does NOT include:

- `flutter doctor` (only needed for environment debugging)
- `flutter pub get` (done automatically by analyze)
- Full Linux build (use `just build` for that)

**Usage**:

```bash
just ok              # Run all checks (format, analyze, tests)
just test            # Run tests only
just release-and-install  # Build and install new version
```

### API Integration

**Jellyfin Server**: All API interactions use the OpenAPI spec in
`ref/jellyfin-openapi-stable.json`

**Current Implementation**:

- Server URL stored in `shared_preferences` with key `server_url`
- Health check endpoint: `GET {server_url}/health`

### State Management

Currently using basic Flutter `StatefulWidget` patterns. As the app grows, we
may need to introduce more sophisticated state management.

### Storage

**Configuration (shared_preferences)**:

- `server_url`: Jellyfin server URL (e.g., "http://lab:8096")
- Stored in user space (~/.local/share on Linux)

**Authentication (flutter_secure_storage)**:

- `access_token`: Jellyfin API access token (encrypted)
- `user_id`: Current user's ID (encrypted)
- `user_name`: Current user's name (encrypted)
- Stored securely using platform-specific keychain/keystore
- Use `SessionManager` helper class for all auth operations

**Important**: Never use `shared_preferences` for tokens! Always use
`SessionManager` for auth data.

### Media Key Support

**Linux Integration via MPRIS**:

- Uses `audio_service` with `audio_service_mpris` plugin
- Integrates with D-Bus MPRIS (Media Player Remote Interfacing Specification)
- Provides system-wide media controls through desktop environment
- Works with KDE, GNOME, and other Linux desktop environments

**Implementation**:

- `AudioPlayerService` wraps the audio player with `audio_service`
- `PandaAudioHandler` extends `BaseAudioHandler` to handle media control
  events
- Updates media metadata (track, album, artist, artwork) to system
- Broadcasts playback state (playing/paused, position, duration)
- Responds to media key events (play, pause, stop)

**Supported Controls**:

- Play/Pause toggle
- Stop
- Track metadata display in system media controls
- Album artwork in system notifications (when available)

### Theming

**Architecture**:
- Centralized theme configuration in `lib/theme.dart`
- Light and dark themes with Material 3 design
- User-selectable theme mode (Light / Dark / Auto) stored in SharedPreferences
- `ThemeManager` class manages theme state with Provider

**Theme Mode Options**:
- **Light**: Always use light theme
- **Dark**: Always use dark theme
- **Auto** (default): Follow system theme preference

**Customizing Themes**:
- Primary color seed: Change `_primarySeed` in `lib/theme.dart` (currently `Colors.deepOrange`)
- Border radius, padding, elevation all configured in theme file
- Both light and dark themes share same structure for consistency

**Theme Manager**:
- `ThemeManager` extends `ChangeNotifier` and persists theme preference
- Stored in SharedPreferences as `theme_mode` (values: 'light', 'dark', 'system')
- Access via `Provider.of<ThemeManager>(context)` or `Consumer<ThemeManager>`
- UI for theme selection in Settings screen (Appearance section)

**Best Practices**:
- Always use theme colors: `Theme.of(context).colorScheme.primary`
- Use semantic text styles: `Theme.of(context).textTheme.titleLarge`
- Never hardcode colors like `Colors.blue` - use theme color roles
- Test changes in both light and dark modes

## Testing Strategy

**All features must have tests!** This is non-negotiable.

### Test Requirements

1. **Widget tests** for all UI components
2. **Integration tests** for multi-screen flows
3. **Mock `SharedPreferences`** for testing configuration
4. Use `SharedPreferences.setMockInitialValues({})` in test `setUp()`

### Current Test Coverage

- ✅ Health check UI
- ✅ Settings screen display and validation
- ✅ Server configuration loading
- ✅ Settings navigation

### Running Tests

```bash
flutter test                    # Run all tests
flutter test --reporter=compact # Compact output (used in ok script)
flutter test path/to/test.dart  # Run specific test
```

## Common Tasks

### Adding a New Screen

1. Create the screen widget in `lib/`
2. Add navigation from existing screens
3. Create corresponding test file in `test/`
4. Add tests for:
   - Widget rendering
   - User interactions
   - Navigation
   - State changes
5. Run `just ok` to verify everything passes

### Adding a New API Call

1. Reference `ref/jellyfin-openapi-stable.json` for endpoint details
2. Use the configured `server_url` from `SharedPreferences`
3. Handle errors gracefully (network issues, auth failures, etc.)
4. Add tests with mocked HTTP responses
5. Keep it simple - start with basic functionality

### Code Style

- Run `just fmt` before committing (or let `just ok` catch formatting issues)
- Follow Flutter/Dart conventions
- Use `const` constructors where possible
- Prefer explicit types over `var` for clarity

## Native Plugin Issues

**Important**: When adding packages with native code (like
`shared_preferences`):

1. Run `flutter clean`
2. Run `flutter pub get`
3. **Do a full rebuild** - hot reload will NOT work!
4. Stop the app completely and restart with `flutter run -d linux`

**Common Error**: `MissingPluginException` means you need a full rebuild.

## Git Workflow

Before committing:

1. Run `just ok` - all checks must pass
2. Ensure tests cover your changes
3. Write clear, concise commit messages
4. Focus on "why" rather than "what" in commits

## Future Roadmap

Things to build (in small chunks!):

1. ~~Server configuration~~ ✅
2. ~~Authentication with Jellyfin~~ ✅
3. ~~Browse music library~~ ✅
4. ~~Playback controls~~ ✅
5. ~~Native media key support~~ ✅
6. ~~Album art display~~ ✅
7. Queue management / next/previous
8. Seek controls
9. Playlists
10. Search functionality
11. Additional platforms (macOS, Windows)

## Tips for Claude

- **Always work in small chunks** - verify each step before moving forward
- **Run `just ok` frequently** - catch issues early
- **Write tests first when appropriate** - TDD helps with design
- **Reference the Jellyfin API spec** in `ref/` when implementing new features
- **Focus on Linux first** - don't worry about cross-platform until requested
- **Keep the UI simple** - functionality over fancy UI for now
- **Ask questions** - if requirements are unclear, ask before implementing
- **Use `just` commands** - `just ok`, `just fmt`, `just release-and-install`,
  etc.

## Current State

**What works**:

- ✅ Basic Flutter app structure
- ✅ Server configuration with persistence
- ✅ Settings screen with validation
- ✅ Secure authentication with encrypted token storage
- ✅ Auto-login with session persistence
- ✅ Music library selection
- ✅ Album browsing and listing
- ✅ Track listing with duration display
- ✅ Audio playback with play/pause controls
- ✅ Global persistent now playing bar (seamless across navigation)
- ✅ Track progress indicator and album art display
- ✅ Native media key support via MPRIS (Linux)
- ✅ Sign out functionality
- ✅ Comprehensive test coverage (11 tests)
- ✅ Fast development workflow (`ok` script)

**Next steps**:

- Queue management / next/previous track
- Seek controls
- Search functionality
- Playlist support

## Notes

- Development server is at `http://lab:8096`
- All code must pass `just ok` before being considered complete
- Tests are mandatory for all new features
- Work in small, verifiable increments
- Use `just release-and-install` to build and deploy new versions
- App installs to `~/.local/share/panda` with symlink in `~/.local/bin`
