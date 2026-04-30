## Why

The auto-exit-after-probe feature currently uses `process.exit(0)` to terminate the server immediately without closing active HTTP connections. This abruptly terminates in-flight requests and prevents proper resource cleanup, which can cause errors in clients or leave resources in inconsistent states.

## What Changes

- Export the server object created by `app.listen()` so it can be accessed for graceful shutdown
- Add graceful shutdown logic that checks if the server is listening and closes it before exiting
- Make the exit callback async to support `await server.close()`
- Only attempt graceful shutdown if the server is actually listening (e.g., after crash during startup)

No breaking changes - this adds proper cleanup without changing external behavior.

## Capabilities

### Modified Capabilities
- `auto-exit-after-probe`: Add graceful shutdown requirement
  - Server SHALL close listening HTTP connections before exiting
  - If server is not listening (startup error), exit without graceful close

## Impact

- Modified code: `server.js` (export server variable, make exit callback async, add server.close())
- New server object reference required in exit callback closure
- No API changes - internal cleanup logic only
- No new dependencies
- Tests should verify graceful shutdown behavior when server is listening
