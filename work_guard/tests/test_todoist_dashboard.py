"""
Unit tests for the Todoist dashboard producer.
"""

import datetime
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import engagement_monitor
import todoist_signals
from engagement_monitor import TodoistEngagementMonitor
from todoist_signals import TodoistApiClient, _due_label


class _FixedDateTime(datetime.datetime):
    @classmethod
    def now(cls, tz=None):
        base = cls(2026, 6, 1, 10, 0, 0)
        if tz is not None:
            return base.replace(tzinfo=tz)
        return base


class TestTodoistDueLabel(unittest.TestCase):

    def setUp(self):
        self.now = datetime.datetime(2026, 6, 1, 10, 0, 0)

    def test_overdue_today_tomorrow_and_future_boundaries(self):
        cases = [
            (datetime.datetime(2026, 5, 29), False, "просрочено 3д"),
            (datetime.datetime(2026, 6, 1, 16, 45), True, "сегодня 16:45"),
            (datetime.datetime(2026, 6, 2, 9, 5), True, "завтра 09:05"),
            (datetime.datetime(2026, 6, 3), False, "Ср 3"),
            (datetime.datetime(2026, 6, 7), False, "Вс 7"),
            (datetime.datetime(2026, 6, 8), False, "8 июн"),
        ]
        for due_dt, has_time, expected in cases:
            with self.subTest(expected=expected):
                self.assertEqual(_due_label(due_dt, has_time, self.now), expected)


class TestTodoistDashboard(unittest.TestCase):

    def test_dashboard_shape_filtering_to_today_sorting_and_counts(self):
        tasks = [
            {
                "id": "today-p1",
                "content": "Today p1",
                "priority": 4,
                "due": {"datetime": "2026-06-01T16:45:00"},
            },
            {
                "id": "overdue-p1",
                "content": "Overdue p1",
                "priority": 4,
                "due": {"date": "2026-05-31"},
            },
            {
                "id": "undated-p1",
                "content": "Undated p1",
                "priority": 4,
                "due": None,
            },
            {
                "id": "tomorrow-p2",
                "content": "Tomorrow p2",
                "priority": 3,
                "due": {"date": "2026-06-02"},
            },
            {
                "id": "weekday-p3",
                "content": "Weekday p3",
                "priority": 2,
                "due": {"date": "2026-06-03"},
            },
            {
                "id": "future-p4",
                "content": "Future p4",
                "priority": 1,
                "due": {"date": "2026-06-08"},
            },
            {
                "id": "undated-default-p4",
                "content": "Undated default",
                "due": {},
            },
        ]

        with patch.object(todoist_signals.datetime, "datetime", _FixedDateTime):
            dashboard = TodoistApiClient.dashboard(tasks, cap=1)

        self.assertEqual(set(dashboard), {"columns", "counts"})
        self.assertEqual(set(dashboard["columns"]), {"p1", "p2", "p3", "p4"})
        self.assertEqual(set(dashboard["counts"]), {"p1", "p2", "p3", "p4"})

        self.assertEqual([t["content"] for t in dashboard["columns"]["p1"]],
                         ["Overdue p1", "Today p1"])
        self.assertEqual(dashboard["columns"]["p1"][0]["due_label"], "просрочено 1д")
        self.assertTrue(dashboard["columns"]["p1"][0]["overdue"])
        self.assertEqual(dashboard["columns"]["p1"][1]["due_label"], "сегодня 16:45")
        self.assertFalse(dashboard["columns"]["p1"][1]["overdue"])

        self.assertEqual(dashboard["columns"]["p2"], [])
        self.assertEqual(dashboard["columns"]["p3"], [])
        self.assertEqual(dashboard["columns"]["p4"], [])

        self.assertEqual(dashboard["counts"]["p1"],
                         {"dated": 2, "overdue": 1, "undated_hidden": 1})
        self.assertEqual(dashboard["counts"]["p2"],
                         {"dated": 0, "overdue": 0, "undated_hidden": 0})
        self.assertEqual(dashboard["counts"]["p3"],
                         {"dated": 0, "overdue": 0, "undated_hidden": 0})
        self.assertEqual(dashboard["counts"]["p4"],
                         {"dated": 0, "overdue": 0, "undated_hidden": 1})


class _FakeTodoistClient:
    def fetch_tasks(self, token):
        return [
            {
                "id": "fresh",
                "content": "Fresh task",
                "priority": 4,
                "due": {"date": "2026-06-01"},
                "updated_at": "2026-06-01T09:00:00",
            }
        ]

    def fetch_completed(self, token, since, until):
        return []

    def fetch_deleted_activity(self, token, since):
        return []

    def dashboard(self, tasks, cap):
        return TodoistApiClient.dashboard(tasks, cap)

    def snapshot_sig(self, tasks):
        return TodoistApiClient.snapshot_sig(tasks)

    def recent_api_change_time(self, *args, **kwargs):
        return None


class TestTodoistDashboardRestore(unittest.TestCase):

    def test_old_shape_restore_is_discarded_then_repopulated(self):
        with tempfile.TemporaryDirectory() as tmp:
            state_path = Path(tmp) / "todoist_state.json"
            state_path.write_text(json.dumps({
                "last_engagement": "2026-06-01T09:00:00",
                "snapshot_tasks": [],
                "dashboard": {"p1p2": [], "p3_count": 1},
            }), encoding="utf-8")

            with (
                patch.object(engagement_monitor, "STATE_PATH", state_path),
                patch.object(engagement_monitor, "read_todoist_token",
                             return_value="token"),
                patch.object(todoist_signals.datetime, "datetime",
                             _FixedDateTime),
            ):
                monitor = TodoistEngagementMonitor({
                    "todoist_reminder": {
                        "enabled": True,
                        "idle_threshold_min": 120,
                        "poll_interval_min": 5,
                        "task_list_cap": 1,
                    }
                })
                self.assertIsNone(monitor.dashboard())

                monitor._client = _FakeTodoistClient()
                monitor._do_poll(_FixedDateTime.now())

                dashboard = monitor.dashboard()
                self.assertIn("columns", dashboard)
                saved = json.loads(state_path.read_text(encoding="utf-8"))
                self.assertIn("columns", saved["dashboard"])


if __name__ == "__main__":
    unittest.main()
