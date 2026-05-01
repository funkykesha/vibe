## 1. Export Server Object

- [x] 1.1 Locate the `app.listen()` call (line ~280)
- [x] 1.2 Capture the return value into a `server` variable: `const server = app.listen(PORT, ...)`
- [x] 1.3 Verify the `server` variable is accessible in the exit callback closure

## 2. Make Exit Callback Async

- [x] 2.1 Convert the setTimeout callback from `() => { }` to `async () => { }` (line ~70)
- [x] 2.2 Convert the setTimeout call to support async callback

## 3. Add Graceful Shutdown Logic

- [x] 3.1 Add check for `server.listening` before closing (line ~74)
- [x] 3.2 Add `await server.close()` call inside the listening check
- [x] 3.3 Ensure the exit message still logs before graceful close
- [x] 3.4 Verify `process.exit(0)` runs after server close completes

## 4. Verification

- [x] 4.1 Run existing tests to ensure normal exit behavior still works
- [ ] 4.2 Test graceful shutdown with in-flight HTTP request (new test)
- [ ] 4.3 Test exit without graceful shutdown when server never started (error case)
- [x] 4.4 Verify backward compatibility: `--exit-after-probe` flag behavior unchanged
