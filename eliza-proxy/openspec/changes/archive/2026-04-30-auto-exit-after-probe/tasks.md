## 1. Implementation

- [x] 1.1 Add command-line argument parsing for `--exit-after-probe` flag in `server.js`
- [x] 1.2 Create global variable `shouldExitAfterProbe` to store flag state
- [x] 1.3 Add tracking for probe completion count
- [x] 1.4 Implement check for probe completion and flag condition
- [x] 1.5 Add `process.exit(0)` when both conditions are met

## 2. Testing

- [x] 2.1 Start server without flag - verify it keeps running: `npm start`
- [x] 2.2 Start server with flag - verify it exits after probe: `npm start -- --exit-after-probe`
- [x] 2.3 Verify exit code is 0 for successful startup
- [x] 2.4 Verify exit code is 1 for startup errors (missing ELIZA_TOKEN)

## 3. Verification

- [x] 3.1 Test with models that fail probe - ensure exit only after ALL models complete
- [x] 3.2 Verify final probe results are displayed before exit
- [x] 3.3 Confirm HTTP server doesn't accept requests when auto-exit is enabled
