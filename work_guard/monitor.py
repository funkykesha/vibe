"""
Activity monitoring:
- Input activity via pynput (keyboard + mouse)
- Active application via NSWorkspace (PyObjC)
- Lid open/close via IOKit (ioreg polling)
"""

import logging
import subprocess
import threading
import time
import datetime
from typing import Optional
from production_calendar import ProductionCalendar

logger = logging.getLogger(__name__)

try:
    from AppKit import NSWorkspace
    HAS_APPKIT = True
except ImportError:
    HAS_APPKIT = False
    logger.warning("AppKit not available — falling back to osascript for active app")

try:
    from pynput import keyboard as pynput_keyboard, mouse as pynput_mouse
    HAS_PYNPUT = True
except ImportError:
    HAS_PYNPUT = False
    logger.warning("pynput not available — input monitoring disabled")


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
    if HAS_APPKIT:
        try:
            info = NSWorkspace.sharedWorkspace().activeApplication()
            if info:
                return info.get("NSApplicationName")
        except Exception:
            pass
    return _get_active_app_osascript()


class InputWatcher:
    """Tracks last keyboard or mouse activity time using pynput."""

    def __init__(self):
        self._last_input: Optional[datetime.datetime] = None
        self._lock = threading.Lock()
        self._kb_listener: Optional[object] = None
        self._mouse_listener: Optional[object] = None

    def start(self):
        if not HAS_PYNPUT:
            return
        self._kb_listener = pynput_keyboard.Listener(on_press=self._on_input)
        self._kb_listener.daemon = True
        self._kb_listener.start()
        self._mouse_listener = pynput_mouse.Listener(
            on_move=self._on_input,
            on_click=self._on_input,
            on_scroll=self._on_input,
        )
        self._mouse_listener.daemon = True
        self._mouse_listener.start()
        logger.info("InputWatcher started (keyboard + mouse)")

    def stop(self):
        for listener in (self._kb_listener, self._mouse_listener):
            if listener:
                try:
                    listener.stop()
                except Exception:
                    pass

    def _on_input(self, *_args):
        with self._lock:
            self._last_input = datetime.datetime.now()

    def is_active(self, idle_threshold_sec: int = 300) -> bool:
        with self._lock:
            if self._last_input is None:
                return False
            return (datetime.datetime.now() - self._last_input).total_seconds() < idle_threshold_sec


class LidWatcher:
    """
    Monitors laptop lid state by polling 'ioreg' for display sleep.
    When lid closes → display sleeps. When lid opens → display wakes.
    """

    def __init__(self):
        self._lid_closed = False
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
        try:
            result2 = subprocess.run(
                ["ioreg", "-n", "IODisplayWrangler"],
                capture_output=True, text=True, timeout=3,
            )
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
                        logger.info("Lid opened — monitoring continues")
            except Exception as e:
                logger.debug("LidWatcher poll error: %s", e)
            time.sleep(10)


def _has_focused_user_app() -> bool:
    app = get_active_app()
    return bool(app)


class ActivityMonitor:
    """Tracks input activity, lid state, and work schedule."""

    def __init__(self, config: dict):
        self._config = config
        self._input = InputWatcher()
        self._lid = LidWatcher()
        self._calendar = ProductionCalendar(config)

    def start(self):
        self._input.start()
        self._lid.start()

    def stop(self):
        self._input.stop()
        self._lid.stop()

    def update_config(self, config: dict):
        self._config = config
        self._calendar.update_config(config)

    def _schedule(self) -> dict:
        return self._config.get("current_period_settings", {})

    def get_active_app(self) -> Optional[str]:
        return get_active_app()

    def is_input_active(self) -> bool:
        return self._input.is_active(idle_threshold_sec=300)

    def is_lid_closed(self) -> bool:
        return self._lid.is_closed

    def is_work_happening(self) -> bool:
        """True if user appears to be working right now."""
        if self.is_lid_closed():
            return False
        if self.is_input_active():
            return True
        # Lid open + focused app = working
        return _has_focused_user_app()

    def is_work_time(self) -> bool:
        """True if current time falls within configured work schedule."""
        now = datetime.datetime.now()
        day_info = self._calendar.classify_date(now.date())
        if not day_info.is_workday:
            return False

        sched = self._schedule()
        try:
            start = datetime.datetime.strptime(
                sched.get("work_start", "09:00"), "%H:%M"
            ).replace(year=now.year, month=now.month, day=now.day)
            end = datetime.datetime.strptime(
                sched.get("work_end", "19:00"), "%H:%M"
            ).replace(year=now.year, month=now.month, day=now.day)
            if day_info.is_short_day:
                end = end - datetime.timedelta(hours=1)
        except ValueError:
            return False

        if end <= start:
            return False
        return start <= now <= end
