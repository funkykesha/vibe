## ADDED Requirements

### Requirement: CLI writes isStarting state to cache before spawn
System SHALL write `isStarting: true` for each service about to be restarted to `last_check.json` before spawning processes.

#### Scenario: Restart all writes starting state
- **WHEN** user runs `startwatch restart all` for 3 services
- **THEN** system writes `[CodableCheckResult...]` with `isStarting: true` for all 3 services immediately

#### Scenario: Daemon overwrites starting state periodically
- **WHEN** daemon performs next check cycle after CLI wrote `isStarting: true`
- **THEN** daemon overwrites entries with real results (`isRunning: true/false`, `isStarting: false`)

### Requirement: Menu bar reads isStarting from cache and reflects in icon
System SHALL read `isStarting` field from `last_check.json` and use it to determine menu bar icon state.

#### Scenario: Menu shows spinner when service starting
- **WHEN** menu agent reads cache with one entry having `isStarting: true`
- **THEN** menu bar displays ⏳ icon

#### Scenario: Menu updates when service starts successfully
- **WHEN** daemon writes new cache entry with `isRunning: true, isStarting: false`
- **THEN** menu agent on next poll reads entry, shows ♻️ if all running

### Requirement: CodableCheckResult includes isStarting field
`CodableCheckResult` struct SHALL include `isStarting: Bool` field with default value `false`.

#### Scenario: Decode old cache file without isStarting field
- **WHEN** system reads `last_check.json` from before this change (no `isStarting` key)
- **THEN** Codable decoder defaults `isStarting` to `false`, old files decode successfully

#### Scenario: Encode new cache file with isStarting
- **WHEN** system writes new cache entries after restart
- **THEN** JSON includes `"isStarting": true/fals`` field
