# Project Brief

## Project Name
ServicesMenu

## Purpose and Vision
ServicesMenu is a macOS menu bar utility for viewing and restarting user LaunchAgent services owned under the `com.agaibadulin.*` label namespace.

## Core Requirements
- Run as a menu bar app without a regular Dock window.
- Discover manageable LaunchAgents from `~/Library/LaunchAgents`.
- Show service status using `launchctl list`.
- Restart discovered services with `launchctl stop` and `launchctl start`.
- Create new LaunchAgent plist files from a small AppKit form.
- Package as `/Applications/ServicesMenu.app` with login autostart support.

## Goals and Success Criteria
- Created `com.agaibadulin.*.plist` services appear in the menu without app relaunch.
- ServicesMenu does not list its own autostart LaunchAgent as a managed service.
- Generated plist files avoid unsafe names and silent overwrites.
- App bundle has a custom gear-related icon.

## Scope

### In Scope
- Local macOS LaunchAgent management for the current user.
- Python `rumps` menu bar UI with AppKit windows where needed.
- py2app packaging and rebuild/install script.
- Unit tests for pure helper behavior.

### Out of Scope
- System-level daemons outside the user LaunchAgents directory.
- Cross-user service management.
- Full service log viewer or process inspector.
- Signed/notarized distribution beyond local ad-hoc signing.

---
Source of truth for the project. Updated rarely, only when fundamental goals change.
