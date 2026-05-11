# WorkGuard — dynamic view: Swift menu ↔ Python core

When the **Swift menu agent** is enabled, the Python core does not own the only `NSStatusItem`. Instead, Python publishes menu state to disk; Swift renders the menu and writes user intentions back. Python polls `command.json` and maps actions to handlers.

## Diagram

```mermaid
C4Dynamic
  title Dynamic Diagram — Menu command flow (Swift agent path)

  Container(py, "Python core", "rumps / PyObjC", "Orchestration")
  Container(swift, "Swift menu agent", "Cocoa", "NSStatusItem + NSMenu")
  ContainerDb(cmd, "command.json", "JSON", "User action queue")
  ContainerDb(status, "status.json", "JSON", "Title, tooltip, menu model")

  Rel(py, status, "1. Atomically writes when state changes")
  Rel(swift, status, "2. Polls mtime ~1s; rebuilds menu")
  Rel(swift, cmd, "3. Writes action + timestamp on click")
  Rel(py, cmd, "4. Reads and handles settings/pause/overlay/quit")
  Rel(swift, swift, "5. Quit: terminate self after write", "(optional)")

  UpdateRelStyle(py, status, $textColor="#1565c0", $offsetY="-12")
  UpdateRelStyle(swift, cmd, $textColor="#1565c0", $offsetY="-12")
```

## Action IDs

Written by Swift into `command.json` under `"action"` (handled in `WorkGuardApp._handle_swift_command`):

| Action | Effect |
|--------|--------|
| `settings` | Open settings dialog |
| `pause` / `resume` | Toggle pause window |
| `test_overlay` | Show test overlay |
| `quit` | Graceful shutdown |

Read-only display rows (`status`, `overtime`) are ignored as commands.
