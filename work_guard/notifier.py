import subprocess
import logging
from ascii_art import get_entry

logger = logging.getLogger(__name__)


def send_notification(title: str, body: str, sound: bool = True):
    """Send a macOS notification via osascript."""
    sound_name = "Basso" if sound else ""
    script = f'display notification "{body}" with title "{title}"'
    if sound_name:
        script += f' sound name "{sound_name}"'
    try:
        subprocess.run(
            ["osascript", "-e", script],
            check=True,
            capture_output=True,
            timeout=5,
        )
    except subprocess.TimeoutExpired:
        logger.warning("Notification timed out")
    except subprocess.CalledProcessError as e:
        logger.warning(f"Notification failed: {e.stderr.decode()}")


def notify_overtime(minutes_over: int):
    """Send a notification with escalating urgency based on minutes over work time."""
    if minutes_over < 10:
        level = 0
    elif minutes_over < 20:
        level = 1
    else:
        level = 2

    _art, message = get_entry(level)

    titles = [
        "Рабочий день закончился",
        "Уже пора заканчивать",
        "ХВАТИТ РАБОТАТЬ!",
    ]
    title = titles[level]

    # Add time context to message
    import datetime
    now = datetime.datetime.now().strftime("%H:%M")
    body = f"{now} — {message}"

    send_notification(title, body, sound=(level >= 1))
    logger.info(f"Notification sent: level={level}, minutes_over={minutes_over}")
