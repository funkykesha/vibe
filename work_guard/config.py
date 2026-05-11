import json
import os
from pathlib import Path

CONFIG_DIR = Path.home() / ".config" / "work_guard"
CONFIG_FILE = CONFIG_DIR / "config.json"

DEFAULTS = {
    "work_start": "09:00",
    "work_end": "19:00",
    "work_days": [1, 2, 3, 4, 5],  # 1=Mon, 7=Sun
    "notification_interval_min": 5,
    "overlay_delay_min": 20,
    "overlay_lock_initial_sec": 30,
    "overlay_lock_max_sec": 1800,
    "calendar_source": "xmlcalendar_ru",
    "calendar_cache_days": 30,
    "pause_until": None,
    "work_apps": [
        "Xcode", "Visual Studio Code", "Cursor", "Terminal", "iTerm2", "Warp",
        "Safari", "Google Chrome", "Firefox", "Yandex", "Yandex Browser",
        "Mail", "Slack", "Zoom", "Telegram",
        "Notion", "Obsidian", "PyCharm", "IntelliJ IDEA",
        "Figma", "Postman", "TablePlus", "DataGrip",
        "Python", "python3", "zsh", "bash",
    ]
}


def load_config() -> dict:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    if not CONFIG_FILE.exists():
        save_config(DEFAULTS.copy())
        return DEFAULTS.copy()
    with open(CONFIG_FILE) as f:
        data = json.load(f)
    # Fill missing keys with defaults
    for k, v in DEFAULTS.items():
        data.setdefault(k, v)
    return data


def save_config(cfg: dict):
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    with open(CONFIG_FILE, "w") as f:
        json.dump(cfg, f, indent=2, ensure_ascii=False)
