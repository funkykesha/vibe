## ADDED Requirements

### Requirement: Typed configuration
The backend SHALL read configuration through a typed settings object.

#### Scenario: Local backend starts
- **WHEN** required deployment-only or bot-only variables are absent during local backend startup
- **THEN** the backend SHALL start with documented local defaults

#### Scenario: Module needs config
- **WHEN** backend code needs configuration
- **THEN** it SHALL use the shared settings object instead of reading environment variables directly

### Requirement: Secret handling
The repository SHALL provide an example environment file while excluding local secrets.

#### Scenario: Developer configures locally
- **WHEN** a developer copies `.env.example` to `.env`
- **THEN** local backend defaults SHALL be discoverable
- **AND** real secrets SHALL NOT be committed

### Requirement: Database foundation
The backend SHALL provide database engine, session, and model foundation for accounts and settings.

#### Scenario: Request uses database
- **WHEN** an API endpoint reads or writes persisted finance state
- **THEN** it SHALL use a bounded database session that is closed after the request

### Requirement: Idempotent seed
Seed behavior SHALL add missing default account/settings records without overwriting existing financial values.

#### Scenario: Seed runs twice
- **WHEN** seed is run against a database that already contains seeded records
- **THEN** duplicate accounts SHALL NOT be created
- **AND** existing balances SHALL NOT be overwritten

### Requirement: Accounts API
The backend SHALL expose current accounts as a flat JSON list and support narrow account updates.

#### Scenario: List accounts
- **WHEN** the client calls `GET /api/accounts`
- **THEN** the backend SHALL return HTTP 200 with an array of account objects

#### Scenario: Update account balance
- **WHEN** the client updates an account
- **THEN** only allowed balance/currency fields SHALL change
- **AND** model fields such as name, bank, category, and type SHALL NOT be silently rewritten by that request

### Requirement: Settings API
The backend SHALL expose current dashboard settings and accept partial settings updates.

#### Scenario: Read settings
- **WHEN** the client calls `GET /api/settings`
- **THEN** the backend SHALL return categories, deductions, USD rate, and mortgage settings

#### Scenario: Partial settings update
- **WHEN** the client sends only one settings field
- **THEN** the backend SHALL preserve the other settings fields

### Requirement: Static dashboard serving
The backend SHALL serve the dashboard over HTTP for local use.

#### Scenario: Open local dashboard
- **WHEN** the user opens the configured local backend URL
- **THEN** the backend SHALL return the static dashboard document

### Requirement: CORS and trusted boundary
The backend SHALL allow documented local origins and require explicit deployed origin/access configuration.

#### Scenario: Local browser requests API
- **WHEN** the dashboard is served from a documented local origin
- **THEN** API requests SHALL be accepted without CORS failure

#### Scenario: Deployed API is exposed
- **WHEN** the backend is configured for deployment
- **THEN** allowed origins and single-user access boundary SHALL be explicitly configured
