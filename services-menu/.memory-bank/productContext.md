# Product Context

## Problem Statement
Developer-owned background services need quick visibility and restart control from the macOS menu bar. Manually editing plist files and running `launchctl` commands is slow and error-prone.

## User Personas

| Persona | Description | Primary Need |
|---------|-------------|--------------|
| Local developer | Maintains several `com.agaibadulin.*` LaunchAgents | See status and restart services fast |
| Tool maintainer | Builds personal macOS automation utilities | Add and package LaunchAgent configs reliably |

## How It Works
1. The app runs in the menu bar with a gear title.
2. It scans `~/Library/LaunchAgents/com.agaibadulin.*.plist`.
3. Valid labels are displayed with status icons from `launchctl list`.
4. Each service has a restart action.
5. `Add Config` opens an AppKit form and writes a new LaunchAgent plist.
6. Rebuild script packages and installs `/Applications/ServicesMenu.app`.

## Key Features

| Feature | Description | Priority |
|---------|-------------|----------|
| Service discovery | Reads labels from matching LaunchAgent plist files | P0 |
| Status display | Shows running, stopped, missing, or unknown state | P0 |
| Restart action | Runs `launchctl stop/start` for a selected service | P0 |
| Add Config | Creates validated user LaunchAgent plist files | P0 |
| Which action | Resolves command names using `/usr/bin/which` with Homebrew PATH | P1 |
| Custom app icon | Uses a gear-related `.icns` in py2app bundle | P1 |

---
Updated when product vision or user requirements change.
