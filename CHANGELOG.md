# Changelog

All notable changes to Panda will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- App icon by Sofie Ascherl from [OpenMoji](https://openmoji.org/library/emoji-1F43C/), licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)
- GitHub Workflow for CI checks
- Dark Mode theme with setting and auto switching

### Changed

- Project renamed from Stingray to Panda to avoid possible conflict with existing Stingray music service

## [0.1.0] - 2025-11-10

### Added

- Initial release of Panda (formerly Stingray)
- Jellyfin server connection and authentication
- Secure token storage with session persistence
- Music library browsing with album grid view
- Album detail view with track listing
- Audio playback with play/pause controls
- Queue management with next/previous track navigation
- Persistent now playing bar across all screens
- Album artwork display with optimized loading
- Native media key support via MPRIS (Linux)
- System media controls integration
- Favorites functionality (mark and browse favorite tracks)
- Playback reporting to Jellyfin for play counts and statistics
- Settings page with library selection and sign out
- Auto-login on app restart
- Escape key navigation

### Platform Support

- Linux x64 (tested on Fedora)
