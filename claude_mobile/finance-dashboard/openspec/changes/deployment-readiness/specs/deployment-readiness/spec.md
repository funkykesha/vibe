## ADDED Requirements

### Requirement: Managed deployed database
The deployed application SHALL use managed Postgres or another approved persistent managed database for financial data.

#### Scenario: Deployment is configured
- **WHEN** the app is deployed to a hosted platform
- **THEN** `DATABASE_URL` SHALL point to persistent managed storage
- **AND** the app SHALL NOT depend on ephemeral SQLite files

### Requirement: Secret management
Deployment SHALL provide secrets through platform environment variables.

#### Scenario: Deployment starts
- **WHEN** the deployed process starts
- **THEN** required secrets SHALL be read from deployment environment configuration
- **AND** secret files SHALL NOT be committed or required in the repository

### Requirement: Backup and restore readiness
Deployment SHALL include database backup and restore procedures.

#### Scenario: Backup readiness is reviewed
- **WHEN** deployment is considered ready
- **THEN** backup schedule and restore steps SHALL be documented and tested or dry-run verified

### Requirement: Telegram webhook deployment
The deployed Telegram assistant SHALL use webhook mode only with required webhook safety configuration.

#### Scenario: Webhook is enabled
- **WHEN** Telegram webhook mode is configured
- **THEN** it SHALL use an HTTPS URL, secret token, and explicit pending-update policy

### Requirement: Deployed access boundary
The deployed app SHALL enforce the single-user trusted boundary.

#### Scenario: Public network can reach deployment
- **WHEN** the dashboard or API is reachable outside localhost
- **THEN** access SHALL be restricted to the configured trusted user/context
