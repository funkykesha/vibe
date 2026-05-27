#!/usr/bin/env python3
"""
WorkGuard — macOS app that monitors activity and stops you from overworking.

Menu bar icon with settings, monitoring loop, notifications and full-screen overlay.
"""

import datetime
import fcntl
import json
import logging
import os
import subprocess
import sys
import threading
import time
from pathlib import Path

# Make sure we can import our own modules regardless of cwd
sys.path.insert(0, str(Path(__file__).parent))

import rumps

from config import load_config, save_config
from monitor import ActivityMonitor
from notifier import notify_overtime
from overlay import FullScreenOverlay
from ascii_art import get_entry

# ------------------------------------------------------------------
# Logging
# ------------------------------------------------------------------
CONFIG_DIR = Path.home() / ".config" / "work_guard"
CONFIG_DIR.mkdir(parents=True, exist_ok=True)

LOG_FILE = CONFIG_DIR / "work_guard.log"
LOCK_PATH = CONFIG_DIR / "work_guard.lock"
STATUS_JSON_PATH = CONFIG_DIR / "status.json"
COMMAND_JSON_PATH = CONFIG_DIR / "command.json"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(),
    ]
)
logger = logging.getLogger("work_guard")

# ------------------------------------------------------------------
# Single-instance lock (fcntl flock)
# ------------------------------------------------------------------

_LOCK_FD = None


def _notify_already_running() -> None:
    _notify_osascript(
        "WorkGuard",
        "Уже запущен — смотрите строку меню (WG) или иконку в Dock.",
    )


def _notify_started_menu_bar_hint() -> None:
    """Системное уведомление без rumps — только osascript."""
    _notify_osascript(
        "WorkGuard запущен",
        "Ищите WG справа в строке меню или иконку приложения в Dock.",
    )


_INFO_PLIST_XML = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.workguard.app</string>
    <key>CFBundleName</key>
    <string>WorkGuard</string>
