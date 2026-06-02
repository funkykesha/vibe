"""
Codex launcher — opens an interactive Codex session in a new iTerm tab.

Async by design: we fire the AppleScript and return immediately so the
assistant can keep talking while Codex works (concept iteration 1). The tab
stays interactive so the user can keep typing prompts by hand.

The AppleScript building (`build_applescript`) is pure and unit-tested; only
`launch` touches the system via `osascript`.
"""

import logging
import subprocess

logger = logging.getLogger(__name__)


def _escape(s: str) -> str:
    """Escape a string for embedding inside an AppleScript double-quoted literal."""
    return s.replace("\\", "\\\\").replace('"', '\\"')


def build_applescript(prompt: str, base_dir: str, codex_cmd: str = "codex") -> str:
    """
    Build AppleScript that, in iTerm:
      1. opens a new tab,
      2. cd's into base_dir,
      3. starts an interactive Codex session,
      4. sends the initial prompt.

    The session is left interactive so further prompts can be typed manually.
    """
    cd_cmd = _escape(f"cd {base_dir!r}")
    start_cmd = _escape(codex_cmd)
    prompt_line = _escape(prompt)
    return f'''tell application "iTerm"
    activate
    if (count of windows) = 0 then
        create window with default profile
    else
        tell current window to create tab with default profile
    end if
    tell current session of current window
        write text "{cd_cmd}"
        write text "{start_cmd}"
        write text "{prompt_line}"
    end tell
end tell'''


def launch(prompt: str, base_dir: str, codex_cmd: str = "codex") -> None:
    """Fire the iTerm session non-blocking. Logs and swallows failures."""
    script = build_applescript(prompt, base_dir, codex_cmd)
    try:
        subprocess.Popen(["osascript", "-e", script])
        logger.info("Launched Codex in iTerm: %s", prompt[:80])
    except Exception:
        logger.exception("Failed to launch Codex via iTerm")
