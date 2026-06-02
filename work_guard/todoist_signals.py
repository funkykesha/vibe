"""
Todoist REST API engagement signal.

Single collector: TodoistApiClient — active tasks snapshot + completed/deleted
recency via the Todoist REST API v1. Used to detect user-visible task changes
and to render the reminder mini-dashboard.

All errors degrade to None — a missing signal is NOT a Todoist Interaction and
never suppresses the reminder by itself.
"""

import datetime
import hashlib
import json
import logging
import urllib.error
import urllib.parse
import urllib.request
from typing import Optional

logger = logging.getLogger(__name__)

_API_BASE = "https://api.todoist.com"
_API_TIMEOUT = 30


def _parse_iso(value: Optional[str]) -> Optional[datetime.datetime]:
    """Parse a Todoist ISO timestamp into a naive local datetime."""
    if not value:
        return None
    try:
        s = value.replace("Z", "+00:00")
        dt = datetime.datetime.fromisoformat(s)
    except (ValueError, TypeError):
        return None
    if dt.tzinfo is not None:
        dt = dt.astimezone().replace(tzinfo=None)
    return dt


# Russian short weekday / month tables for relative due labels (design D2).
_RU_WEEKDAY_SHORT = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
_RU_MONTH_SHORT = [
    "янв", "фев", "мар", "апр", "май", "июн",
    "июл", "авг", "сен", "окт", "ноя", "дек",
]


def _due_label(due_dt: datetime.datetime, has_time: bool,
               now: datetime.datetime) -> str:
    """Relative russian due label (design D2). `HH:MM` only today/tomorrow."""
    today = now.date()
    d = due_dt.date()
    delta = (d - today).days
    time_suffix = f" {due_dt.strftime('%H:%M')}" if has_time else ""
    if delta < 0:
        # D2: uniform "просрочено Nд" (N≥1); no "вчера" / "N дней назад" aliases.
        return f"просрочено {-delta}д"
    if delta == 0:
        return f"сегодня{time_suffix}"
    if delta == 1:
        return f"завтра{time_suffix}"
    if delta <= 6:
        return f"{_RU_WEEKDAY_SHORT[d.weekday()]} {d.day}"
    return f"{d.day} {_RU_MONTH_SHORT[d.month - 1]}"


