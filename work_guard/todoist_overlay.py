"""
Full-screen Todoist engagement reminder overlay.

Separate module from `overlay.py` by design (D4): different UX — no countdown
timer, two action buttons, a non-clickable task mini-dashboard. Same
subprocess/stdin pattern so NSApplication gets its own main thread.

Buttons:
  - «Перейти в Todoist» → `open -a <app_path>`, result `open`;
  - «Свернуть оверлей»  → result `dismiss` (does NOT reset engagement).

The subprocess writes a single JSON result line to stdout before terminating;
the parent launcher reads it and invokes a callback so the `open` action can
update `last_engagement` immediately without waiting for the next tick.

Rendering (redesign-todoist-overlay): a dark backdrop with a centered rounded
"Todoist-in-terminal" panel — header band, a priority-section grid, centered
actions. Two width tiers (D4) and a screen-height-driven dynamic row cap (D9).
The producer (`TodoistApiClient.dashboard`) emits the `columns`/`counts` shape;
this renderer is pure layout.
"""

import json
import logging
import subprocess
import sys
import threading
from pathlib import Path
from typing import Callable, Optional

logger = logging.getLogger(__name__)


class TodoistReminderOverlay:
    """Launches the reminder overlay subprocess and relays its action result."""

    def __init__(self):
        self._proc: Optional[subprocess.Popen] = None
        self._lock = threading.Lock()
        self._active = False

    def is_active(self) -> bool:
        with self._lock:
            return self._active

    def show(self, message: str, dashboard: Optional[dict], app_path: str,
             on_result: Optional[Callable[[str], None]] = None) -> None:
        """Show the reminder on all monitors. Non-blocking."""
        with self._lock:
            if self._active:
                logger.debug("Todoist overlay already active — skipping")
                return
            self._active = True
        threading.Thread(
            target=self._launch,
            args=(message, dashboard, app_path, on_result),
            daemon=True,
        ).start()

    def close(self) -> None:
        with self._lock:
            proc = self._proc
        if proc:
            try:
                proc.terminate()
            except Exception:
                pass

    def _launch(self, message, dashboard, app_path, on_result):
        script = Path(__file__)
        payload = json.dumps(
            {"message": message, "dashboard": dashboard, "app_path": app_path}
        )
        result = "dismiss"
        try:
            proc = subprocess.Popen(
                [sys.executable, str(script)],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
            )
            with self._lock:
                self._proc = proc
            out, _ = proc.communicate(payload.encode())
            result = _parse_result(out) or "dismiss"
        except Exception as e:
            logger.exception("Todoist overlay subprocess error: %s", e)
        finally:
            with self._lock:
                self._active = False
                self._proc = None
        if on_result:
            try:
                on_result(result)
            except Exception as e:
                logger.exception("Todoist overlay on_result failed: %s", e)


def _parse_result(out: bytes) -> Optional[str]:
    if not out:
        return None
    for line in reversed(out.decode("utf-8", errors="replace").splitlines()):
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
            if isinstance(obj, dict) and "result" in obj:
                return obj["result"]
        except ValueError:
            continue
    return None


def _emit_result(result: str) -> None:
    try:
        sys.stdout.write(json.dumps({"result": result}) + "\n")
        sys.stdout.flush()
    except Exception:
        pass


# ------------------------------------------------------------------
# Subprocess entry point — runs in its own process with a real main thread
# ------------------------------------------------------------------

if __name__ == "__main__":
    logging.basicConfig(level=logging.WARNING)
    from todoist_overlay_render import run_overlay  # noqa: E402

    data = json.loads(sys.stdin.read())
    run_overlay(data["message"], data.get("dashboard"), data.get("app_path", ""),
                _emit_result)
