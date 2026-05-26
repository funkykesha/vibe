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
PAUSE_DURATION_HOURS = 1

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


class WorkGuardApp(rumps.App):

    def __init__(self, initial_cfg: dict):
        super().__init__(
            name="WorkGuard",
            title=MENU_BAR_LABEL,
            quit_button=None,   # we add a custom quit item
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
        self._last_overlay_minute = -1
        self._next_overlay_minute: int | None = None
        self._next_overlay_delay_min: int | None = None
        self._overlay_base_delay_min: int | None = None
        self._next_overlay_lock_sec: int | None = None
        self._status_line = "Запускается..."

        self._bar_title_pending = MENU_BAR_LABEL

        self._pause_item: rumps.MenuItem | None = None
        self._build_menu()
        if self.monitor.is_paused():
            self._update_icon(paused=True)
        self._refresh_pause_appearance()

        # Start background threads
        self.monitor.start()
        self._loop_thread = threading.Thread(
            target=self._monitoring_loop, daemon=True
        )
        self._loop_thread.start()
        logger.info(
            "WorkGuard started (swift_menu_bar=%s)",
            self._swift_menu,
        )

    def _status_json_payload(self) -> dict:
        """Состояние для нативного агента (status.json)."""
        paused = self.monitor.is_paused()
        items: list[dict] = [
            {"id": "status", "text": self._status_line, "enabled": False},
            {"id": "settings", "text": "Настройки...", "enabled": True},
        ]
        if paused:
            items.append({"id": "resume", "text": "Снять паузу", "enabled": True})
        else:
            items.append(
                {
                    "id": "pause",
                    "text": self._pause_base_title(),
                    "enabled": True,
                }
            )
        items.append(
            {
                "id": "test_overlay",
                "text": "Показать оверлей (тест)",
                "enabled": True,
            }
        )
        title = getattr(self, "_bar_title_pending", MENU_BAR_LABEL) or MENU_BAR_LABEL
        return {
            "title": title,
            "tooltip": self._status_line,
            "paused": paused,
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
        if action == "settings":
            self.open_settings()
        elif action in ("pause", "resume"):
            self.toggle_pause()
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
        self._pause_item = rumps.MenuItem(
            self._pause_base_title(),
            callback=self.toggle_pause,
        )
        self.menu = [
            rumps.MenuItem("WorkGuard", callback=None),
            None,
            rumps.MenuItem(
                STATUS_MENU_KEY,
                callback=None,
                key=None,
            ),
            None,
            rumps.MenuItem("Настройки...", callback=self.open_settings),
            self._pause_item,
            None,
            rumps.MenuItem("Показать оверлей (тест)", callback=self.test_overlay),
            None,
            rumps.MenuItem("Выйти", callback=self.quit_app),
        ]
        self._write_status_json()

    @staticmethod
    def _pause_base_title() -> str:
        return f"Пауза на {PAUSE_DURATION_HOURS} ч"

    def _refresh_pause_appearance(self) -> None:
        self._style_pause_item(self.monitor.is_paused())
        self._write_status_json()

    def _style_pause_item(self, paused: bool) -> None:
        if self._pause_item is None:
            return
        plain = self._pause_base_title()
        if not paused:
            try:
                self._pause_item._menuitem.setTitle_(plain)
            except Exception:
                self._pause_item.title = plain
            return

        until_str = ""
        pu = self.cfg.get("pause_until")
        if pu:
            try:
                until = datetime.datetime.fromisoformat(pu)
                until_str = until.strftime("%H:%M")
            except Exception:
                pass
        if until_str:
            text = f"⏸ Пауза до {until_str} — нажми, чтобы снять"
        else:
            text = "⏸ Пауза — нажми, чтобы снять"
        try:
            from AppKit import (
                NSAttributedString,
                NSFont,
                NSForegroundColorAttributeName,
                NSFontAttributeName,
                NSColor,
            )

            font = NSFont.menuFontOfSize_(0)
            color = NSColor.secondaryLabelColor()
            attrs = {
                NSFontAttributeName: font,
                NSForegroundColorAttributeName: color,
            }
            attr_title = NSAttributedString.alloc().initWithString_attributes_(
                text, attrs
            )
            self._pause_item._menuitem.setAttributedTitle_(attr_title)
        except Exception:
            self._pause_item.title = text

    # ------------------------------------------------------------------
    # Menu actions
    # ------------------------------------------------------------------

    @rumps.clicked("Настройки...")
    def open_settings(self, _=None):
        """Open a simple Tkinter settings dialog as a subprocess."""
        import subprocess as sp
        script = Path(__file__).parent / "settings_dialog.py"
        try:
            sp.Popen([sys.executable, str(script)])
        except FileNotFoundError:
            logger.error("Settings dialog script not found: %s", script)
        except Exception as e:
            logger.exception("Failed to open settings dialog: %s", e)

    def toggle_pause(self, _=None):
        try:
            if self.monitor.is_paused():
                self.cfg["pause_until"] = None
                save_config(self.cfg)
                self.monitor.update_config(self.cfg)
                self._reset_overtime_state()
                self._refresh_pause_appearance()
                self._sync_ui_after_pause_end()
                logger.info("Pause cancelled by user")
                return

            until = datetime.datetime.now() + datetime.timedelta(
                hours=PAUSE_DURATION_HOURS
            )
            self.cfg["pause_until"] = until.isoformat()
            save_config(self.cfg)
            self.monitor.update_config(self.cfg)
            self._reset_overtime_state()
            self._update_icon(paused=True)
            self._refresh_pause_appearance()
            try:
                rumps.notification(
                    "WorkGuard", "Пауза",
                    f"Мониторинг приостановлен до {until.strftime('%H:%M')}",
                )
            except Exception as ne:
                logger.warning("Pause notification failed (icon already updated): %s", ne)
            logger.info("Paused until %s", until)
        except Exception as e:
            logger.exception("Failed to toggle pause: %s", e)

    def _sync_ui_after_pause_end(self) -> None:
        """Иконка и статус после снятия паузы (в т.ч. вручную)."""
        in_work_time = self.monitor.is_work_time()
        working = self.monitor.is_work_happening()
        active_app = self.monitor.get_active_app() or "—"

        if in_work_time:
            self._reset_overtime_state()
            self._update_icon(emoji="🟢")
            return

        if not working:
            self._reset_overtime_state()
            self._update_icon(emoji="⚪")
            return

        self._overtime_started_at = datetime.datetime.now()
        self._update_icon(emoji="🔴", app=active_app, minutes=0)

    @rumps.clicked("Показать оверлей (тест)")
    def test_overlay(self, _=None):
        art, msg = get_entry(2)
        lock_secs, _ = self._overlay_lock_bounds()
        threading.Thread(
            target=self.overlay.show, args=(art, msg, lock_secs), daemon=True
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

        if self.monitor.is_paused():
            self._update_icon(paused=True)
            self._refresh_pause_appearance()
            return

        self._refresh_pause_appearance()

        in_work_time = self.monitor.is_work_time()
        working = self.monitor.is_work_happening()
        active_app = self.monitor.get_active_app() or "—"

        logger.debug(
            "Tick: work_time=%s working=%s app=%s",
            in_work_time, working, active_app,
        )

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
        m = int((now - self._overtime_started_at).total_seconds() // 60)
        self._minutes_overtime = max(0, m)
        self._update_icon(emoji="🔴", app=active_app, minutes=m)

        interval = self._notification_interval()
        overlay_delay = self._overlay_delay_minutes()
        lock_initial, lock_max = self._overlay_lock_bounds()

        if m > 0 and m % interval == 0 and m != self._last_notification_minute:
            self._last_notification_minute = m
            notify_overtime(m)

        if self._overlay_base_delay_min != overlay_delay:
            self._overlay_base_delay_min = overlay_delay
            self._next_overlay_delay_min = overlay_delay
            self._next_overlay_minute = overlay_delay
        if self._next_overlay_lock_sec is None:
            self._next_overlay_lock_sec = lock_initial

        if self._next_overlay_minute is not None and m >= self._next_overlay_minute:
            self._last_overlay_minute = m
            next_delay = (self._next_overlay_delay_min or overlay_delay) * 2
            self._next_overlay_delay_min = next_delay
            self._next_overlay_minute = m + next_delay
            lock_secs = max(1, int(self._next_overlay_lock_sec or lock_initial))
            self._next_overlay_lock_sec = min(lock_max, lock_secs * 2)
            art, msg = get_entry(level=min(2, m // 20))
            threading.Thread(
                target=self.overlay.show, args=(art, msg, lock_secs), daemon=True
            ).start()
            logger.info(
                "Overlay triggered at %s min overtime; next in %s min, lock=%ss",
                m,
                self._next_overlay_delay_min,
                lock_secs,
            )

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

    def _update_icon(self, emoji="🟢", paused=False, app=None, minutes=0):
        if paused:
            until_str = ""
            pause_until = self.cfg.get("pause_until")
            if pause_until:
                try:
                    until = datetime.datetime.fromisoformat(pause_until)
                    until_str = f" до {until.strftime('%H:%M')}"
                except Exception:
                    pass
            bar_title = "WG ⏸"
            status = f"⏸ Пауза{until_str}"
        elif emoji == "🟢":
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
        self._last_overlay_minute = -1
        self._next_overlay_minute = None
        self._next_overlay_delay_min = None
        self._overlay_base_delay_min = None
        self._next_overlay_lock_sec = None

    def _notification_interval(self) -> int:
        return max(1, int(self.cfg.get("notification_interval_min", 5) or 5))

    def _overlay_delay_minutes(self) -> int:
        return max(1, int(self.cfg.get("overlay_delay_min", 20) or 20))

    def _overlay_lock_bounds(self) -> tuple[int, int]:
        initial = max(1, int(self.cfg.get("overlay_lock_initial_sec", 30) or 30))
        max_lock = max(1, int(self.cfg.get("overlay_lock_max_sec", 1800) or 1800))
        if max_lock < initial:
            max_lock = initial
        return initial, max_lock


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
