#!/usr/bin/env python3
import datetime
import json
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
import production_calendar as pc


def _assert(condition: bool, message: str):
    if not condition:
        raise AssertionError(message)


def main():
    with tempfile.TemporaryDirectory() as tmp_dir:
        tmp_path = Path(tmp_dir)
        pc.CONFIG_DIR = tmp_path

        cfg = {
            "calendar_source": "xmlcalendar_ru",
            "calendar_cache_days": 30,
            "work_days": [1, 2, 3, 4, 5],
        }
        cal = pc.ProductionCalendar(cfg)

        # Cache fixture:
        # 2026-01-01 holiday (no suffix)
        # 2026-01-02 shortened day (*)
        # 2026-01-03 transferred workday (+)
        fixture = {
            "year": 2026,
            "months": [
                {
                    "month": 1,
                    "days": "1,2*,3+",
                }
            ],
        }
        cache_file = tmp_path / "calendar_ru_2026.json"
        cache_file.write_text(
            json.dumps(fixture, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

        holiday = cal.classify_date(datetime.date(2026, 1, 1))
        _assert(not holiday.is_workday, "holiday should be non-working")

        short = cal.classify_date(datetime.date(2026, 1, 2))
        _assert(short.is_workday, "shortened day should be working")
        _assert(short.is_short_day, "shortened day should be flagged short")

        transferred = cal.classify_date(datetime.date(2026, 1, 3))
        _assert(transferred.is_workday, "transferred workday should be working")
        _assert(not transferred.is_short_day, "transferred workday should not be short")

        # Fallback check for missing date marker: 2026-01-05 is Monday
        fallback = cal.classify_date(datetime.date(2026, 1, 5))
        _assert(fallback.is_workday, "missing marker should fallback to weekday config")
        _assert(fallback.source == "fallback", "missing marker should report fallback source")

        # Cache check: disable network source via monkeypatch to ensure cache still works.
        original_fetch = pc.ProductionCalendar._fetch_year
        pc.ProductionCalendar._fetch_year = staticmethod(lambda year: None)
        try:
            again = cal.classify_date(datetime.date(2026, 1, 2))
            _assert(again.is_short_day, "cached shortened day should remain available")
        finally:
            pc.ProductionCalendar._fetch_year = original_fetch

    print("verify_production_calendar: OK")


if __name__ == "__main__":
    main()
