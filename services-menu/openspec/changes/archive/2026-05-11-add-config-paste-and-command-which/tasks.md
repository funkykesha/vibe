## 1. Command Resolution

- [x] 1.1 Add a pure helper that validates a non-empty command value before lookup.
- [x] 1.2 Resolve commands by running `/usr/bin/which <command>` without `shell=True`.
- [x] 1.3 Use a deterministic PATH that includes `/opt/homebrew/bin`, `/usr/local/bin`, `/usr/bin`, `/bin`, `/usr/sbin`, and `/sbin`.
- [x] 1.4 Return the resolved path only when `which` succeeds and stdout is non-empty.
- [x] 1.5 Preserve the original command value and surface a validation/error message when lookup fails.

## 2. Add Config UI

- [x] 2.1 Add standard AppKit edit actions so text fields support paste, copy, cut, and select-all.
- [x] 2.2 Add a `Which` button next to the `Command` field without changing existing Apply/Cancel behavior.
- [x] 2.3 Wire `Which` to resolve the current command field value and replace the field only on success.
- [x] 2.4 Show validation or lookup errors through the existing alert style.

## 3. Verification

- [x] 3.1 Add unit tests for command resolution success using an injected runner or controlled environment.
- [x] 3.2 Add unit tests for blank command and command-not-found behavior.
- [x] 3.3 Run the project test suite.
- [x] 3.4 Manually verify that `Cmd+V` works in Add Config text fields and `Which` converts `node` to `/opt/homebrew/bin/node` when available.
