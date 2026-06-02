"""
Unit tests for TodoistEngagementMonitor.

Covers:
  - no-token scenario: no engagement advance, no poll spawn, no crash
  - active_app ignored (frontmost-app signal removed)
  - BrowserHistoryReader not constructed
  - token removal via update_config
  - only API can advance last_engagement
"""

import datetime
import sys
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from engagement_monitor import TodoistEngagementMonitor

NOW = datetime.datetime(2026, 6, 1, 10, 0, 0)


def _cfg(enabled=True, poll_interval_min=5, idle_threshold_min=120):
    return {
        "todoist_reminder": {
            "enabled": enabled,
            "poll_interval_min": poll_interval_min,
            "idle_threshold_min": idle_threshold_min,
        }
    }


def _make_monitor(token=None, enabled=True):
    with patch("engagement_monitor.read_todoist_token", return_value=token), \
         patch("engagement_monitor.STATE_PATH") as mock_path:
        mock_path.is_file.return_value = False
        monitor = TodoistEngagementMonitor(_cfg(enabled=enabled))
    return monitor


class TestNoToken(unittest.TestCase):

    def test_api_enabled_false_without_token(self):
        m = _make_monitor(token=None)
        self.assertFalse(m.api_enabled())

    def test_is_enabled_true_without_token(self):
        m = _make_monitor(token=None, enabled=True)
        self.assertTrue(m.is_enabled())

    def test_update_no_token_does_not_spawn_poll(self):
        m = _make_monitor(token=None)
        with patch.object(m, "_spawn_poll") as mock_spawn:
            m.update("Todoist", NOW)
        mock_spawn.assert_not_called()

    def test_update_no_token_last_engagement_stays_none(self):
        m = _make_monitor(token=None)
        m.update("Todoist", NOW)
        self.assertIsNone(m.last_engagement())

    def test_update_no_token_minutes_since_returns_none(self):
        m = _make_monitor(token=None)
        m.update("Todoist", NOW)
        self.assertIsNone(m.minutes_since(NOW))

    def test_update_no_crash_various_active_app_values(self):
        m = _make_monitor(token=None)
        for app in ("Todoist", None, "", "Safari", "Yandex Browser"):
            with self.subTest(active_app=app):
                m.update(app, NOW)

    def test_no_browser_history_reader_on_monitor(self):
        m = _make_monitor(token=None)
        self.assertFalse(hasattr(m, "_reader"))

    def test_feature_disabled_update_is_noop(self):
        m = _make_monitor(token=None, enabled=False)
        with patch.object(m, "_spawn_poll") as mock_spawn:
            m.update("Todoist", NOW)
        mock_spawn.assert_not_called()
        self.assertIsNone(m.last_engagement())


class TestTokenPresent(unittest.TestCase):

    def test_api_enabled_true_with_token(self):
        m = _make_monitor(token="tok_abc")
        self.assertTrue(m.api_enabled())

    def test_update_with_token_spawns_poll_when_due(self):
        m = _make_monitor(token="tok_abc")
        with patch.object(m, "_spawn_poll") as mock_spawn:
            m.update("Todoist", NOW)
        mock_spawn.assert_called_once_with(NOW)

    def test_active_app_does_not_advance_engagement(self):
        """Frontmost-app signal removed: active_app='Todoist' must not bump last_engagement."""
        m = _make_monitor(token="tok_abc")
        with patch.object(m, "_spawn_poll"):
            m.update("Todoist", NOW)
        self.assertIsNone(m.last_engagement())

    def test_active_app_none_does_not_advance_engagement(self):
        m = _make_monitor(token="tok_abc")
        with patch.object(m, "_spawn_poll"):
            m.update(None, NOW)
        self.assertIsNone(m.last_engagement())


class TestUpdateConfig(unittest.TestCase):

    def test_token_removal_disables_api(self):
        m = _make_monitor(token="tok_abc")
        self.assertTrue(m.api_enabled())
        with patch("engagement_monitor.read_todoist_token", return_value=None):
            m.update_config(_cfg())
        self.assertFalse(m.api_enabled())

    def test_token_added_enables_api(self):
        m = _make_monitor(token=None)
        self.assertFalse(m.api_enabled())
        with patch("engagement_monitor.read_todoist_token", return_value="tok_new"):
            m.update_config(_cfg())
        self.assertTrue(m.api_enabled())

    def test_update_config_no_reader_update(self):
        """update_config must not reference _reader (removed)."""
        m = _make_monitor(token=None)
        with patch("engagement_monitor.read_todoist_token", return_value=None):
            m.update_config(_cfg())
        self.assertFalse(hasattr(m, "_reader"))


class TestApiEngagementSignal(unittest.TestCase):

    def test_mark_engagement_now_advances_last_engagement(self):
        m = _make_monitor(token="tok_abc")
        m.mark_engagement_now(NOW)
        self.assertEqual(m.last_engagement(), NOW)

    def test_mark_engagement_now_does_not_regress(self):
        m = _make_monitor(token="tok_abc")
        later = NOW + datetime.timedelta(minutes=10)
        m.mark_engagement_now(later)
        m.mark_engagement_now(NOW)
        self.assertEqual(m.last_engagement(), later)

    def test_minutes_since_after_engagement(self):
        m = _make_monitor(token="tok_abc")
        m.mark_engagement_now(NOW)
        check = NOW + datetime.timedelta(minutes=30)
        self.assertAlmostEqual(m.minutes_since(check), 30.0, places=1)


if __name__ == "__main__":
    unittest.main()
