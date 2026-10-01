# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [2.0.0] - 2026-10-01

### Added
- Codex CLI support (`~/.codex/auth.json`, ChatGPT and API-key logins).
- Cursor support (experimental): swaps the `cursorAuth/*` rows in Cursor's settings database and refuses to run while Cursor is open.
- `ai-switch <name>` switches every tool that has a profile with that name.
- `ai-switch list` and `ai-switch current` cover all tools.

### Changed
- Renamed from `claude-switch` to `ai-switch` and rewrote it in Python. `claude-switch` remains as a shortcut for `ai-switch claude`.
- Profiles now live in `~/.ai-switch/<tool>/<name>` and Keychain items named `ai-switch:<tool>:<name>`. Existing claude-switch profiles are moved automatically.

## [1.0.0] - 2026-10-01

### Added
- First release: save Claude Code logins and switch between them without `/login`, on macOS (Keychain) and Linux.

[Unreleased]: https://github.com/Techiebutler/ai-switch/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/Techiebutler/ai-switch/releases/tag/v2.0.0
[1.0.0]: https://github.com/Techiebutler/ai-switch/releases/tag/v1.0.0
