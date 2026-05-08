## 1. Ownership arbitration and startup flow

- [x] 1.1 Implement bind-first daemon ownership detection with explicit handling for bind success, `EADDRINUSE`, and unexpected bind errors.
- [x] 1.2 Add stale-socket recovery path: failed handshake on `EADDRINUSE` -> unlink once -> single bind retry.
- [x] 1.3 Refactor startup into role-driven flow (`owner` / `non-owner`) combined with `showMenu` flag matrix.

## 2. UI runtime modes and control abstraction

- [x] 2.1 Introduce menu control protocol with local and remote implementations (`LocalControl` and `RemoteControl`).
- [x] 2.2 Wire owner full-mode to local control with direct coordinator calls.
- [x] 2.3 Wire non-owner full-mode to UI-only client that subscribes/controls daemon over IPC client.

## 3. Unified quit and lifecycle parity

- [x] 3.1 Route menu Quit through control abstraction so local mode calls coordinator shutdown and remote mode sends `.quit` IPC command.
- [x] 3.2 Ensure `startwatch stop` and menu Quit converge to the same daemon shutdown path and observable effect.
- [x] 3.3 Keep non-owner headless startup as clean duplicate exit without side effects.

## 4. LaunchAgent and compatibility

- [x] 4.1 Ensure LaunchAgent uses `/usr/local/bin/startwatch daemon --no-menu` and remove app-bundle daemon path assumptions from installer flow.
- [x] 4.2 Preserve CLI IPC compatibility for status/check/start/stop/restart commands after startup refactor.

## 5. Verification

- [x] 5.1 Add race-focused tests for near-simultaneous launchd/app startup and `EADDRINUSE` arbitration outcomes.
- [x] 5.2 Add tests for app launch when daemon already exists: UI-only client mode without second coordinator ownership.
- [x] 5.3 Add tests for Quit parity in local and remote menu modes, then run `swift test`.
