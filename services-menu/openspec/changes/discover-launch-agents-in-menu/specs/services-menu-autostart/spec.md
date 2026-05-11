## ADDED Requirements

### Requirement: Launch packaged app at login
The system SHALL configure ServicesMenu login startup to launch the packaged app at `/Applications/ServicesMenu.app`.

#### Scenario: Login startup uses packaged app
- **WHEN** the ServicesMenu LaunchAgent runs at login
- **THEN** it launches `/Applications/ServicesMenu.app`

### Requirement: Install packaged app in Applications
The system SHALL install the packaged ServicesMenu app bundle at `/Applications/ServicesMenu.app`.

#### Scenario: Rebuild installs to Applications
- **WHEN** the ServicesMenu rebuild/install flow completes
- **THEN** `/Applications/ServicesMenu.app` exists as the installed app bundle

### Requirement: Do not reference removed source script
The system MUST NOT configure ServicesMenu login startup to launch `/Users/agaibadulin/Desktop/projects/vibe/services_menu.py`.

#### Scenario: Removed script path is absent
- **WHEN** the ServicesMenu LaunchAgent config is generated or installed
- **THEN** its `ProgramArguments` do not include `/Users/agaibadulin/Desktop/projects/vibe/services_menu.py`
