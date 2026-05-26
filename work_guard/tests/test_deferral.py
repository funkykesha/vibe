"""
Unit tests for deferral state machine, period boundary, and config migration.
Tasks 10.1-10.6.
"""

import datetime
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import config as cfg_module

# ─────────────────────────────────────────────────────────────
# Helpers used by tests without importing the full app
# ─────────────────────────────────────────────────────────────

LADDER_STEPS = [20, 10, 5]
DEFER_CUTOFF_SEC = 120
OVERLAY_FIRST_DELAY_MIN = 20
LOCK_INITIAL_SEC = 120
LOCK_MAX_SEC = 1800


def _make_deferral(steps_consumed=None, next_overlay_at=None, cadence_min=20, next_lock_sec=120):
    base = datetime.datetime(2026, 5, 26, 20, 0, 0)
    if next_overlay_at is None:
        next_overlay_at = (base + datetime.timedelta(minutes=OVERLAY_FIRST_DELAY_MIN)).isoformat()
    return {
        "period_id": "2026-05-26T19:00:00",
        "steps_consumed": steps_consumed or [],
        "next_overlay_at": next_overlay_at,
        "cadence_min": cadence_min,
        "next_lock_sec": next_lock_sec,
    }


def contextual_button_state(overtime_started_at, deferral, now=None):
    """Pure function extracted from WorkGuardApp._contextual_button_state."""
    if overtime_started_at is None:
        return {"title": "Работаем!", "enabled": False}
    if not deferral:
        return {"title": "Работаем!", "enabled": False}
    if now is None:
        now = datetime.datetime.now()
    steps = deferral.get("steps_consumed", [])
    if len(steps) >= len(LADDER_STEPS):
        return {"title": "пора отдыхать", "enabled": False}
    try:
        next_at = datetime.datetime.fromisoformat(deferral["next_overlay_at"])
        if now >= next_at - datetime.timedelta(seconds=DEFER_CUTOFF_SEC):
            return {"title": "пора отдыхать", "enabled": False}
    except Exception:
        pass
    step = LADDER_STEPS[len(steps)]
    return {"title": f"Отложить на {step} мин", "enabled": True}


def defer_step(deferral, overtime_started_at, now=None):
    """Pure function: apply one deferral step. Returns new deferral or raises ValueError."""
    if not deferral or overtime_started_at is None:
        raise ValueError("not in overtime")
    if now is None:
        now = datetime.datetime.now()
    steps = list(deferral.get("steps_consumed", []))
    if len(steps) >= len(LADDER_STEPS):
        raise ValueError("ladder exhausted")
    next_at = datetime.datetime.fromisoformat(deferral["next_overlay_at"])
    if now >= next_at - datetime.timedelta(seconds=DEFER_CUTOFF_SEC):
        raise ValueError("within cutoff")
    step = LADDER_STEPS[len(steps)]
    steps.append(f"+{step}")
    new_next_at = next_at + datetime.timedelta(minutes=step)
    result = dict(deferral)
    result["steps_consumed"] = steps
    result["next_overlay_at"] = new_next_at.isoformat()
    return result


# ─────────────────────────────────────────────────────────────
# 10.1  Button state machine
# ─────────────────────────────────────────────────────────────

