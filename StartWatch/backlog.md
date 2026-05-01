1. Если выходишь из меню и заново запускаешь не всегда появляется меню

swift build
[1/1] Planning build
Building for debugging...
[2/2] Emitting module StartWatch
Build complete! (0.75s)
./install.sh 

StartWatch Installer
════════════════════

Building release binary...
✓ Build complete
✓ StartWatchMenu.app bundle id set to com.user.startwatch.menu.1777639840
✓ StartWatchMenu.app installed at /Applications/StartWatchMenu.app
✓ StartWatchMenu.app signed (ad-hoc)
✓ StartWatchMenu.app signature verified
Password:
Sorry, try again.
Password:
✓ CLI wrapper installed to /usr/local/bin/startwatch
✓ Directories created
⚠ Config already exists, skipping
✓ LaunchAgent installed at /Users/agaibadulin/Library/LaunchAgents/com.user.startwatch.plist
✓ LaunchAgent reloaded

Installation complete!

Next steps:
  1. Edit config:   startwatch config
  2. Start daemon:  startwatch daemon &
  3. Check status:  startwatch doctor

startwatch daemon &
[1] 61398

[Daemon] Config loaded: 4 services configured

[1]  + killed     startwatch daemon
startwatch doctor
StartWatch Doctor

  ✓ Config exists
  ✓ Config is valid JSON
  ✓ Config has no errors
  ✓ Daemon is running
  ✓ LaunchAgent installed
  ✓ Terminal 'warp' available
  ✓ Menu app installed
  ✓ Menu app signature valid
  ✗ Notification permission

