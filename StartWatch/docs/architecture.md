# StartWatch Architecture

## System Context (Level 1)

```mermaid
C4Context
    title System Context diagram for StartWatch

    Person(developer, "Developer", "A software developer monitoring local services.")
    System(startwatch, "StartWatch", "Monitors and manages local development services.")

    System_Ext(local_services, "Local Services", "Redis, Postgres, backend servers, workers, etc.")
    System_Ext(macos, "macOS", "Operating system providing notifications, menu bar, and process management.")
    System_Ext(terminal, "Terminal Emulator", "Warp, iTerm2, Alacritty, Apple Terminal, Kitty.")

    Rel(developer, startwatch, "Configures, starts, stops, and views status using CLI or Menu Bar")
    Rel(startwatch, local_services, "Monitors health, starts, stops, and restarts")
    Rel(startwatch, macos, "Displays notifications and menu bar icon")
    Rel(startwatch, terminal, "Opens new tabs/windows to run service commands")
```

## Container (Level 2)

```mermaid
C4Container
    title Container diagram for StartWatch

    Person(developer, "Developer", "A software developer monitoring local services.")

    System_Boundary(startwatch_system, "StartWatch") {
        Container(cli, "CLI", "Swift", "Command-line interface for managing services and daemon.")
        Container(daemon, "Daemon", "Swift", "Background process that schedules checks and manages services.")
        Container(menu_agent, "Menu Agent", "Swift / App Bundle", "Menu bar application providing UI and notifications.")
    }

    System_Ext(local_services, "Local Services", "Monitored services.")
    System_Ext(macos, "macOS", "OS integration.")
    System_Ext(terminal, "Terminal Emulator", "Service execution environment.")

    Rel(developer, cli, "Executes commands (start, stop, check, status)")
    Rel(developer, menu_agent, "Interacts with menu bar icon")

    Rel(cli, daemon, "Sends commands via Unix Socket", "Unix Socket/JSON")
    Rel(cli, daemon, "Reads cached state", "File (last_check.json)")
    Rel(cli, menu_agent, "Bootstraps app runtime when daemon socket missing", "open -na ... --args menu-agent")
    
    Rel(menu_agent, daemon, "Sends commands via Unix Socket", "Unix Socket/JSON")
    Rel(menu_agent, daemon, "Polls state", "File (last_check.json)")
    Rel(menu_agent, daemon, "Sends check-now fallback (legacy)", "File (menu_command.json)")

    Rel(daemon, local_services, "Checks health (HTTP, Port, Process)")
    Rel(daemon, terminal, "Launches service commands via shell")
    Rel(menu_agent, macos, "Shows notifications & menu icon")
```

## Component (Level 3)

### CLI Components

```mermaid
C4Component
    title Component diagram for StartWatch CLI

    Container_Boundary(cli_container, "CLI Container") {
        Component(main, "main.swift", "Swift", "App entrypoint and launch-mode routing.")
        Component(cli_router, "CLI Router", "Swift", "Top-level command dispatcher.")
        Component(commands, "Commands", "Swift", "Command implementations (Check, Start, Status, etc.).")
        Component(formatting, "Formatting", "Swift", "Terminal output formatting (ANSI, Tables, Reports).")
    }

    Container(daemon, "Daemon", "Swift", "Background process.")
    Container(menu_agent, "Menu Agent", "Swift / App Bundle", "Menu bar app runtime.")
    
    Rel(main, cli_router, "Routes execution")
    Rel(cli_router, commands, "Dispatches command")
    Rel(commands, formatting, "Formats output")
    Rel(commands, daemon, "Sends IPC messages / Reads State")
    Rel(commands, menu_agent, "Bootstraps runtime if needed", "open -na")
```

### Daemon Components