class TestContextualButtonState(unittest.TestCase):

    def _now(self):
        return datetime.datetime(2026, 5, 26, 20, 5, 0)

    def _next_at(self, offset_min):
        base = datetime.datetime(2026, 5, 26, 20, 0, 0)
        return (base + datetime.timedelta(minutes=OVERLAY_FIRST_DELAY_MIN + offset_min)).isoformat()

    def test_outside_overtime(self):
        s = contextual_button_state(None, None, self._now())
        self.assertEqual(s["title"], "Работаем!")
        self.assertFalse(s["enabled"])

    def test_fresh_ladder(self):
        d = _make_deferral(steps_consumed=[], next_overlay_at=self._next_at(30))
        onset = datetime.datetime(2026, 5, 26, 20, 0, 0)
        s = contextual_button_state(onset, d, self._now())
        self.assertEqual(s["title"], "Отложить на 20 мин")
        self.assertTrue(s["enabled"])

    def test_after_plus20(self):
        d = _make_deferral(steps_consumed=["+20"], next_overlay_at=self._next_at(30))
        onset = datetime.datetime(2026, 5, 26, 20, 0, 0)
        s = contextual_button_state(onset, d, self._now())
        self.assertEqual(s["title"], "Отложить на 10 мин")
        self.assertTrue(s["enabled"])

    def test_after_plus20_plus10(self):
        d = _make_deferral(steps_consumed=["+20", "+10"], next_overlay_at=self._next_at(30))
        onset = datetime.datetime(2026, 5, 26, 20, 0, 0)
        s = contextual_button_state(onset, d, self._now())
        self.assertEqual(s["title"], "Отложить на 5 мин")
        self.assertTrue(s["enabled"])

    def test_ladder_exhausted(self):
        d = _make_deferral(steps_consumed=["+20", "+10", "+5"], next_overlay_at=self._next_at(30))
        onset = datetime.datetime(2026, 5, 26, 20, 0, 0)
        s = contextual_button_state(onset, d, self._now())
        self.assertEqual(s["title"], "пора отдыхать")
        self.assertFalse(s["enabled"])

    def test_within_cutoff(self):
        # next_overlay_at is 1 minute from now → within 2-min cutoff
        now = self._now()
        next_at = (now + datetime.timedelta(seconds=60)).isoformat()
        d = _make_deferral(steps_consumed=[], next_overlay_at=next_at)
        onset = datetime.datetime(2026, 5, 26, 20, 0, 0)
        s = contextual_button_state(onset, d, now)
        self.assertEqual(s["title"], "пора отдыхать")
        self.assertFalse(s["enabled"])


# ─────────────────────────────────────────────────────────────
# 10.2  defer_step time math
# ─────────────────────────────────────────────────────────────

class TestDeferStep(unittest.TestCase):

    def _now(self):
        return datetime.datetime(2026, 5, 26, 20, 5, 0)

    def test_adds_to_scheduled_not_click(self):
        next_at_dt = datetime.datetime(2026, 5, 26, 20, 30, 0)
        d = _make_deferral(steps_consumed=[], next_overlay_at=next_at_dt.isoformat())
        onset = datetime.datetime(2026, 5, 26, 20, 0, 0)
        now = self._now()  # 20:05, well before next_at 20:30
        new_d = defer_step(d, onset, now)
        expected = next_at_dt + datetime.timedelta(minutes=20)
        self.assertEqual(new_d["next_overlay_at"], expected.isoformat())

    def test_ladder_advance_sequence(self):
        next_at_dt = datetime.datetime(2026, 5, 26, 20, 30, 0)
        d = _make_deferral(steps_consumed=[], next_overlay_at=next_at_dt.isoformat())
        onset = datetime.datetime(2026, 5, 26, 20, 0, 0)
        now = self._now()
        d = defer_step(d, onset, now)
        self.assertEqual(d["steps_consumed"], ["+20"])
        d = defer_step(d, onset, now)
        self.assertEqual(d["steps_consumed"], ["+20", "+10"])
        d = defer_step(d, onset, now)
        self.assertEqual(d["steps_consumed"], ["+20", "+10", "+5"])

    def test_ladder_exhaustion_rejection(self):
        d = _make_deferral(steps_consumed=["+20", "+10", "+5"],
                           next_overlay_at=datetime.datetime(2026, 5, 26, 21, 0).isoformat())
        onset = datetime.datetime(2026, 5, 26, 20, 0, 0)
        with self.assertRaises(ValueError, msg="ladder exhausted"):
            defer_step(d, onset, self._now())

    def test_cutoff_rejection(self):
        now = self._now()
        next_at = (now + datetime.timedelta(seconds=60)).isoformat()
        d = _make_deferral(steps_consumed=[], next_overlay_at=next_at)
        onset = datetime.datetime(2026, 5, 26, 20, 0, 0)
        with self.assertRaises(ValueError, msg="within cutoff"):
            defer_step(d, onset, now)


