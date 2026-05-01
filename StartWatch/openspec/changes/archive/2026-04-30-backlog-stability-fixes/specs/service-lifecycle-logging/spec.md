## MODIFIED Requirements

### Requirement: Service configuration includes startup timeout
`ServiceConfig` struct SHALL include optional `startupTimeout` field in seconds, defaulting to 10 seconds.

#### Scenario: Service with default startup timeout
- **WHEN** config entry has no `startupTimeout` field
- **THEN** system uses default 10 seconds timeout during startup poll

#### Scenario: Service with custom timeout
- **WHEN** config entry specifies `"startupTimeout": 15`
- **THEN** system uses 15 seconds timeout for that service's startup poll

## MODIFIED Requirements

### Requirement: IPC client config is authoritative source for service list
`IPCClient.getLastResults()` SHALL return list based on config services, using cache only as status source.

#### Scenario: Config has 4 services, cache has 2 matching entries
- **WHEN** config lists [Redis, Postgres, Eliza, Worker] and cache has status for Redis and Postgres only
- **THEN** system returns 4 CheckResults — Redis+Postgres from cache status, Eliza+Worker with `unknown` status

#### Scenario: Cache has entry for service not in config
- **WHEN** cache has status for "OldService" but config does not list it
- **THEN** system ignores the cache entry, does not include in results

#### Scenario: Cache is empty or stale
- **WHEN** config lists services but cache file doesn't exist or is empty
- **THEN** system returns CheckResults for all services with `unknown` status
