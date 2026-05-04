## 1. LaunchAgent Lifecycle

- [ ] 1.1 Add `com.startwatch.daemon` LaunchAgent plist template with `RunAtLoad`, keepalive-on-crash, log paths, PATH, and exit timeout.
- [ ] 1.2 Implement `startwatch install` to write plist, migrate/remove legacy `com.user.startwatch`, and bootstrap + kickstart new job.
- [ ] 1.3 Implement `startwatch uninstall` to bootout `com.startwatch.daemon`, remove plist, and clean legacy label artifacts.

## 2. Client Bootstrap Removal

- [ ] 2.1 Remove `.app` bootstrap fallback (`open -na ... menu-agent`) from IPC client and related retry paths.
- [ ] 2.2 Update daemon-dependent CLI commands to surface daemon-offline guidance instead of implicit bootstrap.
- [ ] 2.3 Remove app-bundle default daemon bootstrap call so menu-agent no longer attempts to own daemon lifecycle.

## 3. Menu-Agent Offline UX

- [ ] 3.1 Add menu-agent daemon connectivity check and offline state rendering (`Daemon not running`).
- [ ] 3.2 Add menu action to start daemon via `launchctl kickstart -k gui/<uid>/com.startwatch.daemon`.
- [ ] 3.3 Ensure normal status polling resumes automatically once daemon becomes available.

## 4. Daemon Signal Handling

- [ ] 4.1 Add SIGTERM dispatch source and route signal into existing coordinator shutdown path.
- [ ] 4.2 Ensure shutdown path performs idempotent cleanup of scheduler, watcher, IPC socket, and persisted state.

## 5. Validation

- [ ] 5.1 Add/update tests for CLI router commands (`install`, `uninstall`) and IPC no-bootstrap behavior.
- [ ] 5.2 Validate by code search that CLI no longer contains `open -na` bootstrap for daemon recovery.
- [ ] 5.3 Run `swift test` and manual checks for install/uninstall, restart-after-kill, offline menu state, and SIGTERM graceful exit.