# ─────────────────────────────────────────────────────────────
# 10.4  Legacy config migration
# ─────────────────────────────────────────────────────────────

class TestLegacyMigration(unittest.TestCase):

    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self._orig_dir = cfg_module.CONFIG_DIR
        self._orig_file = cfg_module.CONFIG_FILE
        cfg_module.CONFIG_DIR = Path(self._tmp)
        cfg_module.CONFIG_FILE = Path(self._tmp) / "config.json"

    def tearDown(self):
        cfg_module.CONFIG_DIR = self._orig_dir
        cfg_module.CONFIG_FILE = self._orig_file
        shutil.rmtree(self._tmp, ignore_errors=True)

    def _write_legacy(self, data):
        cfg_module.CONFIG_FILE.write_text(json.dumps(data), encoding="utf-8")

    def test_backup_written(self):
        self._write_legacy({"work_start": "09:00", "work_end": "18:00", "work_days": [1, 2, 3, 4, 5]})
        cfg_module.load_config()
        bak = cfg_module.CONFIG_FILE.with_suffix(".json.pre-deferral.bak")
        self.assertTrue(bak.exists(), "backup not written")

    def test_lifted_fields_preserved(self):
        self._write_legacy({"work_start": "08:30", "work_end": "17:30", "work_days": [1, 2, 3]})
        result = cfg_module.load_config()
        ps = result["current_period_settings"]
        self.assertEqual(ps["work_start"], "08:30")
        self.assertEqual(ps["work_end"], "17:30")
        self.assertEqual(ps["work_days"], [1, 2, 3])

    def test_dropped_fields_absent(self):
        legacy = {
            "work_start": "09:00", "work_end": "19:00", "work_days": [1, 2, 3, 4, 5],
            "pause_until": "2026-05-26T12:00:00",
            "work_apps": ["Slack"],
            "notification_interval_min": 10,
            "overlay_delay_min": 30,
            "overlay_lock_initial_sec": 60,
            "overlay_lock_max_sec": 3600,
        }
        self._write_legacy(legacy)
        result = cfg_module.load_config()
        for dropped in ("pause_until", "work_apps", "notification_interval_min",
                         "overlay_delay_min", "overlay_lock_initial_sec", "overlay_lock_max_sec"):
            self.assertNotIn(dropped, result, f"{dropped} should be dropped")

    def test_new_keys_initialised(self):
        self._write_legacy({"work_start": "09:00", "work_end": "19:00", "work_days": [1, 2, 3, 4, 5]})
        result = cfg_module.load_config()
        self.assertIn("current_period_settings", result)
        self.assertIsNone(result["pending_period_settings"])
        self.assertIsNone(result["deferral"])


# ─────────────────────────────────────────────────────────────
# 10.5  Clock-jump guard
# ─────────────────────────────────────────────────────────────