class TodoistApiClient:
    """Thin Todoist REST API v1 client (stdlib urllib only)."""

    def __init__(self, timeout: int = _API_TIMEOUT):
        self._timeout = timeout

    # -- HTTP -------------------------------------------------------------

    def _get(self, token: str, path: str, params: dict) -> Optional[dict]:
        url = f"{_API_BASE}{path}"
        if params:
            url = f"{url}?{urllib.parse.urlencode(params)}"
        req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
        try:
            with urllib.request.urlopen(req, timeout=self._timeout) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except (urllib.error.URLError, TimeoutError, ValueError, OSError) as e:
            logger.warning("Todoist API GET %s failed: %s", path, e)
            return None

    @staticmethod
    def _items(payload: dict) -> list:
        """Extract the result list from a v1 paginated payload."""
        if isinstance(payload, list):
            return payload
        for key in ("results", "items", "data"):
            val = payload.get(key)
            if isinstance(val, list):
                return val
        return []

    def _paginate(self, token: str, path: str, params: dict, max_pages: int = 50) -> Optional[list]:
        """Walk all pages via `next_cursor`. Returns None if the first page fails."""
        out: list = []
        cursor = None
        for _ in range(max_pages):
            page_params = dict(params)
            if cursor:
                page_params["cursor"] = cursor
            payload = self._get(token, path, page_params)
            if payload is None:
                return None if not out else out
            out.extend(self._items(payload))
            cursor = payload.get("next_cursor") if isinstance(payload, dict) else None
            if not cursor:
                break
        return out

    # -- 2.2 active tasks -------------------------------------------------

    def fetch_tasks(self, token: str) -> Optional[list]:
        """All active tasks (cursor-paginated)."""
        return self._paginate(token, "/api/v1/tasks", {"limit": 200})

    # -- 2.3 completed ----------------------------------------------------

    def fetch_completed(self, token: str, since: datetime.datetime,
                        until: datetime.datetime) -> Optional[list]:
        """Tasks completed in [since, until]. Both bounds are required by v1."""
        params = {
            "since": _to_api_iso(since),
            "until": _to_api_iso(until),
            "limit": 200,
        }
        return self._paginate(
            token, "/api/v1/tasks/completed/by_completion_date", params
        )

    # -- 2.4 deleted activity ---------------------------------------------

    def fetch_deleted_activity(self, token: str, since: datetime.datetime,
                               max_pages: int = 20) -> Optional[list]:
        """Deleted item events with event_date >= since.

        v1 `/api/v1/activities` has no `since` param — paginate by cursor and
        filter client-side, stopping once events fall before `since`.
        Note: v1 item activity logs only added/updated/deleted/completed/
        uncompleted; move/reorder/priority do NOT appear here.
        """
        out: list = []
        cursor = None
        got_any = False
        for _ in range(max_pages):
            params = {"object_type": "item", "limit": 100}
            if cursor:
                params["cursor"] = cursor
            payload = self._get(token, "/api/v1/activities", params)
            if payload is None:
                return None if not got_any else out
            got_any = True
            events = self._items(payload)
            stop = False
            for ev in events:
                ev_dt = _parse_iso(ev.get("event_date"))
                if ev_dt is None:
                    continue
                if ev_dt < since:
                    stop = True
                    continue
                if ev.get("event_type") == "deleted":
                    out.append(ev)
            cursor = payload.get("next_cursor") if isinstance(payload, dict) else None
            if stop or not cursor:
                break
        return out

    # -- 2.5 snapshot signature -------------------------------------------

    @staticmethod
    def snapshot_sig(tasks: list) -> dict:
        """Map task id → (updated_at, hash(content/priority/due)).

        Primary API-recency source: a diff against the previous snapshot catches
        any real mutation of an active task (server bumps `updated_at` only on a
        genuine change).
        """
        sig: dict = {}
        for t in tasks or []:
            tid = str(t.get("id"))
            if not tid or tid == "None":
                continue
            due = t.get("due") or {}
            blob = json.dumps(
                {
                    "content": t.get("content"),
                    "priority": t.get("priority"),
                    "due": due.get("date") or due.get("datetime"),
                },
                sort_keys=True,
                ensure_ascii=False,
            )
            digest = hashlib.sha1(blob.encode("utf-8")).hexdigest()
            sig[tid] = (t.get("updated_at") or t.get("added_at"), digest)
        return sig

    # -- 2.5a recurring-due-only guard ------------------------------------

    @staticmethod
    def recurring_due_only_change(prev_task: dict, cur_task: dict) -> bool:
        """True if ONLY `due` changed AND it's recurring → likely auto-rollover.

        Such a change is a client-side iteration advance, not a Todoist
        Interaction. Any other field change → not guarded (treat as interaction).
        Empirical necessity tracked by task 7.10a.
        """
        if not prev_task or not cur_task:
            return False
        if cur_task.get("content") != prev_task.get("content"):
            return False
        if cur_task.get("priority") != prev_task.get("priority"):
            return False
        cur_due = cur_task.get("due") or {}
        prev_due = prev_task.get("due") or {}
        cur_date = cur_due.get("date") or cur_due.get("datetime")
        prev_date = prev_due.get("date") or prev_due.get("datetime")
        if cur_date == prev_date:
            return False  # due did not change → not a rollover
        return bool(cur_due.get("is_recurring"))

    # -- 2.6 recent API change time ---------------------------------------

    def recent_api_change_time(self, prev_snapshot: Optional[dict],
                               cur_snapshot: dict,
                               prev_tasks_by_id: Optional[dict],
                               cur_tasks_by_id: dict,
                               completed: Optional[list],
                               deleted_activity: Optional[list],
                               recently_changed_ids: Optional[set] = None,
                               ) -> Optional[datetime.datetime]:
        """Max Todoist Change Time across snapshot diff, completed, deleted.

        - updated_at of tasks whose snapshot hash shifted (minus recurring-due
          guard 2.5a, unless the same id also appears in completed/deleted);
        - completed_at of completed tasks (2.3);
        - event_date of deleted events (2.4).
        Returns None if nothing changed.
        """
        times: list[datetime.datetime] = []
        recently_changed_ids = recently_changed_ids or set()

        if prev_snapshot is not None:
            prev_tasks_by_id = prev_tasks_by_id or {}
            cur_tasks_by_id = cur_tasks_by_id or {}
            for tid, (updated, digest) in cur_snapshot.items():
                prev = prev_snapshot.get(tid)
                if prev is None:
                    # New active task appeared → real change.
                    dt = _parse_iso(updated)
                    if dt is not None:
                        times.append(dt)
                    continue
                if prev[1] == digest:
                    continue  # unchanged
                # Hash shifted → apply recurring-due-only guard.
                guarded = self.recurring_due_only_change(
                    prev_tasks_by_id.get(tid, {}), cur_tasks_by_id.get(tid, {})
                )
                if guarded and tid not in recently_changed_ids:
                    continue
                dt = _parse_iso(updated)
                if dt is not None:
                    times.append(dt)

        for c in completed or []:
            dt = _parse_iso(c.get("completed_at"))
            if dt is not None:
                times.append(dt)

        for ev in deleted_activity or []:
            dt = _parse_iso(ev.get("event_date"))
            if dt is not None:
                times.append(dt)

        return max(times) if times else None

    # -- 2.7 dashboard ----------------------------------------------------

    @staticmethod
    def dashboard(tasks: list, cap: int = 10) -> dict:
        """Per-priority dated dashboard (design D1).

        Shape::

            {
              "columns": {"p1": [ {content, due_label, overdue, due_sort}, ... ],
                          "p2": [...], "p3": [...], "p4": [...]},
              "counts":  {"p1": {dated, overdue, undated_hidden}, ...},
            }

        REST priority mapping: 4=p1, 3=p2, 2=p3, 1=p4.
        Only tasks with a due date no later than today enter `columns[pX]`;
        undated tasks are excluded and counted in `counts[pX].undated_hidden`.
        Each list is sorted by `due_sort` ascending (overdue first, then today).
        The producer does NOT cap — the renderer slices to per-monitor
        geometry. `cap` is accepted for call-site compatibility and ignored.
        """
        now = datetime.datetime.now()
        today = now.date()
        keys = {4: "p1", 3: "p2", 2: "p3", 1: "p4"}
        columns: dict = {"p1": [], "p2": [], "p3": [], "p4": []}
        counts: dict = {
            k: {"dated": 0, "overdue": 0, "undated_hidden": 0}
            for k in ("p1", "p2", "p3", "p4")
        }

        for t in tasks or []:
            prio = t.get("priority") or 1
            key = keys.get(prio, "p4")
            due = t.get("due") or {}
            due_raw = due.get("date") or due.get("datetime")
            due_dt = _parse_iso(due_raw)
            if due_dt is None:
                counts[key]["undated_hidden"] += 1
                continue
            if due_dt.date() > today:
                continue
            has_time = bool(due.get("datetime"))
            overdue = due_dt.date() < today
            columns[key].append({
                "content": t.get("content", ""),
                "due_label": _due_label(due_dt, has_time, now),
                "overdue": overdue,
                "due_sort": due_dt.strftime("%Y-%m-%dT%H:%M"),
            })
            counts[key]["dated"] += 1
            if overdue:
                counts[key]["overdue"] += 1

        for key in columns:
            columns[key].sort(key=lambda x: x["due_sort"])

        return {"columns": columns, "counts": counts}


def _to_api_iso(dt: datetime.datetime) -> str:
    """Naive-local datetime → UTC ISO string with `Z` suffix for the API."""
    aware = dt.replace(tzinfo=None).astimezone()
    return aware.astimezone(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