Services configured: 4
  • genidea_log [http:http://localhost:3001]
  • Ollama [http:http://localhost:11434/api/tags]
  • ai_roovy [http:http://localhost:3000]
  • eliza_proxy [http:http://localhost:3100/v1/health]

startwatch start
Usage: startwatch start <service-name>
startwatch --help
StartWatch — service monitor for macOS

USAGE:
    startwatch <command> [options]

COMMANDS:
    status, s          Show status of all services
    check, c           Run checks now and show results
    start <name>       Start a specific service
    restart <name|all> Restart a service or all failed
    list               List all configured services
    stop               Stop daemon and menu agent
    config             Open config in $EDITOR
    log                Show check history
    doctor             Diagnose StartWatch itself

EXAMPLES:
    startwatch status              Show service status
    startwatch check               Run all checks
    startwatch restart all         Restart all failed (live table)
    startwatch restart Redis       Restart specific service
    startwatch list                List configured services
    startwatch stop                Stop StartWatch
    startwatch daemon --no-menu    Run daemon without menu bar

OPTIONS:
    --json             Output as JSON
    --tag <tag>        Filter by tag
    --no-color         Disable colors

CONFIG:
    /Users/agaibadulin/.config/startwatch/config.json
startwatch status

  StartWatch Status
  2026-05-01 15:52:53

  ❌  genidea_log  down     stopped
       ➜ cd /Users/agaibadulin/Desktop/projects/vibe/genidea && node log-server.js
  ❌  Ollama       down     stopped
       ➜ ollama serve
  ❌  ai_roovy     down     stopped
       ➜ cd /Users/agaibadulin/Desktop/projects/vibe/groovy_agent && node server.js
  ❌  eliza_proxy  down     stopped
       ➜ cd /Users/agaibadulin/Desktop/projects/vibe/eliza-proxy && node server.js

  4 of 4 services down
  Run: startwatch restart all

startwatch restart all
Checking services...
⏳  genidea_log                    starting... 0.0s
✓  Ollama                         running    0.7s

Restarted 2 services successfully
startwatch status

  StartWatch Status
  2026-05-01 15:53:01

  ❌  genidea_log  down     starting
       ➜ cd /Users/agaibadulin/Desktop/projects/vibe/genidea && node log-server.js
  ❌  Ollama       down     starting
       ➜ ollama serve
  ❌  ai_roovy     down     unknown
       ➜ cd /Users/agaibadulin/Desktop/projects/vibe/groovy_agent && node server.js
  ❌  eliza_proxy  down     unknown
       ➜ cd /Users/agaibadulin/Desktop/projects/vibe/eliza-proxy && node server.js

  4 of 4 services down
  Run: startwatch restart all

startwatch restart all
Checking services...
All services are running!
startwatch status

  StartWatch Status
  2026-05-01 15:53:08

  ❌  genidea_log  down     starting
       ➜ cd /Users/agaibadulin/Desktop/projects/vibe/genidea && node log-server.js
  ❌  Ollama       down     starting
       ➜ ollama serve
  ❌  ai_roovy     down     unknown
       ➜ cd /Users/agaibadulin/Desktop/projects/vibe/groovy_agent && node server.js
  ❌  eliza_proxy  down     unknown
       ➜ cd /Users/agaibadulin/Desktop/projects/vibe/eliza-proxy && node server.js

  4 of 4 services down
  Run: startwatch restart all

startwatch list
^C
startwatch restart all
Checking services...
All services are running!
startwatch daemon &
[1] 64758

[Daemon] Config loaded: 4 services configured
^P^[[200~startwatch status^[[201~
startwatch status

  StartWatch Status
  2026-05-01 15:53:49

  ❌  genidea_log  down     starting
       ➜ cd /Users/agaibadulin/Desktop/projects/vibe/genidea && node log-server.js
  ❌  Ollama       down     starting
       ➜ ollama serve
  ❌  ai_roovy     down     unknown
       ➜ cd /Users/agaibadulin/Desktop/projects/vibe/groovy_agent && node server.js
  ❌  eliza_proxy  down     unknown
       ➜ cd /Users/agaibadulin/Desktop/projects/vibe/eliza-proxy && node server.js

  4 of 4 services down
  Run: startwatch restart all

startwatch doctor
StartWatch Doctor

  ✓ Config exists
  ✓ Config is valid JSON
  ✓ Config has no errors
  ✓ Daemon is running
  ✓ LaunchAgent installed
  ✓ Terminal 'warp' available
  ✓ Menu app installed
  ✓ Menu app signature valid
  ✓ Notification permission

Services configured: 4
  • genidea_log [http:http://localhost:3001]
  • Ollama [http:http://localhost:11434/api/tags]
  • ai_roovy [http:http://localhost:3000]
  • eliza_proxy [http:http://localhost:3100/v1/health]

startwatch daemon
[Daemon] Config loaded: 4 services configured
^C
npm start
npm error code ENOENT
npm error syscall open
npm error path /Users/agaibadulin/Desktop/projects/vibe/StartWatch/package.json
npm error errno -2
npm error enoent Could not read package.json: Error: ENOENT: no such file or directory, open '/Users/agaibadulin/Desktop/projects/vibe/StartWatch/package.json'
npm error enoent This is related to npm not being able to find a file.
npm error enoent
npm error A complete log of this run can be found in: /Users/agaibadulin/.npm/_logs/2026-05-01T12_54_40_646Z-debug-0.log
bash install.sh

StartWatch Installer
════════════════════

Building release binary...
✓ Build complete
✓ StartWatchMenu.app bundle id set to com.user.startwatch.menu.1777640086
✓ StartWatchMenu.app installed at /Applications/StartWatchMenu.app
✓ StartWatchMenu.app signed (ad-hoc)
✓ StartWatchMenu.app signature verified
✓ CLI wrapper installed to /usr/local/bin/startwatch
✓ Directories created
⚠ Config already exists, skipping
✓ LaunchAgent installed at /Users/agaibadulin/Library/LaunchAgents/com.user.startwatch.plist
✓ LaunchAgent reloaded

Installation complete!

Next steps:
  1. Edit config:   startwatch config
  2. Start daemon:  startwatch daemon &
  3. Check status:  startwatch doctor

startwatch config
Opening in nano...
^C
startwatch daemon &
[2] 66734

[Daemon] Config loaded: 4 services configured
^P^[[200~startwatch doctor^[[201~
startwatch doctor
StartWatch Doctor

  ✓ Config exists
  ✓ Config is valid JSON
  ✓ Config has no errors
  ✓ Daemon is running
  ✓ LaunchAgent installed
  ✓ Terminal 'warp' available
  ✓ Menu app installed
  ✓ Menu app signature valid
  ✗ Notification permission

Services configured: 4
  • genidea_log [http:http://localhost:3001]
  • Ollama [http:http://localhost:11434/api/tags]
  • ai_roovy [http:http://localhost:3000]
  • eliza_proxy [http:http://localhost:3100/v1/health]

startwatch status

  StartWatch Status
  2026-05-01 15:55:22

  ✅  genidea_log  running  HTTP 200
  ✅  Ollama       running  HTTP 200
  ✅  ai_roovy     running  HTTP 200
  ✅  eliza_proxy  running  HTTP 200

  All 4 services running ✓

startwatch doctor
StartWatch Doctor

  ✓ Config exists
  ✓ Config is valid JSON
  ✓ Config has no errors
  ✓ Daemon is running
  ✓ LaunchAgent installed
  ✓ Terminal 'warp' available
  ✓ Menu app installed
  ✓ Menu app signature valid
  ✗ Notification permission

Services configured: 4
  • genidea_log [http:http://localhost:3001]
  • Ollama [http:http://localhost:11434/api/tags]
  • ai_roovy [http:http://localhost:3000]
  • eliza_proxy [http:http://localhost:3100/v1/health]

kill startwatch
kill: illegal pid: startwatch
lsof startwatch
lsof: status error on startwatch: No such file or directory
lsof 4.91
 latest revision: ftp://lsof.itap.purdue.edu/pub/tools/unix/lsof/
 latest FAQ: ftp://lsof.itap.purdue.edu/pub/tools/unix/lsof/FAQ
 latest man page: ftp://lsof.itap.purdue.edu/pub/tools/unix/lsof/lsof_man
 usage: [-?abhlnNoOPRtUvVX] [+|-c c] [+|-d s] [+D D] [+|-f[cgG]]
 [-F [f]] [-g [s]] [-i [i]] [+|-L [l]] [+|-M] [-o [o]] [-p s]
 [+|-r [t]] [-s [p:s]] [-S [t]] [-T [t]] [-u s] [+|-w] [-x [fl]] [--] [names]
Use the ``-h'' option to get more help information.
ps aux | grep startwatch
agaibadulin      69564   0.0  0.0 441884032   1168 s007  R+    3:56PM   0:00.00 grep startwatch
agaibadulin      66734   0.0  0.1 442255392  17728 s007  SN    3:55PM   0:00.06 /Applications/StartWatchMenu.app/Contents/MacOS/startwatch daemon
agaibadulin      66139   0.0  0.1 442255184  17872   ??  S     3:54PM   0:00.06 /Applications/StartWatchMenu.app/Contents/MacOS/startwatch daemon
agaibadulin      64758   0.0  0.1 442255344  17360 s007  SN    3:53PM   0:00.05 /Applications/StartWatchMenu.app/Contents/MacOS/startwatch daemon
agaibadulin      63063   0.0  0.4 442741808  63680   ??  S     3:52PM   0:03.72 /Applications/StartWatchMenu.app/Contents/MacOS/startwatch menu-agent
kill -9 66139

kill -9 66734
[2]  + killed     startwatch daemon                                                                                                                                                                                                                                                         
kill -9 69564
kill: kill 69564 failed: no such process
kill -9 64758
[1]  + killed     startwatch daemon                                                                                                                                                                                                                                                         
ps aux | grep startwatch
agaibadulin      63063  10.7  0.4 442742368  63728   ??  S     3:52PM   0:04.10 /Applications/StartWatchMenu.app/Contents/MacOS/startwatch menu-agent
agaibadulin      70383   0.0  0.0 441883568   1152 s007  R+    3:57PM   0:00.00 grep startwatch
kill -9 63063

ps aux | grep startwatch
agaibadulin      70686   0.0  0.0 441888416   1280 s007  R+    3:57PM   0:00.00 grep startwatch
kill -9 70686
kill: kill 70686 failed: no such process
ps aux | grep startwatch
agaibadulin      70942   0.0  0.0 441887488   1344 s007  S+    3:57PM   0:00.00 grep startwatch
kill -9 70942
kill: kill 70942 failed: no such process
ps aux | grep startwatch
agaibadulin      71231   0.0  0.0 441887808   1344 s007  S+    3:57PM   0:00.00 grep startwatch
kill -9 71231
kill: kill 71231 failed: no such process
startwatch doctor
StartWatch Doctor

  ✓ Config exists
  ✓ Config is valid JSON
  ✓ Config has no errors
  ✗ Daemon is running
  ✓ LaunchAgent installed
  ✓ Terminal 'warp' available
  ✓ Menu app installed
  ✓ Menu app signature valid
  ✗ Notification permission

Services configured: 4
  • genidea_log [http:http://localhost:3001]
  • Ollama [http:http://localhost:11434/api/tags]
  • ai_roovy [http:http://localhost:3000]
  • eliza_proxy [http:http://localhost:3100/v1/health]

StartWatch daemon &
[1] 71818

[Daemon] Config loaded: 4 services configured