</dict>
</plist>
"""


def _ensure_interpreter_info_plist() -> None:
    """rumps ищет CFBundleIdentifier в ``dirname(sys.executable)/Info.plist``. Создаём при отсутствии."""
    plist = Path(sys.executable).resolve().parent / "Info.plist"
    if plist.is_file():
        return
    try:
        plist.write_text(_INFO_PLIST_XML, encoding="utf-8")
        logger.info("Создан Info.plist для интерпретатора: %s", plist)
    except OSError as e:
        logger.warning(
            "Не удалось создать %s (%s). Выполните bash setup.sh от пользователя с правом записи в conda env.",
            plist,
            e,
        )


def _osascript_escape(text: str) -> str:
    return text.replace("\\", "\\\\").replace('"', '\\"')


def _notify_osascript(title: str, body: str) -> bool:
    """display notification через osascript; True если команда завершилась без ошибки."""
    t = _osascript_escape(title)
    b = _osascript_escape(body)
    try:
        r = subprocess.run(
            ["osascript", "-e", f'display notification "{b}" with title "{t}"'],
            check=False,
            capture_output=True,
            timeout=10,
        )
        if r.returncode != 0:
            err = (r.stderr or b"").decode("utf-8", errors="replace")
            logger.warning("osascript notification failed rc=%s: %s", r.returncode, err)
            return False
        return True
    except Exception as e:
        logger.warning("osascript notification exception: %s", e)
        return False


def _acquire_lock() -> bool:
    """Атомарная эксклюзивная блокировка — второй процесс сразу отсечётся."""
    global _LOCK_FD
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    _LOCK_FD = open(LOCK_PATH, "a+", encoding="utf-8")
    try:
        fcntl.flock(_LOCK_FD.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        _LOCK_FD.close()
        _LOCK_FD = None
        return False
    _LOCK_FD.seek(0)
    _LOCK_FD.truncate()
    _LOCK_FD.write(str(os.getpid()))
    _LOCK_FD.flush()
    return True


def _release_lock() -> None:
    global _LOCK_FD
    if _LOCK_FD is None:
        return
    try:
        fcntl.flock(_LOCK_FD.fileno(), fcntl.LOCK_UN)
    except OSError:
        pass
    try:
        _LOCK_FD.close()
    except OSError:
        pass
    _LOCK_FD = None


# ------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------
CHECK_INTERVAL = 5           # seconds between status refresh ticks

OVERLAY_FIRST_DELAY_MIN = 20
LOCK_INITIAL_SEC = 120
LOCK_MAX_SEC = 1800
NOTIFY_INTERVAL_MIN = 5
LADDER_STEPS = [20, 10, 5]
DEFER_CUTOFF_SEC = 120

STATUS_MENU_KEY = "Статус: загрузка..."

# Текст в строке меню (не эмодзи): на части конфигураций macOS эмодзи в NSStatusItem не видны.
MENU_BAR_LABEL = "WG"

# Фиксированная ширина слота (pt). NSVariableStatusItemLength на macOS 26 beta + rumps
# давал intrinsic width 0 при nil image / конфликте с deprecated API.
STATUS_ITEM_FIXED_LENGTH = 40.0


def _transparent_status_bar_image():
    """Минимальный NSImage вместо None: на части версий macOS nil трактуется как нулевой вклад в размер."""
    from AppKit import NSImage
    from Foundation import NSSize

    img = NSImage.alloc().initWithSize_(NSSize(1.0, 1.0))
    img.setTemplate_(True)
    return img


def _swift_menu_binary() -> Path:
    return Path(__file__).resolve().parent / "WorkGuardMenu" / "workguard-menu"


def _swift_menu_enabled() -> bool:
    """Нативный Swift-агент строки меню (обход PyObjC на macOS 26 beta).

    ``WORKGUARD_SWIFT_MENU=0`` — только rumps. ``WORKGUARD_SWIFT_MENU=1`` — требовать бинарник.
    Если переменная не задана — включено при наличии собранного ``workguard-menu``.
    """
    if os.environ.get("WORKGUARD_SWIFT_MENU") == "0":
        return False
    exe = _swift_menu_binary()
    ok = exe.is_file() and os.access(exe, os.X_OK)
    if os.environ.get("WORKGUARD_SWIFT_MENU") == "1":
        if not ok:
            logger.warning(
                "WORKGUARD_SWIFT_MENU=1, но нет бинарника Swift: %s (см. setup.sh)",
                exe,
            )
        return ok
    return ok


def _atomic_write_json(path: Path, data: dict) -> None:
    tmp = path.with_suffix(path.suffix + ".tmp")
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    tmp.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    tmp.replace(path)


def next_work_start_after(anchor_dt: datetime.datetime, settings: dict, calendar) -> datetime.datetime:
    """Return next datetime when work starts, searching up to 14 days ahead."""
    work_start_time = datetime.datetime.strptime(
        settings.get("work_start", "09:00"), "%H:%M"
    ).time()
    work_days = settings.get("work_days", [1, 2, 3, 4, 5])
    for i in range(1, 15):
        candidate = anchor_dt.date() + datetime.timedelta(days=i)
        try:
            day_info = calendar.classify_date(candidate)
            is_work = day_info.is_workday
        except Exception:
            is_work = candidate.isoweekday() in work_days
        if is_work:
            return datetime.datetime.combine(candidate, work_start_time)
    return anchor_dt + datetime.timedelta(days=1)


def last_work_end_before(anchor_dt: datetime.datetime, settings: dict, calendar) -> datetime.datetime:
    """Return the most recent work_end datetime on or before anchor_dt."""
    work_end_time = datetime.datetime.strptime(
        settings.get("work_end", "19:00"), "%H:%M"
    ).time()
    work_days = settings.get("work_days", [1, 2, 3, 4, 5])
    today = anchor_dt.date()
    today_end = datetime.datetime.combine(today, work_end_time)
    if today_end <= anchor_dt:
        try:
            day_info = calendar.classify_date(today)
            if day_info.is_workday:
                return today_end
        except Exception:
            if today.isoweekday() in work_days:
                return today_end
    for i in range(1, 8):
        candidate = anchor_dt.date() - datetime.timedelta(days=i)
        try:
            day_info = calendar.classify_date(candidate)
            is_work = day_info.is_workday
        except Exception:
            is_work = candidate.isoweekday() in work_days
        if is_work:
            return datetime.datetime.combine(candidate, work_end_time)
    return datetime.datetime.combine(today - datetime.timedelta(days=1), work_end_time)


class WorkGuardApp(rumps.App):

    def __init__(self, initial_cfg: dict):
        super().__init__(
            name="WorkGuard",
            title=MENU_BAR_LABEL,
            quit_button=None,
        )

        self.cfg = initial_cfg
        self._swift_menu = _swift_menu_enabled()
        self._swift_proc: subprocess.Popen | None = None
        self._last_status_json: str | None = None

        self.monitor = ActivityMonitor(self.cfg)
        self.overlay = FullScreenOverlay()

        self._minutes_overtime = 0
        self._overtime_started_at: datetime.datetime | None = None
        self._last_notification_minute = -1
        self._status_line = "Запускается..."
        self._prev_work_time: bool | None = None

        self._bar_title_pending = MENU_BAR_LABEL
        self._defer_item: rumps.MenuItem | None = None
        self._build_menu()

        self.monitor.start()
        self._check_period_boundary_on_launch()
        self._loop_thread = threading.Thread(
            target=self._monitoring_loop, daemon=True
        )
        self._loop_thread.start()
        logger.info("WorkGuard started (swift_menu_bar=%s)", self._swift_menu)

    def _status_json_payload(self) -> dict:
        defer_btn = self._contextual_button_state()
        items: list[dict] = [
            {"id": "status", "text": self._status_line, "enabled": False},
            {"id": "settings", "text": "Настройки...", "enabled": True},
            {"id": "defer", "text": defer_btn["title"], "enabled": defer_btn["enabled"]},
            {"id": "test_overlay", "text": "Показать оверлей (тест)", "enabled": True},
        ]
        title = getattr(self, "_bar_title_pending", MENU_BAR_LABEL) or MENU_BAR_LABEL
        return {
            "title": title,
            "tooltip": self._status_line,
            "defer_button": defer_btn,
            "items": items,
        }

    def _write_status_json(self) -> None:
        if not getattr(self, "_swift_menu", False):
            return
        try:
            data = self._status_json_payload()
            key = json.dumps(data, ensure_ascii=False, sort_keys=True)
            if key == self._last_status_json:
                return
            self._last_status_json = key
            _atomic_write_json(STATUS_JSON_PATH, data)
        except Exception as e:
            logger.warning("status.json write failed: %s", e)

    def _start_swift_menu_agent(self) -> None:
        if not getattr(self, "_swift_menu", False):
            return
        self._write_status_json()
        exe = _swift_menu_binary()
        try:
            self._swift_proc = subprocess.Popen(
                [str(exe)],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                cwd=str(exe.parent),
            )
            logger.info("Swift menu bar agent started pid=%s path=%s", self._swift_proc.pid, exe)
        except Exception as e:
            logger.exception("Failed to start Swift menu agent: %s", e)
            self._swift_proc = None

    def _stop_swift_menu_agent(self) -> None:
        proc = getattr(self, "_swift_proc", None)
        if proc is None:
            return
        try:
            proc.terminate()
            proc.wait(timeout=3.0)
        except Exception as e:
            logger.debug("Swift agent terminate: %s", e)
            try:
                proc.kill()
            except Exception:
                pass
        self._swift_proc = None

    def _handle_swift_command(self, action: str) -> None:
        if action in ("status", "overtime"):
            return
        if action in ("pause", "resume"):
            return  # removed feature; older Swift may still send these
        if action == "settings":
            self.open_settings()
        elif action == "defer":
            self.defer_step()
        elif action == "test_overlay":
            self.test_overlay()
        elif action == "quit":
            self.quit_app()
        else:
            logger.warning("Неизвестная команда из command.json: %s", action)

    def run(self, **options):
        """Запуск NSApplication.

        LSUIElement=YES в Info.plist скрывает приложение из Dock и App Switcher на уровне ОС.
        """
        from AppKit import NSApplication

        ns_app = NSApplication.sharedApplication()
        logger.info("NSApplication activationPolicy: %s", int(ns_app.activationPolicy()))
        _notify_started_menu_bar_hint()
        self._start_swift_menu_agent()
        if os.environ.get("WORKGUARD_DEBUG") == "1":
            _plist = Path(sys.executable).resolve().parent / "Info.plist"
            logger.info(
                "WORKGUARD_DEBUG: executable=%s Info.plist_exists=%s",
                sys.executable,
                _plist.is_file(),
            )
            logger.info(
                "WORKGUARD_DEBUG: CONDA_PREFIX=%s CONDA_SHLVL=%s",
                os.environ.get("CONDA_PREFIX"),
                os.environ.get("CONDA_SHLVL"),
            )
        super().run(**options)

    def _log_status_item_diag(self, tag: str) -> None:
        """Снимок NSStatusItem для дебага (frame / intrinsic / title / окно кнопки).

        window=None на отложенном теге (например delayed_10s) косвенно указывает, что
        WindowServer ещё не связал view со слотом строки меню (см. сравнение conda run vs прямой python).
        """
        try:
            delegate = self._nsapp
            item = delegate.nsstatusitem
            btn = item.button()
            intrinsic = None
            if btn is not None and hasattr(btn, "intrinsicContentSize"):
                try:
                    intrinsic = str(btn.intrinsicContentSize())
                except Exception:
                    intrinsic = "intrinsicContentSize() failed"
            diag = {
                "title": repr(btn.title()) if btn is not None else None,
                "image": str(btn.image()) if btn is not None else None,
                "font": str(btn.font()) if btn is not None else None,
                "frame": str(btn.frame()) if btn is not None else None,
                "intrinsic": intrinsic,
                "length": float(item.length()) if item is not None else None,
                "visible": bool(item.isVisible()) if item is not None else None,
            }
            if btn is not None:
                try:
                    window = btn.window()
                    if window is not None:
                        diag["window_frame"] = str(window.frame())
                        diag["window_visible"] = bool(window.isVisible())
                        diag["window_on_screen"] = window.screen() is not None
                    else:
                        diag["window"] = "None"
                except Exception as we:
                    diag["window_error"] = str(we)
            logger.info("STATUS_ITEM_DIAG[%s]: %s", tag, diag)
        except Exception as e:
            logger.warning("STATUS_ITEM_DIAG[%s] failed: %s", tag, e)

    @rumps.timer(0.2)
    def _pin_status_item(self, timer) -> None:
        """Закрепить видимый слот: фиксированная длина + button API + шрифт строки меню (macOS 26)."""
        if getattr(self, "_swift_menu", False):
            if not getattr(self, "_wg_status_pinned", False):
                try:
                    self._nsapp.nsstatusitem.setVisible_(False)
                except Exception:
                    pass
                self._wg_status_pinned = True
            try:
                timer.stop()
            except Exception:
                pass
            return
        if getattr(self, "_wg_status_pinned", False):
            try:
                timer.stop()
            except Exception:
                pass
            return
        n = getattr(self, "_wg_pin_attempts", 0) + 1
        self._wg_pin_attempts = n
        if n > 25:
            logger.warning("Status item pin: giving up after %s attempts", n)
            try:
                timer.stop()
            except Exception:
                pass
            return
        try:
            from AppKit import NSFont

            delegate = self._nsapp
            item = delegate.nsstatusitem
            tiny = _transparent_status_bar_image()
            item.setVisible_(True)
            item.setImage_(tiny)
            item.setLength_(STATUS_ITEM_FIXED_LENGTH)

            btn = item.button()
            if btn is None:
                logger.warning("Status item pin attempt %s: button() is None", n)
                return                      # ← retry на следующем тике

            btn.setImage_(tiny)
            btn.setFont_(NSFont.menuBarFontOfSize_(0))
            btn.setTitle_(MENU_BAR_LABEL)

            # --- диагностика ---
            self._log_status_item_diag("pin")
            try:
                fr = str(btn.frame())
                vis = item.isVisible()
                logger.info("Status item pinned: frame=%s itemVisible=%s", fr, vis)
            except Exception as de:
                logger.info("Status item pinned (diagnostics skipped): %s", de)

            # --- принудительная высота окна (macOS 26 bug: window.height=0) ---
            try:
                window = btn.window()
                if window is not None:
                    wf = window.frame()
                    if wf.size.height == 0:
                        from AppKit import NSMakeRect
                        new_frame = NSMakeRect(
                            wf.origin.x, wf.origin.y,
                            wf.size.width, 24.0,
                        )
                        window.setFrame_display_(new_frame, True)
                        logger.warning(
                            "Forced status item window height to 24pt (was 0). new_frame=%s",
                            new_frame,
                        )
            except Exception as we:
                logger.warning("Status item window fix failed: %s", we)

            self._wg_status_pinned = True
            try:
                timer.stop()
            except Exception:
                pass
        except Exception as e:
            logger.warning("Status item pin attempt %s: %s", n, e)


    @rumps.timer(10.0)
    def _delayed_status_item_diag(self, timer) -> None:
        """Через ~10 с: title после возможной перезаписи rumps + window/layout (WindowServer)."""
        if getattr(self, "_swift_menu", False):
            try:
                timer.stop()
            except Exception:
                pass
            return
        if getattr(self, "_wg_delayed_status_diag_done", False):
            try:
                timer.stop()
            except Exception:
                pass
            return
        self._wg_delayed_status_diag_done = True
        self._log_status_item_diag("delayed_10s")
        try:
            timer.stop()
        except Exception:
            pass

    # ------------------------------------------------------------------
    # Menu construction
    # ------------------------------------------------------------------

    def _build_menu(self):
        self.menu.clear()
        state = self._contextual_button_state()
        self._defer_item = rumps.MenuItem(state["title"], callback=self._on_defer_click)
        self.menu = [
            rumps.MenuItem("WorkGuard", callback=None),
            None,
            rumps.MenuItem(STATUS_MENU_KEY, callback=None, key=None),
            None,
            rumps.MenuItem("Настройки...", callback=self.open_settings),
            self._defer_item,
            None,
            rumps.MenuItem("Показать оверлей (тест)", callback=self.test_overlay),
            None,
            rumps.MenuItem("Выйти", callback=self.quit_app),
        ]
        self._write_status_json()

    def _refresh_defer_item(self) -> None:
        if self._defer_item is None:
            return
        state = self._contextual_button_state()
        try:
            self._defer_item._menuitem.setTitle_(state["title"])
            self._defer_item._menuitem.setEnabled_(state["enabled"])
        except Exception:
            self._defer_item.title = state["title"]

    # ------------------------------------------------------------------
    # Menu actions
    # ------------------------------------------------------------------

    @rumps.clicked("Настройки...")
    def open_settings(self, _=None):
        import subprocess as sp
        script = Path(__file__).parent / "settings_dialog.py"
        try:
            sp.Popen([sys.executable, str(script)])
        except FileNotFoundError:
            logger.error("Settings dialog script not found: %s", script)
        except Exception as e:
            logger.exception("Failed to open settings dialog: %s", e)

    def _contextual_button_state(self) -> dict:
        if self._overtime_started_at is None:
            return {"title": "Работаем!", "enabled": False}
        deferral = self.cfg.get("deferral")
        if not deferral:
            return {"title": "Работаем!", "enabled": False}
        steps = deferral.get("steps_consumed", [])
        if len(steps) >= len(LADDER_STEPS):
            return {"title": "пора отдыхать", "enabled": False}
        now = datetime.datetime.now()
        try:
            next_at = datetime.datetime.fromisoformat(deferral["next_overlay_at"])
            if now >= next_at - datetime.timedelta(seconds=DEFER_CUTOFF_SEC):
                return {"title": "пора отдыхать", "enabled": False}
        except Exception:
            pass
        step = LADDER_STEPS[len(steps)]
        step_unlock_str = deferral.get("step_unlock_at")
        if step_unlock_str:
            try:
                unlock_at = datetime.datetime.fromisoformat(step_unlock_str)
            except Exception:
                unlock_at = None
            if unlock_at is not None and now < unlock_at:
                return {"title": f"Отложить на {step} мин", "enabled": False}
        return {"title": f"Отложить на {step} мин", "enabled": True}

    def _on_defer_click(self, _=None):
        self.defer_step()

    def defer_step(self) -> None:
        deferral = self.cfg.get("deferral")
        if not deferral or self._overtime_started_at is None:
            logger.info("defer_step: not in overtime or no deferral")
            return
        steps = deferral.get("steps_consumed", [])
        if len(steps) >= len(LADDER_STEPS):
            logger.info("defer_step: ladder exhausted")
            return
        try:
            now = datetime.datetime.now()
            next_at = datetime.datetime.fromisoformat(deferral["next_overlay_at"])
            if now >= next_at - datetime.timedelta(seconds=DEFER_CUTOFF_SEC):
                logger.info("defer_step: within cutoff window")
                return
            step_unlock_str = deferral.get("step_unlock_at")
            if step_unlock_str:
                try:
                    unlock_at = datetime.datetime.fromisoformat(step_unlock_str)
                except Exception:
                    unlock_at = None
                if unlock_at is not None and now < unlock_at:
                    logger.info("defer_step: step unlock delay active until %s", unlock_at)
                    return
            step = LADDER_STEPS[len(steps)]
            steps.append(f"+{step}")
            next_at += datetime.timedelta(minutes=step)
            unlock_delay_min = step * 3 // 4
            deferral["steps_consumed"] = steps
            deferral["next_overlay_at"] = next_at.isoformat()
            deferral["step_unlock_at"] = (now + datetime.timedelta(minutes=unlock_delay_min)).isoformat()
            self.cfg["deferral"] = deferral
            save_config(self.cfg)
            logger.info("Deferred +%s min; next_overlay_at=%s; unlock_at=%s",
                        step, next_at, deferral["step_unlock_at"])
            self._refresh_defer_item()
            self._write_status_json()
        except Exception as e:
            logger.exception("defer_step failed: %s", e)

    @rumps.clicked("Показать оверлей (тест)")
    def test_overlay(self, _=None):
        art, msg = get_entry(2)
        threading.Thread(
            target=self.overlay.show, args=(art, msg, LOCK_INITIAL_SEC), daemon=True
        ).start()

    @rumps.clicked("Выйти")
    def quit_app(self, _=None):
        try:
            logger.info("Quitting WorkGuard")
            self._stop_swift_menu_agent()
            self.overlay.close()
            self.monitor.stop()
            _release_lock()
            rumps.quit_application()
        except Exception as e:
            logger.exception("Failed to quit application: %s", e)

    # ------------------------------------------------------------------
    # Monitoring loop
    # ------------------------------------------------------------------

    def _monitoring_loop(self):
        while True:
            try:
                self._tick()
            except Exception as e:
                logger.exception("Monitoring loop error: %s", e)
            time.sleep(CHECK_INTERVAL)

    def _tick(self):
        self.cfg = load_config()
        self.monitor.update_config(self.cfg)

        in_work_time = self.monitor.is_work_time()
        working = self.monitor.is_work_happening()
        active_app = self.monitor.get_active_app() or "—"

        logger.debug("Tick: work_time=%s working=%s app=%s", in_work_time, working, active_app)

        # Period boundary: False→True transition
        if self._prev_work_time is not None and not self._prev_work_time and in_work_time:
            self._run_period_promotion()
        self._prev_work_time = in_work_time

        if in_work_time:
            self._reset_overtime_state()
            self._update_icon(emoji="🟢")
            return

        if not working:
            self._reset_overtime_state()
            self._update_icon(emoji="⚪")
            return

        now = datetime.datetime.now()

        if self._overtime_started_at is None:
            self._overtime_started_at = now
            self._init_deferral(now)

        m = int((now - self._overtime_started_at).total_seconds() // 60)
        self._minutes_overtime = max(0, m)
        self._update_icon(emoji="🔴", app=active_app, minutes=m)

        if m > 0 and m % NOTIFY_INTERVAL_MIN == 0 and m != self._last_notification_minute:
            self._last_notification_minute = m
            notify_overtime(m)

        deferral = self.cfg.get("deferral")
        if deferral:
            try:
                next_at = datetime.datetime.fromisoformat(deferral["next_overlay_at"])
                if now >= next_at:
                    self._fire_overlay(deferral, now)
            except Exception as e:
                logger.warning("Overlay scheduling error: %s", e)

        self._refresh_defer_item()

    @rumps.timer(1)
    def _sync_bar_title(self, _timer) -> None:
        """Sync menu bar title on main thread via button() API (macOS 13+ requirement)."""
        if getattr(self, "_swift_menu", False):
            self._write_status_json()
            return
        pending = getattr(self, "_bar_title_pending", MENU_BAR_LABEL)
        try:
            btn = self._nsapp.nsstatusitem.button()
            if btn is not None and btn.title() != pending:
                btn.setTitle_(pending)
        except Exception:
            pass

    @rumps.timer(0.5)
    def _poll_swift_commands(self, _timer) -> None:
        """Команды из Swift (command.json): pause, settings, quit, …"""
        if not getattr(self, "_swift_menu", False):
            return
        if not COMMAND_JSON_PATH.is_file():
            return
        try:
            raw = COMMAND_JSON_PATH.read_text(encoding="utf-8")
            data = json.loads(raw)
            COMMAND_JSON_PATH.unlink(missing_ok=True)
        except Exception as e:
            logger.warning("command.json read failed: %s", e)
            return
        action = data.get("action")
        if not isinstance(action, str):
            return
        logger.info("command.json action=%s", action)
        try:
            self._handle_swift_command(action)
        except Exception:
            logger.exception("command.json handler failed")

    def _update_icon(self, emoji="🟢", app=None, minutes=0):
        if emoji == "🟢":
            bar_title = "WG 🟢"
            status = "🟢 Рабочее время"
        elif emoji == "⚪":
            bar_title = "WG"
            status = "⚪ Нерабочее время — отдыхаешь"
        elif emoji == "🔴":
            bar_title = "WG 🔴"
            status = f"🔴 Переработка: {minutes} мин | {app}"
        else:
            bar_title = "WG"
            status = "..."

        self._bar_title_pending = bar_title
        self._status_line = status
        try:
            self.menu[STATUS_MENU_KEY].title = status
        except Exception:
            pass
        self._write_status_json()

    def _reset_overtime_state(self) -> None:
        self._minutes_overtime = 0
        self._overtime_started_at = None
        self._last_notification_minute = -1

    def _init_deferral(self, overtime_start: datetime.datetime) -> None:
        ps = self.cfg.get("current_period_settings", {})
        try:
            period_id = last_work_end_before(
                overtime_start, ps, self.monitor._calendar
            ).isoformat()
        except Exception:
            period_id = overtime_start.isoformat()
        next_overlay_at = (overtime_start + datetime.timedelta(minutes=OVERLAY_FIRST_DELAY_MIN)).isoformat()
        self.cfg["deferral"] = {
            "period_id": period_id,
            "steps_consumed": [],
            "next_overlay_at": next_overlay_at,
            "cadence_min": OVERLAY_FIRST_DELAY_MIN,
            "next_lock_sec": LOCK_INITIAL_SEC,
        }
        save_config(self.cfg)
        logger.info("Deferral period opened period_id=%s next_overlay_at=%s", period_id, next_overlay_at)

    def _fire_overlay(self, deferral: dict, now: datetime.datetime) -> None:
        lock_secs = max(1, int(deferral.get("next_lock_sec", LOCK_INITIAL_SEC)))
        cadence = int(deferral.get("cadence_min", OVERLAY_FIRST_DELAY_MIN))
        new_cadence = cadence * 2
        new_next_lock = min(LOCK_MAX_SEC, lock_secs * 2)
        new_next_at = now + datetime.timedelta(minutes=new_cadence)
        deferral["next_overlay_at"] = new_next_at.isoformat()
        deferral["cadence_min"] = new_cadence
        deferral["next_lock_sec"] = new_next_lock
        self.cfg["deferral"] = deferral
        save_config(self.cfg)
        m = self._minutes_overtime
        art, msg = get_entry(level=min(2, m // 20))
        threading.Thread(target=self.overlay.show, args=(art, msg, lock_secs), daemon=True).start()
        logger.info("Overlay fired: lock=%ss next_in=%smin", lock_secs, new_cadence)

    def _run_period_promotion(self) -> None:
        pending = self.cfg.get("pending_period_settings")
        if pending:
            self.cfg["current_period_settings"] = pending
        self.cfg["pending_period_settings"] = None
        self.cfg["deferral"] = None
        save_config(self.cfg)
        self.monitor.update_config(self.cfg)
        logger.info("Period promotion: pending→current, deferral reset")

    def _check_period_boundary_on_launch(self) -> None:
        deferral = self.cfg.get("deferral")
        if not deferral:
            return
        try:
            next_at = datetime.datetime.fromisoformat(deferral["next_overlay_at"])
            now = datetime.datetime.now()
            if abs((next_at - now).total_seconds()) > 86400:
                logger.info("Clock jump detected; resetting deferral")
                self.cfg["deferral"] = None
                save_config(self.cfg)
                return
            ps = self.cfg.get("current_period_settings", {})
            period_id_dt = datetime.datetime.fromisoformat(deferral["period_id"])
            next_period_start = next_work_start_after(period_id_dt, ps, self.monitor._calendar)
            if now >= next_period_start:
                self._run_period_promotion()
        except Exception as e:
            logger.warning("_check_period_boundary_on_launch failed: %s", e)


def main():
    # Finder/launchd often start GUI apps with cwd "/"; normalize for subprocesses and paths.
    try:
        os.chdir(Path(__file__).resolve().parent)
    except OSError as e:
        logger.debug("Could not chdir to script dir: %s", e)
    _ensure_interpreter_info_plist()
    cfg = load_config()
    if not _acquire_lock():
        logger.error("WorkGuard уже запущен. Выход.")
        _notify_already_running()
        sys.exit(0)
    try:
        app = WorkGuardApp(cfg)
        app.run()
    finally:
        _release_lock()


if __name__ == "__main__":
    main()
