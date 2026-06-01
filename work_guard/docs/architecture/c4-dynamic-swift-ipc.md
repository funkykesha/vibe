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
  Rel(py, cmd, "4. Reads and handles settings/defer/overlay/quit")
  Rel(swift, swift, "5. Quit: terminate self after write", "(optional)")

  UpdateRelStyle(py, status, $textColor="#1565c0", $offsetY="-12")
  UpdateRelStyle(swift, cmd, $textColor="#1565c0", $offsetY="-12")
```

## Action IDs

Written by Swift into `command.json` under `"action"` (handled in `WorkGuardApp._handle_swift_command`):

| Action | Effect |
|--------|--------|
| `settings` | Open settings dialog |
| `defer` | Consume next deferral ladder step (`defer_step()`) |
| `test_overlay` | Show test overlay |
| `quit` | Graceful shutdown |

Legacy `pause` / `resume` actions are defensively ignored — the pause feature was removed; older Swift binaries may still emit them.

Read-only display rows (`status`, `overtime`) are ignored as commands.

## Deferral button payload

`status.json` carries a `defer_button: {title, enabled}` object that drives the single
contextual menu item. Python computes it from deferral state via `_contextual_button_state()`:

| State | title | enabled |
|-------|-------|---------|
| Outside overtime | `Работаем!` | `false` |
| Cutoff window or ladder exhausted | `пора отдыхать` | `false` |
| Step unlock delay active | `Отложить на N мин` | `false` |
| Ladder step available | `Отложить на {20\|10\|5} мин` | `true` |

Swift renders the item from `defer_button`; if the field is missing it omits the item
(no crash). Click writes `command.json {"action": "defer", "ts": ...}`.
