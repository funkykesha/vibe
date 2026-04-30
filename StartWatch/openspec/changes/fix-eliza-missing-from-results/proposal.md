## Why

ServiceChecker.checkAll() returns only 3 of 4 configured services. The 4th service (Eliza Proxy on localhost:3100) is silently dropped before results are saved, causing it to never appear in the menu or CLI output. This is a critical bug preventing visibility and management of the Eliza service.

## What Changes

- Diagnose and fix the root cause of the missing 4th result in ServiceChecker.checkAll()
- Ensure all configured services are included in check results
- Add logging/instrumentation if needed to prevent future regressions
- Verify Eliza Proxy appears in menu and CLI status output

## Capabilities

### New Capabilities
- `service-check-reliability`: Ensure all configured services are checked and returned reliably, with no silent drops due to concurrency issues or task group problems

### Modified Capabilities
<!-- None — this is a bug fix, not a spec change -->

## Impact

- **Affected files**: `Sources/StartWatch/Core/ServiceChecker.swift`, possibly `Sources/StartWatch/Daemon/AppDelegate.swift` (if the issue is in how results are saved)
- **Affected code paths**: Service checker task group (`checkAll`), HTTP check handler
- **User impact**: Eliza Proxy service becomes visible and manageable in StartWatch menu/CLI
- **No API changes**: Existing service check behavior remains; fix restores missing functionality