```mermaid
C4Component
    title Component diagram for StartWatch Daemon

    Container_Boundary(daemon_container, "Daemon Container") {
    Component(app_delegate, "App Delegate", "Swift", "Daemon coordinator and lifecycle.")
        Component(check_scheduler, "Check Scheduler", "Swift", "Periodic check scheduling.")
        Component(ipc_server, "IPC Server", "Swift", "Unix domain socket server for commands.")
    }

    Component(service_checker, "Service Checker", "Swift", "Executes health checks.")
    Component(process_manager, "Process Manager", "Swift", "Starts/stops/restarts processes.")
    Component(state_manager, "State Manager", "Swift", "Manages state persistence (last_check.json).")
    Component(terminal_launcher, "Terminal Launcher", "Swift", "Terminal selection/dispatch abstraction.")

    Container(cli, "CLI", "Swift", "Command-line interface.")
    Container(menu_agent, "Menu Agent", "Swift", "Menu bar application.")
    System_Ext(local_services, "Local Services", "Monitored services.")
    System_Ext(terminal, "Terminal Emulator", "Service execution environment.")

    Rel(cli, ipc_server, "Sends commands")
    Rel(menu_agent, ipc_server, "Sends commands")
    
    Rel(app_delegate, ipc_server, "Initializes")
    Rel(app_delegate, check_scheduler, "Initializes")
    
    Rel(check_scheduler, service_checker, "Triggers checks")
    Rel(ipc_server, process_manager, "Triggers process actions")
    
    Rel(service_checker, state_manager, "Saves results")
    Rel(service_checker, local_services, "Checks health")
    Rel(process_manager, local_services, "Starts/stops service processes")
```

### Menu Agent Components

```mermaid
C4Component
    title Component diagram for StartWatch Menu Agent

    Container_Boundary(menu_agent_container, "Menu Agent Container") {
        Component(menu_delegate, "Menu Agent Delegate", "Swift", "Lifecycle, state polling, notifications.")
        Component(menu_view, "Service Menu Item View", "Swift", "Per-service menu UI rendering.")
        Component(ipc_client, "IPC Client", "Swift", "Sends commands to Daemon.")
        Component(notification_manager, "Notification Manager", "Swift", "Setup, delivery, action handling.")
    }

    Container(daemon, "Daemon", "Swift", "Background process.")
    System_Ext(macos, "macOS", "OS integration.")

    Rel(menu_delegate, menu_view, "Updates UI")
    Rel(menu_delegate, daemon, "Polls last_check.json")
    Rel(menu_delegate, ipc_client, "Sends user actions")
    Rel(menu_delegate, notification_manager, "Triggers notifications")
    Rel(ipc_client, daemon, "Sends commands via socket")
    Rel(notification_manager, macos, "Displays via Notification Center")
    Rel(menu_view, macos, "Renders in Menu Bar")
```

## Data Flow & IPC

StartWatch uses a hybrid IPC architecture:

1. **Real-time Command Channel (Unix Domain Socket)**
   - **Path**: `~/.local/state/startwatch/sock`
   - **Direction**: CLI/Menu → Daemon (one-way commands)
   - **Messages**: `triggerCheck`, `startService`, `stopService`, `restartService`, `quit`
   - **Auto-bootstrap**: if socket is missing, CLI first runs `open -na <StartWatchMenu.app> --args menu-agent`, then retries IPC.

2. **State Synchronization Channel (File-based Polling)**
   - **File**: `~/.local/state/startwatch/last_check.json`
   - **Direction**: Daemon → Menu/CLI
   - **Mechanism**: Daemon writes check results; Menu Agent polls every 3s (0.5s when starting); CLI reads on-demand for `status`.
   - **Note**: `menu_command.json` is only a fallback path for `check_now`; primary Menu → Daemon control path is Unix socket IPC.

## Runtime Ownership Rules

- LaunchAgent starts only `startwatch daemon --no-menu`.
- `.app` launch starts `menu-agent` and ensures daemon readiness.
- CLI acts as a client to app-owned runtime; it does not own long-lived UI lifecycle.
