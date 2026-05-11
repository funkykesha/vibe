"""
Activity monitoring:
- Active application via NSWorkspace (PyObjC)
- Keyboard activity via pynput
- Lid open/close via IOKit PowerManagement (PyObjC)
"""

import logging
import subprocess
import threading
import time
import datetime
from typing import Optional
from production_calendar import ProductionCalendar

logger = logging.getLogger(__name__)

# Try to import PyObjC — required for NSWorkspace and IOKit
try:
    from AppKit import NSWorkspace
    HAS_APPKIT = True
except ImportError:
    HAS_APPKIT = False
    logger.warning("AppKit not available — falling back to osascript for active app")

try:
    from pynput import keyboard as pynput_keyboard
    HAS_PYNPUT = True
except ImportError:
    HAS_PYNPUT = False
    logger.warning("pynput not available — keyboard monitoring disabled")


def _get_active_app_osascript() -> Optional[str]:
    try:
        result = subprocess.run(
            ["osascript", "-e",
             'tell application "System Events" to get name of first application process '
             'whose frontmost is true'],
            capture_output=True, text=True, timeout=3,
        )
        return result.stdout.strip() or None
    except Exception:
        return None


def get_active_app() -> Optional[str]:
    """Return the name of the currently active (frontmost) application."""
    if HAS_APPKIT:
        try:
            info = NSWorkspace.sharedWorkspace().activeApplication()
            if info:
                return info.get("NSApplicationName")
        except Exception:
            pass
    return _get_active_app_osascript()


class KeyboardWatcher:
    """Tracks last keyboard activity time using pynput."""

    def __init__(self):
        self._last_keypress: Optional[datetime.datetime] = None
        self._lock = threading.Lock()
        self._listener: Optional[object] = None

    def start(self):
        if not HAS_PYNPUT:
            return
        self._listener = pynput_keyboard.Listener(on_press=self._on_press)
        self._listener.daemon = True
        self._listener.start()
        logger.info("Keyboard watcher started")

    def stop(self):
        if self._listener:
            try:
                self._listener.stop()
            except Exception:
                pass

    def _on_press(self, key):
        with self._lock:
            self._last_keypress = datetime.datetime.now()

    def is_active(self, idle_threshold_sec: int = 300) -> bool:
        """True if keyboard was used within the last idle_threshold_sec seconds."""
        with self._lock:
            if self._last_keypress is None:
                return False
            elapsed = (datetime.datetime.now() - self._last_keypress).total_seconds()
            return elapsed < idle_threshold_sec


class LidWatcher:
    """
    Monitors laptop lid state by polling 'ioreg' for display sleep.
    When lid closes → display sleeps → we record it.
    When lid opens → display wakes → we record the break.
    """

    def __init__(self):
        self._lid_closed = False
        self._last_open: Optional[datetime.datetime] = None
        self._lock = threading.Lock()
        self._thread: Optional[threading.Thread] = None
        self._running = False

    def start(self):
        self._running = True
        self._thread = threading.Thread(target=self._poll_loop, daemon=True)
        self._thread.start()
        logger.info("Lid watcher started (polling ioreg)")

    def stop(self):
        self._running = False

    @property
    def is_closed(self) -> bool:
        with self._lock:
            return self._lid_closed

    def _check_display_asleep(self) -> bool:
        """Check if internal display is asleep via ioreg."""
        try:
            result = subprocess.run(
                ["ioreg", "-rn", "AppleSmartBatteryManager", "-k", "ExternalConnected"],
                capture_output=True, text=True, timeout=3,
            )
            # Better: check IODisplayWrangler CurrentPowerState
            result2 = subprocess.run(
                ["ioreg", "-n", "IODisplayWrangler"],
                capture_output=True, text=True, timeout=3,
            )
            # CurrentPowerState = 0 means display off (lid closed)
            for line in result2.stdout.splitlines():
                if "CurrentPowerState" in line:
                    val = line.split("=")[-1].strip()
                    return val == "0"
        except Exception:
            pass
        return False

    def _poll_loop(self):
        while self._running:
            try:
                asleep = self._check_display_asleep()
                with self._lock:
                    if asleep and not self._lid_closed:
                        self._lid_closed = True
                        logger.info("Lid closed — display sleeping")
                    elif not asleep and self._lid_closed:
                        self._lid_closed = False
                        self._last_open = datetime.datetime.now()
                        logger.info("Lid opened — monitoring continues")
            except Exception as e:
                logger.debug(f"LidWatcher poll error: {e}")
            time.sleep(10)


class ActivityMonitor:
    """
    Main activity monitor. Tracks:
    - which application is active
    - keyboard activity
    - lid state
    """

    def __init__(self, config: dict):
        self._config = config
        self._keyboard = KeyboardWatcher()
        self._lid = LidWatcher()
        self._calendar = ProductionCalendar(config)

    def start(self):
        self._keyboard.start()
        self._lid.start()

    def stop(self):
        self._keyboard.stop()
        self._lid.stop()

    def update_config(self, config: dict):
        self._config = config
        self._calendar.update_config(config)

    # ------------------------------------------------------------------
    # Public queries
    # ------------------------------------------------------------------

    def get_active_app(self) -> Optional[str]:
        return get_active_app()

    def is_keyboard_active(self) -> bool:
        return self._keyboard.is_active(idle_threshold_sec=300)

    def is_lid_closed(self) -> bool:
        return self._lid.is_closed

    def is_work_app_active(self) -> bool:
        app = self.get_active_app()
        if not app:
            return False
        work_apps = self._config.get("work_apps", [])
        return any(w.lower() in app.lower() or app.lower() in w.lower()
                   for w in work_apps)

    def is_work_happening(self) -> bool:
        """True if the user appears to be working right now."""
        # Lid closed = definitely not working at the laptop
        if self.is_lid_closed():
            return False
        return self.is_work_app_active() or self.is_keyboard_active()

    def is_work_time(self) -> bool:
        """True if current time falls within configured work schedule."""
        now = datetime.datetime.now()
        day_info = self._calendar.classify_date(now.date())
        if not day_info.is_workday:
            return False

        try:
            start = datetime.datetime.strptime(
                self._config.get("work_start", "09:00"), "%H:%M"
            ).replace(year=now.year, month=now.month, day=now.day)
            end = datetime.datetime.strptime(
                self._config.get("work_end", "19:00"), "%H:%M"
            ).replace(year=now.year, month=now.month, day=now.day)
            if day_info.is_short_day:
                end = end - datetime.timedelta(hours=1)
        except ValueError:
            return False

        if end <= start:
            return False
        return start <= now <= end

    def is_paused(self) -> bool:
        """True if monitoring is manually paused until a certain time."""
        pause_until = self._config.get("pause_until")
        if not pause_until:
            return False
        try:
            until = datetime.datetime.fromisoformat(pause_until)
            if datetime.datetime.now() < until:
                return True
            # Pause expired — clear it
            self._config["pause_until"] = None
            from config import save_config
            save_config(self._config)
        except (ValueError, TypeError):
            pass
        return False
