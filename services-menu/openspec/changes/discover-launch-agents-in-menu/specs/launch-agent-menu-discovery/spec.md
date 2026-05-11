## ADDED Requirements

### Requirement: Discover managed LaunchAgents from plist files
The system SHALL build its managed service list from readable plist files in `~/Library/LaunchAgents` whose filenames match `com.agaibadulin.*.plist`.

#### Scenario: Existing plist appears in menu
- **WHEN** `~/Library/LaunchAgents/com.agaibadulin.WorkGuard.plist` exists and contains `Label` set to `com.agaibadulin.WorkGuard`
- **THEN** the menu includes a managed service item for `WorkGuard`

#### Scenario: Non-matching plist is ignored
- **WHEN** `~/Library/LaunchAgents/com.google.keystone.agent.plist` exists
- **THEN** the menu does not include a managed service item for that plist

### Requirement: Use plist Label as service identity
The system SHALL use each discovered plist's `Label` value as the service identity for status lookup, display naming, and restart commands.

#### Scenario: Label differs from filename
- **WHEN** a matching plist filename contains one suffix but its `Label` contains another valid label
- **THEN** the menu item and restart command use the plist `Label`

### Requirement: Exclude ServicesMenu from managed services
The system MUST exclude ServicesMenu's own LaunchAgent from the managed service list.

#### Scenario: ServicesMenu plist exists
- **WHEN** `~/Library/LaunchAgents/com.agaibadulin.services-menu.plist` exists
- **THEN** the menu does not include `services-menu` as a restartable managed service item

### Requirement: Refresh menu after config creation
The system SHALL refresh the managed service list after successfully creating a LaunchAgent config.

#### Scenario: Created config becomes visible
- **WHEN** the user creates a valid `com.agaibadulin.<name>.plist` through Add Config
- **THEN** the newly created service appears in the menu without restarting ServicesMenu

### Requirement: Continue when a plist cannot be read
The system SHALL skip unreadable or malformed matching plist files and continue rendering other discovered services.

#### Scenario: Malformed plist does not break menu
- **WHEN** one matching plist cannot be parsed and another matching plist is valid
- **THEN** the valid service still appears in the menu
