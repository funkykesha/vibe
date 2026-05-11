# Troubleshooting

## Daemon Offline In Menu

- Use menu action `Start Daemon` (kickstart only), or:

```bash
launchctl kickstart gui/$(id -u)/com.user.startwatch
```

- Validate installation:

```bash
startwatch doctor
```

## Stale Socket / Startup Failure

Daemon runtime attempts stale socket recovery automatically.
If startup still fails:

1. Ensure state dir exists and permissions are correct.
2. Check socket permissions (`0600`) and owner.
3. Re-run installer.

## LaunchAgent Not Starting

Check plist:

```bash
plutil -lint ~/Library/LaunchAgents/com.user.startwatch.plist
launchctl print gui/$(id -u)/com.user.startwatch
```

Expected:

- `ProgramArguments: /usr/local/bin/startwatch daemon`
- `RunAtLoad=true`
- `KeepAlive.SuccessfulExit=false`
- `ThrottleInterval=10`

## Menu App Not Appearing

1. Verify app exists:
   - `/Applications/StartWatchMenu.app`
2. Verify codesign:
   - `codesign -vvv /Applications/StartWatchMenu.app`
3. Refresh LaunchServices:
   - `lsregister -f /Applications/StartWatchMenu.app`

## Intentional Stop vs Failure Restart

- `startwatch quit` / menu `Stop Daemon` -> clean exit (`0`), launchd does not auto-restart.
- crash/fatal exit (`!=0`) -> launchd may restart daemon (throttled).

## Service Stop Fails

Stop strategy order:

1. explicit `stop` command
2. managed PID
3. discovered PID/port
4. `no stoppable target` error

Escalation:

- SIGTERM
- wait 5s
- SIGKILL if still alive

Check structured logs in `~/.config/startwatch/logs/events.json`.
