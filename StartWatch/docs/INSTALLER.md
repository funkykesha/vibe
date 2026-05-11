# StartWatch Installer Contract

## Artifacts

Installer builds one Mach-O and deploys two copies:

- `/usr/local/bin/startwatch`
- `/Applications/StartWatchMenu.app/Contents/MacOS/startwatch`

`/usr/local/bin/startwatch` must be Mach-O (not shell wrapper).

## App Bundle

Installer replaces `/Applications/StartWatchMenu.app` and writes:

- `Contents/MacOS/startwatch`
- `Contents/Info.plist` with bundle id `com.user.startwatch.menu`

Then:

- `lsregister -f /Applications/StartWatchMenu.app` (non-fatal on failure)
- ad-hoc `codesign --force --deep --sign - /Applications/StartWatchMenu.app`

## LaunchAgent

Plist path:

`~/Library/LaunchAgents/com.user.startwatch.plist`

Required keys:

- `Label = com.user.startwatch`
- `ProgramArguments = ["/usr/local/bin/startwatch", "daemon"]`
- `RunAtLoad = true`
- `KeepAlive.SuccessfulExit = false`
- `ThrottleInterval = 10`
- `StandardOutPath = ~/.local/state/startwatch/daemon.log`
- `StandardErrorPath = ~/.local/state/startwatch/daemon-error.log`

## Permissions

- state dir `~/.local/state/startwatch`: `0700`
- socket `~/.local/state/startwatch/sock`: `0600`

## `startwatch install`

CLI `startwatch install` is LaunchAgent repair/bootstrap only.
It does not build, copy binaries, or codesign.

## Validation

Use:

```bash
startwatch doctor
```

Doctor validates:

- CLI Mach-O path
- app bundle path and codesign
- LaunchAgent label/args/keys
- LaunchServices resolution for `com.user.startwatch.menu`
- socket and state-dir permissions
