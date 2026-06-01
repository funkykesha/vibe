"""
Todoist engagement aggregator.

Folds three local signals into one recency timestamp `last_engagement`:
  - frontmost app == Todoist (active PWA / app viewing — primary signal);
  - last todoist.com visit from Chromium history (regular tabs);
  - Todoist API changes from other devices (snapshot-diff + completed + deleted).

The API poll runs in a non-blocking background thread; the main monitoring tick
only reads cached state. Shared state is guarded by a single lock with atomic
swaps. State persists to `~/.config/work_guard/todoist_state.json` so
`last_engagement`, the last successful task snapshot and dashboard survive a
restart within the day.
"""

import datetime
import json
import logging
import os
import threading
from pathlib import Path
from typing import Optional

from config import read_todoist_token
from todoist_signals import BrowserHistoryReader, TodoistApiClient

logger = logging.getLogger(__name__)

STATE_PATH = Path.home() / ".config" / "work_guard" / "todoist_state.json"


class TodoistEngagementMonitor:
    """Aggregates Todoist signals into a single `last_engagement` timestamp."""

    def __init__(self, config: dict):
        self._cfg = config.get("todoist_reminder", {}) if config else {}
        self._token = read_todoist_token()
        self._reader = BrowserHistoryReader(self._cfg.get("history_browsers"))
        self._client = TodoistApiClient()

        self._lock = threading.Lock()
        self._last_engagement: Optional[datetime.datetime] = None
        self._snapshot_tasks: Optional[list] = None  # last successful active tasks
        self._dashboard: Optional[dict] = None
        self._prev_sig: Optional[dict] = None
        self._prev_tasks_by_id: Optional[dict] = None

        self._last_poll_at: Optional[datetime.datetime] = None
        self._poll_in_flight = False

        self._load_state()

    # -- 3.1 config / capabilities ----------------------------------------

    def update_config(self, config: dict) -> None:
        self._cfg = config.get("todoist_reminder", {}) if config else {}
        self._reader.update_browsers(self._cfg.get("history_browsers", []))
        # Token may be added/removed without restart.
        self._token = read_todoist_token()

    def is_enabled(self) -> bool:
        return bool(self._cfg.get("enabled", False))

    def api_enabled(self) -> bool:
        return bool(self._token)

    # -- 3.2 update -------------------------------------------------------

    def update(self, active_app: Optional[str], now: datetime.datetime) -> None:
        """Refresh signals. Front-app + history run inline; API poll spawns a thread."""
        if not self.is_enabled():
            return

        # 3.2a: app signal only when Todoist is frontmost (not background-running).
        frontmost = self._cfg.get("frontmost_app_name", "Todoist")
        if active_app and active_app == frontmost:
            self._bump_engagement(now)

        # Browser history (throttled inside the reader).
        visit = self._reader.last_visit(now)
        if visit is not None:
            self._bump_engagement(visit)

        # API poll — non-blocking background thread, throttled by poll_interval.
        if self.api_enabled() and self._poll_due(now):
            self._spawn_poll(now)

    def _poll_due(self, now: datetime.datetime) -> bool:
        with self._lock:
            if self._poll_in_flight:
                return False
            interval = int(self._cfg.get("poll_interval_min", 5)) * 60
            if self._last_poll_at is None:
                return True
            return (now - self._last_poll_at).total_seconds() >= interval

    def _spawn_poll(self, now: datetime.datetime) -> None:
        with self._lock:
            if self._poll_in_flight:
                return
            self._poll_in_flight = True
            self._last_poll_at = now
        threading.Thread(target=self._poll_worker, args=(now,), daemon=True).start()

    def _poll_worker(self, now: datetime.datetime) -> None:
        try:
            self._do_poll(now)
        except Exception as e:  # never let a poll crash the thread silently
            logger.exception("Todoist poll failed: %s", e)
        finally:
            with self._lock:
                self._poll_in_flight = False

    def _do_poll(self, now: datetime.datetime) -> None:
        token = self._token
        if not token:
            return
        tasks = self._client.fetch_tasks(token)
        if tasks is None:
            logger.debug("Todoist poll: fetch_tasks returned None; keeping last snapshot")
            return  # error → keep last successful snapshot, no engagement change

        lookback_min = (
            int(self._cfg.get("idle_threshold_min", 120))
            + int(self._cfg.get("poll_interval_min", 5))
            + 5
        )
        since = now - datetime.timedelta(minutes=lookback_min)
        completed = self._client.fetch_completed(token, since, now)
        deleted = self._client.fetch_deleted_activity(token, since)

        cur_sig = self._client.snapshot_sig(tasks)
        cur_by_id = {str(t.get("id")): t for t in tasks if t.get("id") is not None}
        dashboard = self._client.dashboard(tasks, int(self._cfg.get("task_list_cap", 10)))

        with self._lock:
            prev_sig = self._prev_sig
            prev_by_id = self._prev_tasks_by_id

        # ids touched by completed/deleted → exempt from recurring-due guard.
        recently_changed = set()
        for c in completed or []:
            if c.get("id") is not None:
                recently_changed.add(str(c.get("id")))
        for ev in deleted or []:
            oid = ev.get("object_id") or ev.get("id")
            if oid is not None:
                recently_changed.add(str(oid))

        # 3.3 cold start: first snapshot is the baseline, NOT an interaction at now.
        change_time = None
        if prev_sig is not None:
            change_time = self._client.recent_api_change_time(
                prev_sig, cur_sig, prev_by_id, cur_by_id,
                completed, deleted, recently_changed,
            )

        with self._lock:
            self._snapshot_tasks = tasks
            self._dashboard = dashboard
            self._prev_sig = cur_sig
            self._prev_tasks_by_id = cur_by_id
            if change_time is not None and (
                self._last_engagement is None or change_time > self._last_engagement
            ):
                self._last_engagement = change_time
        self._save_state()

    # -- helpers ----------------------------------------------------------

    def _bump_engagement(self, when: datetime.datetime) -> None:
        with self._lock:
            if self._last_engagement is None or when > self._last_engagement:
                self._last_engagement = when
                changed = True
            else:
                changed = False
        if changed:
            self._save_state()

    def mark_engagement_now(self, now: datetime.datetime) -> None:
        """Force an immediate engagement (e.g. user pressed 'open Todoist')."""
        self._bump_engagement(now)

    # -- 3.5 queries ------------------------------------------------------

    def last_engagement(self) -> Optional[datetime.datetime]:
        with self._lock:
            return self._last_engagement

    def minutes_since(self, now: datetime.datetime) -> Optional[float]:
        with self._lock:
            le = self._last_engagement
        if le is None:
            return None
        return (now - le).total_seconds() / 60.0

    def dashboard(self) -> Optional[dict]:
        with self._lock:
            return dict(self._dashboard) if self._dashboard else None

    # -- 3.4 persistence --------------------------------------------------

    def _save_state(self) -> None:
        with self._lock:
            le = self._last_engagement
            tasks = self._snapshot_tasks
            dash = self._dashboard
        data = {
            "last_engagement": le.isoformat() if le else None,
            "snapshot_tasks": tasks,
            "dashboard": dash,
        }
        try:
            STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
            tmp = STATE_PATH.with_suffix(".json.tmp")
            tmp.write_text(
                json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8"
            )
            os.replace(tmp, STATE_PATH)
        except OSError as e:
            logger.warning("todoist_state save failed: %s", e)

    def _load_state(self) -> None:
        if not STATE_PATH.is_file():
            return
        try:
            data = json.loads(STATE_PATH.read_text(encoding="utf-8"))
        except (OSError, ValueError) as e:
            logger.warning("todoist_state load failed: %s", e)
            return
        le = data.get("last_engagement")
        tasks = data.get("snapshot_tasks")
        dash = data.get("dashboard")
        with self._lock:
            if le:
                try:
                    self._last_engagement = datetime.datetime.fromisoformat(le)
                except ValueError:
                    self._last_engagement = None
            if isinstance(tasks, list):
                self._snapshot_tasks = tasks
                self._prev_sig = self._client.snapshot_sig(tasks)
                self._prev_tasks_by_id = {
                    str(t.get("id")): t for t in tasks if t.get("id") is not None
                }
            # D7: discard a pre-redesign snapshot lacking the new `columns`
            # shape; first post-upgrade refresh repopulates it.
            if isinstance(dash, dict) and "columns" in dash:
                self._dashboard = dash
