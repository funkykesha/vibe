# Tech Context

## Development Environment Setup
- Work from `/Users/agaibadulin/Desktop/projects/vibe/services-menu`.
- Python runtime in `rebuild.sh`: `/opt/homebrew/Caskroom/miniforge/base/bin/python3`.
- `setup.py` expects Homebrew `libffi.8.dylib` under `/opt/homebrew`; install with `brew install libffi` if missing.
- Runtime dependencies include `rumps`, PyObjC/AppKit, and py2app.

## Build and Deploy
- Syntax check: `python3 -m py_compile app.py setup.py`
- Unit tests: `python3 -m unittest test_app.py`
- Build/install locally: `./rebuild.sh`
- Rebuild script installs `/Applications/ServicesMenu.app`, updates LaunchServices, ad-hoc signs, writes login LaunchAgent, and opens the app.

## Code Style and Conventions
- **Language**: Python.
- **Formatter**: None configured.
- **Linter**: None configured.
- **Naming**: Uppercase constants, snake_case helpers, AppKit selector methods with trailing underscore.
- **Commit format**: Conventional Commits if commits are requested.

## External Dependencies

| Service | Purpose | Docs | Constraints |
|---------|---------|------|-------------|
| `launchctl` | Read and restart LaunchAgents | `man launchctl` | Current user session behavior matters |
| `~/Library/LaunchAgents` | Source and target for plist files | macOS LaunchAgent plist docs | Only `com.agaibadulin.*.plist` is managed |
| `/usr/bin/which` | Resolve command names | `man which` | PATH is set in code to include Homebrew dirs |
| py2app | Build `.app` bundle | py2app docs | Requires local dependencies and libffi path |

---
Updated when dev environment or conventions change.
