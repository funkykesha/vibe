---

## Issue: Build Cache Caused API Signature Mismatch

**Problem:**
After fixing the convenience init issue, there were concerns about API signature mismatches between the file content and what the compiler was seeing.

**Root Cause:**
Build cache (`.build` directory) had cached old compilation artifacts that didn't reflect the corrected FileWatcher.swift changes.

**Resolution:**
Removed the entire build directory and performed a clean rebuild:
```bash
rm -rf .build
swift build
```

**Results:**
- Build completed successfully (7.30s)
- No compilation errors
- No LSP diagnostics
- API signatures match exactly:
  - `convenience init(filePath: String)`
  - `public init(configDirectoryURL: URL)`
  - `public func start(onChange: @escaping () -> Void)`

**Lesson Learned:**
- When making critical API changes, always clean build cache
- Swift's incremental compilation can cache stale signatures
- Use `rm -rf .build` for clean rebuilds (no `--clean` flag available)
