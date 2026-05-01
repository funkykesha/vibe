## ADDED Requirements

### Requirement: Menu displays four distinct icons based on aggregate state
System SHALL display one of four icons (♻️ ⏳ ⚠️ ❌) based on aggregate state with priority: `starting` > mixed > failed > all-ok.

#### Scenario: All services running
- **WHEN** all services have `isRunning: true`
- **THEN** menu bar shows ♻️ (recycle symbol)

#### Scenario: Any service starting
- **WHEN** at least one service has `isStarting: true`
- **THEN** menu bar shows ⏳ (hourglass/spinner)

#### Scenario: Mixed running and failed
- **WHEN** some services have `isRunning: true`, some have `isRunning: false` (no `isStarting` true)
- **THEN** menu bar shows ⚠️ (warning)

#### Scenario: All services failed
- **WHEN** all services have `isRunning: false` (and no `isStarting` true)
- **THEN** menu bar shows ❌ (cross mark)

### Requirement: Priority order for icon selection
Icon assignment SHALL follow priority (highest wins): starting ⏳ → mixed ⚠️ → failed ❌ → all-ok ♻️.

#### Scenario: Starting overrides mixed
- **WHEN** one service is `starting`, one is `running`, one is `failed`
- **THEN** menu bar shows ⏳ (starting takes priority)

#### Scenario: Mixed overrides failed
- **WHEN** 2 services running, 1 failed, none starting
- **THEN** menu bar shows ⚠️ (mixed takes priority over all-failed)