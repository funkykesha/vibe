## Why

StartWatch v2.0 is working but carries two real architectural debts: file-based IPC polling (2s latency, no backpressure) and Swift 6 concurrency data races in ServiceChecker. A review found the `representedObject` tuple issue already resolved via closures in `ServiceMenuItemView`.

## What Changes

- Replace file-based IPC polling (every 2s) with Unix domain socket for immediate delivery and cleaner lifecycle
- Resolve Swift 6 data races in `ServiceChecker`: `resumed` bool captured across multiple `DispatchQueue` closures

## Capabilities

### New Capabilities
- `ipc-unix-socket`: Replace file-polling IPC with Unix domain socket between daemon and CLI/menu-agent
- `swift6-concurrency`: Fix data races in `ServiceChecker` — `resumed` bool mutated from concurrent queues

### Modified Capabilities
<!-- No existing specs — this is greenfield -->

## Impact

- `Sources/StartWatch/IPC/IPCServer.swift` — rewrite transport layer (timer+file → socket listener)
- `Sources/StartWatch/IPC/IPCClient.swift` — rewrite transport layer (file write → socket send)
- `Sources/StartWatch/IPC/IPCMessage.swift` — unchanged (message format stays)
- `Sources/StartWatch/Core/ServiceChecker.swift` — replace unsafe `resumed` bool with `withTaskCancellationHandler` or `CheckedContinuation` isolation
