# Stingray - Development Guide for Claude

## Project Overview

Stingray is a native music player for Jellyfin, inspired by Plexamp. The goal is to create a high-quality desktop music player with native media key support and seamless integration with Jellyfin music libraries.

**Current Focus**: Linux desktop development
**Primary Target Platform**: Linux (will expand to other platforms later)

## Development Philosophy

**Work in small chunks!** This is critical. Break down features into the smallest possible increments that can be tested and verified independently.

## Project Structure

```
stingray/
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
- `shared_preferences: ^2.2.2` - For storing user configuration (server URL, etc.)
- `cupertino_icons: ^1.0.8` - Icon fonts

### Development Tools

#### The `ok` Script

**Purpose**: Fast feedback loop for developers (~6 seconds)
**Location**: `./ok` in project root

**What it does**:

1. Format check (`dart format`)
2. Static analysis (`flutter analyze`)
3. Run all tests (`flutter test`)

**Important**: This script is optimized for speed and frequent use during development. It does NOT include:

- `flutter doctor` (only needed for environment debugging)
- `flutter pub get` (done automatically by analyze/test)
- Full Linux build (too slow for frequent checks)

**Usage**:

```bash
./ok
```

Must complete in ~10 seconds or less. If it gets slower, investigate and optimize.

### API Integration

**Jellyfin Server**: All API interactions use the OpenAPI spec in `ref/jellyfin-openapi-stable.json`

**Current Implementation**:

- Server URL stored in `shared_preferences` with key `server_url`
- Health check endpoint: `GET {server_url}/health`

### State Management

Currently using basic Flutter `StatefulWidget` patterns. As the app grows, we may need to introduce more sophisticated state management.

### Storage

Using `shared_preferences` for user configuration:

- `server_url`: Jellyfin server URL (e.g., "http://lab:8096")

Data is stored in user space (~/.local/share on Linux).

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
5. Run `./ok` to verify everything passes

### Adding a New API Call

1. Reference `ref/jellyfin-openapi-stable.json` for endpoint details
2. Use the configured `server_url` from `SharedPreferences`
3. Handle errors gracefully (network issues, auth failures, etc.)
4. Add tests with mocked HTTP responses
5. Keep it simple - start with basic functionality

### Code Style

- Run `dart format .` before committing (or let `ok` script catch it)
- Follow Flutter/Dart conventions
- Use `const` constructors where possible
- Prefer explicit types over `var` for clarity

## Native Plugin Issues

**Important**: When adding packages with native code (like `shared_preferences`):

1. Run `flutter clean`
2. Run `flutter pub get`
3. **Do a full rebuild** - hot reload will NOT work!
4. Stop the app completely and restart with `flutter run -d linux`

**Common Error**: `MissingPluginException` means you need a full rebuild.

## Git Workflow

Before committing:

1. Run `./ok` - all checks must pass
2. Ensure tests cover your changes
3. Write clear, concise commit messages
4. Focus on "why" rather than "what" in commits

## Future Roadmap

Things to build (in small chunks!):

1. ~~Server configuration~~ ✅
2. Authentication with Jellyfin
3. Browse music library
4. Playback controls
5. Native media key support
6. Playlists
7. Queue management
8. Album art display
9. Search functionality
10. Additional platforms (macOS, Windows)

## Tips for Claude

- **Always work in small chunks** - verify each step before moving forward
- **Run `./ok` frequently** - catch issues early
- **Write tests first when appropriate** - TDD helps with design
- **Reference the Jellyfin API spec** in `ref/` when implementing new features
- **Focus on Linux first** - don't worry about cross-platform until requested
- **Keep the UI simple** - functionality over fancy UI for now
- **Ask questions** - if requirements are unclear, ask before implementing

## Current State

**What works**:

- ✅ Basic Flutter app structure
- ✅ Server configuration with persistence
- ✅ Settings screen with validation
- ✅ Health check endpoint test
- ✅ Comprehensive test coverage
- ✅ Fast development workflow (`ok` script)

**Next steps**:

- Authentication flow
- Music library browsing
- Basic playback

## Notes

- Development server is at `http://lab:8096`
- All code must pass `./ok` before being considered complete
- Tests are mandatory for all new features
- Work in small, verifiable increments