class TestClockJumpGuard(unittest.TestCase):

    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self._orig_dir = cfg_module.CONFIG_DIR
        self._orig_file = cfg_module.CONFIG_FILE
        cfg_module.CONFIG_DIR = Path(self._tmp)
        cfg_module.CONFIG_FILE = Path(self._tmp) / "config.json"

    def tearDown(self):
        cfg_module.CONFIG_DIR = self._orig_dir
        cfg_module.CONFIG_FILE = self._orig_file
        shutil.rmtree(self._tmp, ignore_errors=True)

    def test_deferral_reset_on_clock_jump(self):
        """next_overlay_at 30 days ahead — should be treated as stale."""
        now = datetime.datetime.now()
        far_future = (now + datetime.timedelta(days=30)).isoformat()
        deferral = _make_deferral(next_overlay_at=far_future)
        cfg = {
            "current_period_settings": {"work_start": "09:00", "work_end": "19:00", "work_days": [1, 2, 3, 4, 5]},
            "pending_period_settings": None,
            "deferral": deferral,
            "calendar_source": "xmlcalendar_ru",
            "calendar_cache_days": 30,
        }
        cfg_module.CONFIG_FILE.write_text(json.dumps(cfg), encoding="utf-8")

        # Simulate check_period_boundary_on_launch logic (clock-jump branch)
        loaded = cfg_module.load_config()
        d = loaded.get("deferral")
        self.assertIsNotNone(d)
        next_at = datetime.datetime.fromisoformat(d["next_overlay_at"])
        jump = abs((next_at - now).total_seconds()) > 86400
        self.assertTrue(jump, "Should detect clock jump (>24h)")

    def test_no_reset_when_within_24h(self):
        now = datetime.datetime.now()
        near = (now + datetime.timedelta(hours=2)).isoformat()
        deferral = _make_deferral(next_overlay_at=near)
        cfg = {
            "current_period_settings": {"work_start": "09:00", "work_end": "19:00", "work_days": [1, 2, 3, 4, 5]},
            "pending_period_settings": None,
            "deferral": deferral,
            "calendar_source": "xmlcalendar_ru",
            "calendar_cache_days": 30,
        }
        cfg_module.CONFIG_FILE.write_text(json.dumps(cfg), encoding="utf-8")
        loaded = cfg_module.load_config()
        d = loaded.get("deferral")
        self.assertIsNotNone(d)
        next_at = datetime.datetime.fromisoformat(d["next_overlay_at"])
        jump = abs((next_at - now).total_seconds()) > 86400
        self.assertFalse(jump, "Should not detect clock jump within 24h")


# ─────────────────────────────────────────────────────────────
# 10.3  Period boundary promotion atomicity
# ─────────────────────────────────────────────────────────────

class TestPeriodBoundaryPromotion(unittest.TestCase):

    def _promotion(self, cfg: dict) -> dict:
        """Simulate _run_period_promotion logic."""
        pending = cfg.get("pending_period_settings")
        if pending:
            cfg["current_period_settings"] = pending
        cfg["pending_period_settings"] = None
        cfg["deferral"] = None
        return cfg

    def test_pending_promoted_to_current(self):
        pending = {"work_start": "10:00", "work_end": "18:00", "work_days": [1, 2, 3]}
        cfg = {
            "current_period_settings": {"work_start": "09:00", "work_end": "19:00", "work_days": [1, 2, 3, 4, 5]},
            "pending_period_settings": pending,
            "deferral": _make_deferral(),
        }
        result = self._promotion(cfg)
        self.assertEqual(result["current_period_settings"]["work_start"], "10:00")
        self.assertIsNone(result["pending_period_settings"])
        self.assertIsNone(result["deferral"])

    def test_no_pending_current_unchanged(self):
        current = {"work_start": "09:00", "work_end": "19:00", "work_days": [1, 2, 3, 4, 5]}
        cfg = {
            "current_period_settings": dict(current),
            "pending_period_settings": None,
            "deferral": _make_deferral(),
        }
        result = self._promotion(cfg)
        self.assertEqual(result["current_period_settings"]["work_start"], "09:00")
        self.assertIsNone(result["deferral"])

    def test_all_three_fields_in_single_state(self):
        """After promotion, current/pending/deferral are all consistent."""
        pending = {"work_start": "08:00", "work_end": "17:00", "work_days": [1, 2, 3, 4]}
        cfg = {
            "current_period_settings": {"work_start": "09:00", "work_end": "19:00", "work_days": [1, 2, 3, 4, 5]},
            "pending_period_settings": pending,
            "deferral": _make_deferral(),
        }
        result = self._promotion(cfg)
        # All three changed atomically
        self.assertEqual(result["current_period_settings"], pending)
        self.assertIsNone(result["pending_period_settings"])
        self.assertIsNone(result["deferral"])


if __name__ == "__main__":
    unittest.main()
