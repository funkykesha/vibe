# Archive: architecture-review

## Context

Change `architecture-review` fully complete (17/17 tasks, all artifacts done). Implements Unix socket IPC and Swift 6 concurrency fixes. User confirmed sync delta specs before archiving.

## Steps

### 1. Sync delta specs → main specs

Create two new main spec files from delta specs:

- Copy `openspec/changes/architecture-review/specs/ipc-unix-socket/spec.md`  
  → `openspec/specs/ipc-unix-socket/spec.md` (new file)

- Copy `openspec/changes/architecture-review/specs/swift6-concurrency/spec.md`  
  → `openspec/specs/swift6-concurrency/spec.md` (new file)

Both are pure ADDED content. Main specs dir is currently empty.

### 2. Archive change directory

```bash
mkdir -p openspec/changes/archive
mv openspec/changes/architecture-review openspec/changes/archive/2026-04-29-architecture-review
```

## Verification

- `openspec/specs/ipc-unix-socket/spec.md` exists
- `openspec/specs/swift6-concurrency/spec.md` exists
- `openspec/changes/architecture-review/` no longer exists
- `openspec/changes/archive/2026-04-29-architecture-review/` exists
- `openspec list --json` returns empty changes array
