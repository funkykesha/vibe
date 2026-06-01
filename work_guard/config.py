import copy
import json
import logging
import os
import shutil
from pathlib import Path

logger = logging.getLogger(__name__)

CONFIG_DIR = Path.home() / ".config" / "work_guard"
CONFIG_FILE = CONFIG_DIR / "config.json"

DEFAULTS = {
    "current_period_settings": {
        "work_start": "09:00",
        "work_end":   "19:00",
        "work_days":  [1, 2, 3, 4, 5],  # 1=Mon, 7=Sun
    },
    "pending_period_settings": None,
    "deferral": None,
    "calendar_source": "xmlcalendar_ru",
    "calendar_cache_days": 30,
    "todoist_reminder": {
        "enabled": False,
        "idle_threshold_min": 120,
        "poll_interval_min": 5,
        "reminder_cadence_min": 30,
        "grace_after_wake_min": 5,
        "history_browsers": ["yandex", "chrome"],
        "frontmost_app_name": "Todoist",
        "open_app_path": "/Applications/Todoist.app",
        "task_list_cap": 10,
    },
}

_LEGACY_FIELDS = {
    "pause_until", "work_apps", "notification_interval_min",
    "overlay_delay_min", "overlay_lock_initial_sec", "overlay_lock_max_sec",
}


def _migrate_legacy(data: dict) -> dict:
    """Lift legacy flat config into new shape. Writes backup before mutating."""
    bak = CONFIG_FILE.with_suffix(".json.pre-deferral.bak")
    if not bak.exists():
        try:
            shutil.copy2(CONFIG_FILE, bak)
        except OSError as e:
            logger.warning("migration: backup failed: %s", e)

    ps = {
        "work_start": data.get("work_start", DEFAULTS["current_period_settings"]["work_start"]),
        "work_end":   data.get("work_end",   DEFAULTS["current_period_settings"]["work_end"]),
        "work_days":  data.get("work_days",  DEFAULTS["current_period_settings"]["work_days"]),
    }

    migrated = {
        "current_period_settings": ps,
        "pending_period_settings": None,
        "deferral": None,
        "calendar_source":    data.get("calendar_source",    DEFAULTS["calendar_source"]),
        "calendar_cache_days": data.get("calendar_cache_days", DEFAULTS["calendar_cache_days"]),
    }

    logger.info(
        "migration: legacy config detected, lifted into current_period_settings; "
        "pause/work_apps fields dropped"
    )
    return migrated


def load_config() -> dict:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    if not CONFIG_FILE.exists():
        cfg = {
            "current_period_settings": dict(DEFAULTS["current_period_settings"]),
            "pending_period_settings": None,
            "deferral": None,
            "calendar_source": DEFAULTS["calendar_source"],
            "calendar_cache_days": DEFAULTS["calendar_cache_days"],
            "todoist_reminder": copy.deepcopy(DEFAULTS["todoist_reminder"]),
        }
        save_config(cfg)
        return cfg

    with open(CONFIG_FILE) as f:
        data = json.load(f)

    if "current_period_settings" not in data:
        data = _migrate_legacy(data)
        save_config(data)
        return data

    # Ensure all top-level keys present
    for k, v in DEFAULTS.items():
        if k not in data:
            data[k] = copy.deepcopy(v)
    # Ensure schedule sub-keys present
    ps = data.setdefault("current_period_settings", {})
    for k, v in DEFAULTS["current_period_settings"].items():
        ps.setdefault(k, v)
    # Ensure todoist_reminder sub-keys present (auto-fill for older configs)
    tr = data.setdefault("todoist_reminder", {})
    if isinstance(tr, dict):
        for k, v in DEFAULTS["todoist_reminder"].items():
            tr.setdefault(k, copy.deepcopy(v))

    return data


def read_todoist_token() -> str:
    """Read Todoist API token from process env or gitignored `.env`.

    Order: `TODOIST_API_TOKEN` process env → `.env` next to project.
    Token value is never logged. Returns "" if unset.
    """
    tok = os.environ.get("TODOIST_API_TOKEN", "").strip()
    if tok:
        return tok
    env_path = Path(__file__).resolve().parent / ".env"
    if env_path.is_file():
        try:
            for line in env_path.read_text(encoding="utf-8").splitlines():
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, _, val = line.partition("=")
                if key.strip() == "TODOIST_API_TOKEN":
                    return val.strip().strip('"').strip("'")
        except OSError as e:
            logger.warning("read_todoist_token: .env read failed: %s", e)
    return ""


def save_config(cfg: dict):
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    tmp = CONFIG_FILE.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(cfg, indent=2, ensure_ascii=False), encoding="utf-8")
    tmp.replace(CONFIG_FILE)
