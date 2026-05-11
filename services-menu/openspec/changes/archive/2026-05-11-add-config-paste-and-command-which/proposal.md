## Why

The Add Config editor is the main path for creating LaunchAgent plist files, but it is slow for common setup work: copied values must paste reliably into fields, and short commands like `node` must be manually resolved to the absolute executable path expected by LaunchAgent.

## What Changes

- Ensure standard paste/copy/select-all behavior works in Add Config text fields.
- Add a `Which` action for the `Command` field.
- Resolve command names by running `which <command>` with a deterministic PATH that includes Homebrew locations.
- Replace the `Command` field value with the resolved absolute executable path on success.
- Preserve the existing command field value and show an error when resolution fails.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `launch-agent-config-creation`: Add Config editor text input behavior and command resolution requirements change.

## Impact

- Affects `app.py` Add Config AppKit window behavior.
- Affects command-field validation and UI event handling.
- Adds test coverage around command resolution success/failure and field behavior where practical.
- No new runtime dependency; uses Python standard library subprocess and existing AppKit/rumps stack.
