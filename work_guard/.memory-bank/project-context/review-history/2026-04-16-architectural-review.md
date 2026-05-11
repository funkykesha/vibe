# 2026-04-16 Architectural Review

## Scope
Full architectural review of the WorkGuard project covering runtime logic, configuration handling, UX flows, launch lifecycle, and maintainability.

## Key Findings

### Critical
1. Product logic mismatch: [`WorkGuardApp._tick()`](work_guard.py:192) only treats work outside the configured time window as overtime, which does not match a true worked-duration model.
2. Work detection semantics in [`ActivityMonitor.is_work_happening()`](monitor.py:205) are too broad and likely to produce false positives.
3. Single-instance protection in [`_acquire_lock()`](work_guard.py:50) relies on a PID file and is vulnerable to PID reuse and stale-state issues.

### High
4. Duplicated settings UI between [`WorkGuardApp._show_settings_dialog()`](work_guard.py:277) and [`settings_dialog.py`](settings_dialog.py).
5. Settings saved by [`settings_dialog.py`](settings_dialog.py) are not reliably reloaded by the main process.
6. Startup lifecycle conflict between [`setup.sh`](setup.sh) manual background launch and [`com.workguard.plist`](com.workguard.plist) with KeepAlive.
7. Weak config validation in [`config.py`](config.py:26) and [`settings_dialog.py`](settings_dialog.py:24), including risk of zero intervals causing runtime errors in [`WorkGuardApp._tick()`](work_guard.py:228).
8. Overlay implementation in [`overlay.py`](overlay.py:84) is fragile and tightly coupled to platform-specific AppKit behavior.

### Medium
9. Excessive broad exception handling across [`work_guard.py`](work_guard.py), [`monitor.py`](monitor.py), [`overlay.py`](overlay.py), and [`settings_dialog.py`](settings_dialog.py).
10. Menu status item is updated through a fragile title lookup in [`work_guard.py`](work_guard.py:210).
11. Dead code and unused imports exist, including the unused settings dialog implementation in [`work_guard.py`](work_guard.py:277).
12. Lid detection heuristic in [`LidWatcher._check_display_asleep()`](monitor.py:122) is unreliable.
13. No explicit application state model; state is spread across flags in [`work_guard.py`](work_guard.py:192).

### Low
14. Documentation drift between [`README.md`](README.md) and actual runtime behavior.
15. No testable pure decision layer for core logic.
16. Limited structured diagnostics and state-transition logging.

## Recommended Remediation Order
1. Clarify and fix the overtime model.
2. Centralize config validation and normalization.
3. Fix lifecycle and locking.
4. Remove duplicated settings UI and add config reload behavior.
5. Stabilize platform-specific monitoring and overlay code.
6. Improve maintainability with state modeling, cleanup, and better diagnostics.

## Outcome
A switch to implementation mode was proposed after the review, but it was denied. The session ended with review findings and a prioritized remediation plan only.
