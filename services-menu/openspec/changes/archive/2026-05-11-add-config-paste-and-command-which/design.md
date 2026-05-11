## Context

`app.py` is a small rumps/AppKit menu bar app. Add Config uses a custom `NSWindow` with `NSTextField` inputs for `name`, `command`, `path-to-start`, and optional `WorkingDirectory`, then writes a LaunchAgent plist from those values. The current command value is accepted as typed, so users must manually provide an absolute executable path such as `/opt/homebrew/bin/node`.

macOS GUI apps launched from Finder or LaunchAgent often have a smaller environment than interactive shells. A `which` action must therefore use an explicit PATH instead of relying on the process environment.

## Goals / Non-Goals

**Goals:**

- Make standard clipboard actions reliable in Add Config text inputs.
- Let the user resolve a command name, especially `node`, into the executable path used in the generated plist.
- Keep command resolution small, testable, and independent from plist generation.
- Preserve user input when resolution fails.

**Non-Goals:**

- Parse shell commands or split command arguments.
- Validate that `path-to-start` is compatible with the resolved command.
- Load, unload, bootstrap, or restart LaunchAgents after config creation.
- Add shell profile integration or source user shell startup files.

## Decisions

1. Add a standard Edit menu or equivalent AppKit responder wiring for copy, paste, cut, and select all.

   Rationale: `NSTextField` already supports these actions through the responder chain when the application exposes the expected menu actions. This keeps behavior native and avoids custom clipboard parsing. Alternative considered: add per-field Paste buttons. Rejected because it adds UI clutter and still does not solve expected keyboard shortcuts.

2. Add a `Which` button next to the `Command` field.

   Rationale: command resolution is tied to a single field and should be visible at the point of use. Alternative considered: resolve automatically on Apply. Rejected because it silently changes user input and can turn a validation action into a filesystem/environment lookup.

3. Resolve commands with `subprocess.run(["/usr/bin/which", command])` and an explicit PATH.

   Rationale: avoiding `shell=True` prevents shell injection and keeps the command name as data. An explicit PATH makes GUI behavior deterministic and includes common Homebrew locations such as `/opt/homebrew/bin` and `/usr/local/bin`. Alternative considered: use `shutil.which`. Rejected for this UX because the requested behavior is specifically a `which` action and `subprocess.run` can model the user-facing command directly while remaining safe without shell.

4. Reject blank command values before running `which`.

   Rationale: a blank lookup is user error and should show a validation message without mutating the field.

5. Replace the command field only when the lookup exits successfully and returns a non-empty path.

   Rationale: failed lookups must not destroy typed input. This also handles commands not installed on the machine.

## Risks / Trade-offs

- PATH may still miss a user's custom tool directory -> include common macOS system and Homebrew paths, and leave manual absolute paths supported.
- `which` can return aliases/functions in shells, but `/usr/bin/which` in a GUI process only sees PATH executables -> acceptable because LaunchAgent also needs an executable path, not shell aliases.
- Existing AppKit test coverage may not exercise keyboard shortcuts directly -> cover pure command resolution with unit tests and keep UI wiring minimal.
