import datetime
import json
import logging
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Optional
from urllib.error import URLError
from urllib.request import urlopen

logger = logging.getLogger(__name__)

CONFIG_DIR = Path.home() / ".config" / "work_guard"
DAY_TOKEN_RE = re.compile(r"^\s*(\d{1,2})([+*]?)\s*$")


@dataclass(frozen=True)
class DayInfo:
    is_workday: bool
    is_short_day: bool
    source: str


class ProductionCalendar:
    def __init__(self, config: dict):
        self._config = config
        self._year_cache: dict[int, dict] = {}

    def update_config(self, config: dict):
        self._config = config

    def classify_date(self, date_value: datetime.date) -> DayInfo:
        marker = self._get_marker_for_date(date_value)
        if marker == "+":
            return DayInfo(is_workday=True, is_short_day=False, source="calendar")
        if marker == "*":
            return DayInfo(is_workday=True, is_short_day=True, source="calendar")
        if marker == "":
            return DayInfo(is_workday=False, is_short_day=False, source="calendar")

        ps = self._config.get("current_period_settings", {})
        work_days = ps.get("work_days") or self._config.get("work_days", [1, 2, 3, 4, 5])
        return DayInfo(
            is_workday=date_value.isoweekday() in work_days,
            is_short_day=False,
            source="fallback",
        )

    def _get_marker_for_date(self, date_value: datetime.date) -> Optional[str]:
        if self._config.get("calendar_source", "xmlcalendar_ru") != "xmlcalendar_ru":
            return None

        data = self._load_year_data(date_value.year)
        if not data:
            return None
        day_map = self._build_day_map(data, date_value.year)
        return day_map.get(date_value.isoformat())

    def _load_year_data(self, year: int) -> Optional[dict]:
        if year in self._year_cache:
            return self._year_cache[year]

        cache_file = CONFIG_DIR / f"calendar_ru_{year}.json"
        cache_days = max(1, int(self._config.get("calendar_cache_days", 30) or 30))
        max_age = datetime.timedelta(days=cache_days)

        cached = self._read_json(cache_file)
        fresh_cache = False
        if cached and cache_file.exists():
            age = datetime.datetime.now() - datetime.datetime.fromtimestamp(
                cache_file.stat().st_mtime
            )
            fresh_cache = age <= max_age

        if fresh_cache:
            self._year_cache[year] = cached
            return cached

        fetched = self._fetch_year(year)
        if fetched:
            CONFIG_DIR.mkdir(parents=True, exist_ok=True)
            cache_file.write_text(
                json.dumps(fetched, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            self._year_cache[year] = fetched
            return fetched

        if cached:
            logger.warning("Using stale production calendar cache for year %s", year)
            self._year_cache[year] = cached
            return cached

        return None

    @staticmethod
    def _read_json(path: Path) -> Optional[dict]:
        if not path.is_file():
            return None
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            logger.warning("Failed to read calendar cache %s: %s", path, exc)
            return None

    @staticmethod
    def _fetch_year(year: int) -> Optional[dict]:
        url = f"https://xmlcalendar.ru/data/ru/{year}/calendar.json"
        try:
            with urlopen(url, timeout=10) as resp:
                payload = resp.read().decode("utf-8")
            data = json.loads(payload)
            if not isinstance(data, dict) or "months" not in data:
                raise ValueError("Invalid calendar payload shape")
            return data
        except (URLError, OSError, ValueError, json.JSONDecodeError) as exc:
            logger.warning("Failed to fetch production calendar for %s: %s", year, exc)
            return None

    @staticmethod
    def _build_day_map(data: dict, year: int) -> dict[str, str]:
        result: dict[str, str] = {}
        months = data.get("months")
        if not isinstance(months, list):
            return result

        for month_entry in months:
            if not isinstance(month_entry, dict):
                continue
            month = month_entry.get("month")
            days = month_entry.get("days")
            if not isinstance(month, int) or not isinstance(days, str):
                continue
            for token in days.split(","):
                match = DAY_TOKEN_RE.match(token)
                if not match:
                    continue
                day_num = int(match.group(1))
                marker = match.group(2)
                try:
                    date_key = datetime.date(year, month, day_num).isoformat()
                except ValueError:
                    continue
                result[date_key] = marker
        return result
