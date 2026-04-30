## Context

StartWatch currently has:
- HistoryLogger: appends check results (UP/DOWN) to a log file with ISO8601 timestamps
- Config system: loads AppConfig from JSON, manages ServiceConfig, CheckConfig models
- ServiceRunner/ServiceChecker: executes service checks and lifecycle operations
- No visibility into config loading/parsing/validation steps
- No visibility into service startup sequence or errors during initialization

Constraints:
- macOS 13+
- CLI-driven (plus daemon menu bar app)
- Config file at ~/.config/startwatch/config.json

## Goals / Non-Goals

**Goals:**
- Log when config is accessed, loaded, parsed, validated
- Log service lifecycle: startup attempts, readiness checks, state changes, shutdown
- Structured log format (timestamp, level, service/component, message) for analysis
- Make logs queryable via CLI (show logs for specific service, time range)
- Differentiate between INFO (normal flow) and ERROR (failures)

**Non-Goals:**
- Real-time log streaming UI
- Remote log aggregation
- Debug-level tracing (just INFO and ERROR)
- Rotation/compression of log files (handled separately)

## Decisions

**Decision 1: Extend HistoryLogger pattern for structured logging**
- Add structured log entries alongside existing check results
- Log format: JSON lines (each line is a complete object) for easy parsing
- File: ~/.config/startwatch/logs/events.json (separate from check history)
- Rationale: HistoryLogger already has file append logic; extend it for config+service events
- Alternative considered: syslog integration (too heavyweight for local CLI tool)

**Decision 2: Log points in Config and Service modules**
- Config.swift: log when load(), parse() operations succeed/fail
- ServiceRunner.swift: log when start(), restart() operations execute and complete
- ServiceChecker.swift: log when check() runs, what type, and result
- Rationale: Instrument at source where decisions are made
- Alternative: wrapper in CLI layer (misses daemon-side operations)

**Decision 3: Async-safe logging (no contention with file operations)**
- Use DispatchQueue.global(qos: .utility) for file I/O
- Non-blocking append (don't block main/check threads)
- Rationale: Daemon and CLI both write logs; contention can cause delays
- Trade-off: May lose logs if app crashes immediately after write queued

**Decision 4: CLI integration - `startwatch logs` command**
- New CLI flag: `startwatch logs [--service <name>] [--since <ISO8601>] [--level ERROR]`
- Reads events.json, filters by service/time/level, outputs human-readable format
- Rationale: Aligns with existing CLI structure
- Alternative: Direct file access (less portable, harder to filter)

## Risks / Trade-offs

**[Risk]** Log file grows unbounded
→ **Mitigation**: Document rotation strategy (separate task); events.json should be rotated weekly

**[Risk]** Logging adds latency to config loading (on startup path)
→ **Mitigation**: Use async dispatch queue; log failures synchronously (rare), success async

**[Risk]** Service name collisions in logs (if config reloaded)
→ **Mitigation**: Include config load timestamp in each log entry; queries can filter by time

**[Trade-off]** JSON lines format vs. human-readable
→ Choice: JSON lines. Reason: Parseable and still human-readable per line. CLI layer formats for display.
