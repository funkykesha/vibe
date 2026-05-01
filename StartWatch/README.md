# StartWatch

Menu bar + CLI monitor for developer services (Redis, Postgres, custom processes).

The menu bar icon shows service status at a glance with four states:
- ♻️ All services running
- ⏳ Services starting up
- ⚠️ Mixed state (some running, some failed)
- ❌ All services failed

Full control from any terminal.

## Requirements

- macOS 13+
- Swift 5.9+ (`xcode-select --install`)
- No other dependencies

## Install

```bash
git clone <repo-url> StarWatch
cd StarWatch
bash install.sh
```

The installer builds the release binary, installs it to `/usr/local/bin/startwatch`, and registers a LaunchAgent so the daemon starts automatically on login.

## Configure

```bash
startwatch config    # opens $EDITOR (or nano)
```

Config file: `~/.config/startwatch/config.json`

```json
{
  "terminal": "warp",
  "checkIntervalMinutes": 1,
  "notifications": true,
  "services": [
    {
      "name": "Redis",
      "check": { "type": "port", "value": "6379" },
      "startupTimeout": 15
    },
    {
      "name": "Postgres",
      "check": { "type": "port", "value": "5432" },
      "startupTimeout": 30
    },
    {
      "name": "Backend",
      "check": { "type": "http", "value": "http://localhost:3000/health" },
      "startupTimeout": 20
    },
    {
      "name": "Worker",
      "check": { "type": "process", "value": "sidekiq" }
    }
  ]
}
```

### Service configuration options

| Field           | Type    | Description                                |
|-----------------|---------|--------------------------------------------|
| `name`          | string  | Service name (required)                    |
| `check`         | object  | How to check if service is running         |
| `start`         | string  | Command to start service (optional)        |
| `restart`       | string  | Command to restart service (optional)      |
| `cwd`           | string  | Working directory for commands (optional)  |
| `tags`          | array   | Tags for filtering (optional)              |
| `open`          | string  | URL or command to open service (optional)  |
| `autostart`     | boolean | Start service on daemon launch (optional)  |
| `startupTimeout`| integer | Seconds to wait for service startup (optional, default: 10) |

### Check types

| `type`    | `value` example              | Passes when                          |
|-----------|------------------------------|--------------------------------------|
| `port`    | `"6379"`                     | TCP connect to localhost:port succeeds |
| `http`    | `"http://localhost:3000"`    | HTTP GET returns 2xx/3xx             |
| `process` | `"redis-server"`             | `pgrep -f <value>` finds a match     |
| `command` | `"pg_isready -q"`            | Command exits with code 0            |

### Terminal values

| `terminal`   | App                  |
|--------------|----------------------|
| `warp`       | Warp                 |
| `iterm`      | iTerm2               |
| `terminal`   | Apple Terminal (default) |
| `alacritty`  | Alacritty            |
| `kitty`      | Kitty                |

## Start the daemon

The LaunchAgent starts the daemon automatically on next login. To start it immediately without rebooting:

```bash
startwatch daemon &
```

Or verify it's already running:

```bash
startwatch doctor
```

## CLI reference

| Command                    | Description                               |
|----------------------------|-------------------------------------------|
| `startwatch` / `status`    | Show all services; exit code = failed count |
| `startwatch check`         | Force live re-check, skip cache           |
| `startwatch start <svc>`   | Run start command for a service           |
| `startwatch restart <svc>` | Restart a service (fuzzy name match)      |
| `startwatch restart all`   | Restart all failed services with live output |
| `startwatch list`          | List all configured services              |
| `startwatch stop`          | Stop daemon and menu agent                |
| `startwatch log`           | Tail check history                        |
| `startwatch config`        | Open config in $EDITOR                    |
| `startwatch doctor`        | Diagnose StartWatch itself                |
| `startwatch daemon`        | Launch menu bar daemon (foreground)       |
| `startwatch daemon --no-menu` | Launch daemon without menu bar agent  |

Flags available on `status` / `check`: `--json`, `--no-color`.

### Restart with live output

The `startwatch restart all` command provides live feedback during service restarts:

```
⏳  Redis                          starting... 0.5s
⏳  Postgres                       starting... 0.5s

✓  Redis                          running      2.1s
✗  Postgres                       failed       10.0s timeout (10s)
```

Services that are already running are skipped. The command exits with code 0 on success or the number of failed services.

Exit code of `startwatch status` equals the number of failed services (0 = all OK — scriptable in CI or shell prompts).

## Troubleshooting

**Daemon not running after install**

The LaunchAgent is registered but the daemon starts on next login. Start it immediately:

```bash
startwatch daemon &
```

Or log out and back in.

**Menu bar icon missing**

Run `startwatch doctor` to check all prerequisites. If the daemon is running but the icon is gone, try:

```bash
launchctl kickstart -k "gui/$(id -u)/com.user.startwatch"
```

**`startwatch status` shows stale data**

The CLI reads the daemon's last check cache (valid for 4 hours). Force a live check:

```bash
startwatch check
```

**Config not found**

Default location: `~/.config/startwatch/config.json`. Create it from the example:

```bash
cp /path/to/StarWatch/config.example.json ~/.config/startwatch/config.json
startwatch config
```

**Notification permission denied**

Notifications require the daemon to be running as a proper app bundle. Grant permission in System Settings → Notifications → StartWatch, then restart the daemon.
