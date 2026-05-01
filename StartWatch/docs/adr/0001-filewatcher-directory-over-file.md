# ADR 0001: FileWatcher Directory vs File FSEvents

## Status
Accepted

## Context
The FileWatcher component monitors the configuration file (`~/.config/startwatch/config.json`) for changes to trigger hot-reload of the daemon configuration.

The initial implementation used a 500ms timer polling the file's modification time. This approach had issues:
- Editors (VSCode, vim, Sublime) use atomic saves: write to temp file, rename into place
- Polling interval was arbitrary (500ms) and missed rapid consecutive saves
- CPU waste from continuous polling

We considered rewriting it to use FSEvents for efficient event-driven monitoring.

## Decision
Use `DispatchSource.makeFileSystemObjectSource` to watch the **parent directory** (`~/.config/startwatch/`) with `O_EVTONLY`, not the config file itself.

### Implementation Details

1. Watch directory events: `eventMask: [.write, .rename]`
2. On event callback, check mtime of target config file
3. Use 200ms debounce via cancellable `DispatchWorkItem`

```swift
source = DispatchSource.makeFileSystemObjectSource(
    fileDescriptor: fileDescriptor,
    eventMask: [.write, .rename],
    queue: DispatchQueue.global()
)
```

## Why Directory Watching?

### Problem with File-Level FSEvents
When editors use atomic saves (write temp → rename), the inode of the file changes:
- File descriptor opened on old inode becomes stale
- New inode is not represented by the old fd
- File-level fd receives no further events after the rename

Many modern editors (VSCode, vim, Sublime Text) use this pattern by default.

### Why Directory Watching Works
A directory descriptor (`O_EVTONLY`) survives inode replacements in its children:
- Directory inode doesn't change when files inside are renamed
- All file operations (write, rename, delete) generate events on the directory
- We filter for the specific config file by checking its mtime

### Why Not Alternatives?

| Alternative | Problem |
|-------------|---------|
| File-level FSEvents | Fails on atomic saves (inode replaced) |
| Watch file + reopen fd on rename | More complex than directory watching with no benefit |
| Continue polling | Wastes CPU, arbitrary interval, misses rapid saves |

## Consequences

### Positive
- Immediate detection of config changes without CPU waste
- Works reliably with all editors including atomic-save editors
- 200ms debounce handles multiple events from single save operation
- No legacy `fw.log` debug file needed

### Negative
- Receives events for any file in the directory
- Must filter by checking target file's mtime (minor overhead)
- More code than polling (~70 lines vs ~30 lines)

## References
- [DispatchSource.FileSystemObject](https://developer.apple.com/documentation/dispatch/dispatchsourcefilesystemobject)
- [FSEvents Programming Guide](https://developer.apple.com/library/archive/documentation/Darwin/Conceptual/FSEvents_ProgGuide/)
- [Atomic Save Pattern](https://www.appcoda.in/atomic-save-pattern/)
