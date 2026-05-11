## 1. Calendar Foundation

- [x] 1.1 Add config defaults for xmlcalendar source, calendar cache behavior, initial overlay lock seconds, and maximum overlay lock seconds.
- [x] 1.2 Implement a small production-calendar helper that loads yearly xmlcalendar.ru data from cache or fetches it when missing/stale.
- [x] 1.3 Parse xmlcalendar `months[].days` strings into date classifications: non-working, transferred workday, shortened workday.
- [x] 1.4 Add fallback behavior that uses configured `work_days` when calendar data is unavailable.
- [x] 1.5 Add focused tests or a local verification script for holiday, transferred workday, shortened workday, cache, and fallback cases.

## 2. Work-Time and Status Integration

- [x] 2.1 Update `ActivityMonitor.is_work_time()` to use production-calendar classification before weekly `work_days`.
- [x] 2.2 Apply shortened workday behavior by ending work time one hour before configured `work_end`.
- [x] 2.3 Split fast status refresh from overtime accounting so visible status/config changes update within 10 seconds.
- [x] 2.4 Change overtime minute calculation to use elapsed time from an overtime session start timestamp instead of loop count.
- [x] 2.5 Ensure overtime state resets when returning to work time, stopping work, or pausing monitoring.

## 3. Overlay Lock Escalation

- [x] 3.1 Track overlay lock duration state separately from overlay trigger delay state.
- [x] 3.2 Pass escalating `lock_secs` to `FullScreenOverlay.show()` instead of the current fixed 30 seconds.
- [x] 3.3 Cap escalating lock duration at configured maximum, defaulting to 1800 seconds.
- [x] 3.4 Reset overlay lock escalation together with overtime session reset.

## 4. Settings Dialog

- [x] 4.1 Add editable fields for initial overlay lock duration and maximum overlay lock duration.
- [x] 4.2 Preserve existing unknown config fields when saving settings.
- [x] 4.3 Make the settings dialog compute and apply a content-based minimum size.
- [x] 4.4 Allow enough vertical sizing or resizing so the save button is fully visible on macOS.

## 5. Documentation and Verification

- [x] 5.1 Update README settings documentation with production-calendar and overlay lock settings.
- [x] 5.2 Update architecture docs to mention xmlcalendar cache and elapsed-time overtime accounting.
- [x] 5.3 Run syntax checks for Python, shell, plist, and Swift.
- [x] 5.4 Manually verify settings dialog opens with the save button fully visible.
- [x] 5.5 Manually verify status changes within 10 seconds after changing work state or config.
