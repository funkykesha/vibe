## Context

StartWatch daemon and CLI/menu-agent communicate via two file-based channels:
1. `trigger_check` flag file (touch → daemon polls every 2s)
2. `menu_command.json` (written by menu-agent, consumed by daemon on next poll)

Both are in `~/.local/state/startwatch/`. The 2s poll introduces latency and has no error path. `ServiceChecker` uses a `var resumed = false` bool captured by closures from different `DispatchQueue` contexts — a data race that strict Swift 6 concurrency will flag.

## Goals / Non-Goals

**Goals:**
- Replace file-polling with Unix domain socket (immediate delivery, clean shutdown)
- Eliminate data races in `ServiceChecker` for Swift 6 compat
- Keep `IPCMessage` enum unchanged — no protocol break

**Non-Goals:**
- Two-way streaming / subscriptions (daemon → client push)
- TLS or auth on the socket (local-only, single-user)
- Replacing `NSStatusItem` architecture

## Decisions

**D1: Unix socket over NSXPCConnection**
`Foundation.Socket` / raw POSIX is available in SPM without AppKit. NSXPCConnection requires registered services and Info.plist — too heavy for a local CLI tool. Decision: raw POSIX socket, one connect-write-read-close per command.

*Alternative: NSXPCConnection* — rejected, requires AppKit and entitlements.

**D2: Socket path = `StateManager.stateDir/daemon.sock`**
Stays in the existing state directory, no new path. Socket is deleted on clean exit and on daemon startup (stale socket handling).

**D3: Replace `resumed` bool with `ManagedAtomic` or `NSLock`**
Options:
- `ManagedAtomic<Bool>` from `swift-atomics` — clean but adds dependency
- `NSLock` protecting the bool — zero new deps, straightforward
- Rewrite with `async/await` native constructs replacing `withCheckedContinuation` entirely

Decision: **NSLock** protecting `resumed`, no new dependencies. `withCheckedContinuation` stays — it's the correct bridge for callback-based APIs.

*Alternative: withTaskCancellationHandler* — possible but adds complexity for timeout handling.

**D4: Swift 6 concurrency mode**
Add `swiftSettings: [.swiftLanguageVersion(.v6)]` to the target in `Package.swift` incrementally, fix warnings as they appear. `runSync` in `AsyncHelpers.swift` is already safe for CLI use (no main actor) — add a `// CLI-only` comment.

## Risks / Trade-offs

- **Socket stale on crash** → Mitigation: daemon startup deletes `daemon.sock` if it exists before binding
- **Menu-agent sends command while daemon restarts** → Mitigation: `IPCClient.send` silently drops (daemon not running = no socket), same behavior as current file-polling
- **NSLock vs data race** → NSLock protects mutation but if continuation is called twice the crash is deterministic and loud — acceptable over silent UB

## Migration Plan

1. Add `IPCServer` socket listener alongside existing timer (dual mode)
2. Switch `IPCClient` to socket-first, file fallback
3. Remove timer + file polling once socket is verified
4. Enable `SWIFT_STRICT_CONCURRENCY = complete`, fix all warnings
5. No config or install.sh changes needed

## Open Questions

- Does `swift test` run in the same process as AppKit? (affects `runSync` safety in test context)
