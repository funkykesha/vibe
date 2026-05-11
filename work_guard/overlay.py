"""
Full-screen overlay for all connected monitors.
Uses PyObjC NSPanel (not tkinter) to:
  - Stay above all windows at NSScreenSaverWindowLevel
  - Appear on ALL Spaces (NSWindowCollectionBehaviorCanJoinAllSpaces)
  - Remain visible when the user switches apps

Run as __main__ via subprocess (called by FullScreenOverlay).
"""

import json
import subprocess
import sys
import threading
import logging
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)

LOCK_DURATION = 30  # seconds before dismiss button appears


class FullScreenOverlay:
    """
    Creates one NSPanel overlay per monitor.
    Launches a subprocess so NSApplication gets its own main thread.
    Thread-safe singleton — only one overlay active at a time.
    """

    def __init__(self):
        self._proc: Optional[subprocess.Popen] = None
        self._lock = threading.Lock()
        self._active = False

    def is_active(self) -> bool:
        with self._lock:
            return self._active

    def show(self, art: str, message: str, lock_secs: int = LOCK_DURATION):
        """Show overlay on all monitors (and all Spaces). Non-blocking."""
        with self._lock:
            if self._active:
                logger.debug("Overlay already active — skipping")
                return
            self._active = True
        threading.Thread(
            target=self._launch, args=(art, message, lock_secs), daemon=True
        ).start()

    def close(self):
        """Programmatically close the overlay."""
        with self._lock:
            proc = self._proc
        if proc:
            try:
                proc.terminate()
            except Exception:
                pass

    def _launch(self, art: str, message: str, lock_secs: int):
        script = Path(__file__)
        payload = json.dumps({"art": art, "message": message, "lock_secs": lock_secs})
        try:
            proc = subprocess.Popen(
                [sys.executable, str(script)],
                stdin=subprocess.PIPE,
            )
            with self._lock:
                self._proc = proc
            proc.communicate(payload.encode())
        except Exception as e:
            logger.exception(f"Overlay subprocess error: {e}")
        finally:
            with self._lock:
                self._active = False
                self._proc = None


# ------------------------------------------------------------------
# Subprocess entry point — runs in its own process with a real main thread
# ------------------------------------------------------------------

def _run_overlay(art: str, message: str, lock_secs: int):
    """PyObjC-based full-screen overlay. Must run on the main thread."""
    import datetime
    from AppKit import (
        NSApplication, NSPanel, NSScreen, NSColor, NSFont,
        NSTextField, NSButton,
        NSApplicationActivationPolicyAccessory,
        NSWindowCollectionBehaviorCanJoinAllSpaces,
        NSWindowCollectionBehaviorStationary,
        NSScreenSaverWindowLevel,
        NSBorderlessWindowMask,
        NSTextAlignmentCenter,
    )
    from Foundation import NSTimer, NSObject, NSMakeRect

    app = NSApplication.sharedApplication()
    # Accessory policy: no dock icon, no menu bar takeover
    app.setActivationPolicy_(NSApplicationActivationPolicyAccessory)

    panels = []
    countdown_labels = []
    close_buttons = []
    remaining = [lock_secs]

    class Handler(NSObject):
        def closeAll_(self, sender):
            app.terminate_(None)

        def tick_(self, timer):
            remaining[0] -= 1
            if remaining[0] <= 0:
                timer.invalidate()
                for lbl in countdown_labels:
                    lbl.setHidden_(True)
                for btn in close_buttons:
                    btn.setHidden_(False)
            else:
                txt = f"Можно закрыть через {remaining[0]} сек..."
                for lbl in countdown_labels:
                    lbl.setStringValue_(txt)

    handler = Handler.alloc().init()

    green     = NSColor.colorWithCalibratedRed_green_blue_alpha_(0.00, 1.00, 0.25, 1.0)
    orange    = NSColor.colorWithCalibratedRed_green_blue_alpha_(1.00, 0.27, 0.00, 1.0)
    gray      = NSColor.colorWithCalibratedRed_green_blue_alpha_(0.50, 0.50, 0.50, 1.0)
    dark_gray = NSColor.colorWithCalibratedRed_green_blue_alpha_(0.30, 0.30, 0.30, 1.0)
    bg_color  = NSColor.colorWithCalibratedRed_green_blue_alpha_(0.04, 0.04, 0.04, 1.0)

    now_str = datetime.datetime.now().strftime("%H:%M, %d %B %Y")

    for screen in NSScreen.screens():
        frame = screen.frame()
        w = int(frame.size.width)
        h = int(frame.size.height)

        panel = NSPanel.alloc().initWithContentRect_styleMask_backing_defer_(
            frame,
            NSBorderlessWindowMask,
            2,      # NSBackingStoreBuffered
            False,
        )
        panel.setLevel_(NSScreenSaverWindowLevel)
        panel.setCollectionBehavior_(
            NSWindowCollectionBehaviorCanJoinAllSpaces |
            NSWindowCollectionBehaviorStationary
        )
        panel.setBackgroundColor_(bg_color)
        panel.setOpaque_(True)
        # NSPanel hides on deactivation by default — disable that
        panel.setHidesOnDeactivate_(False)

        cv = panel.contentView()

        def add_label(text, x, y, lw, lh, color, font_name, font_size):
            f = NSTextField.alloc().initWithFrame_(NSMakeRect(x, y, lw, lh))
            f.setStringValue_(text)
            f.setTextColor_(color)
            f.setFont_(NSFont.fontWithName_size_(font_name, font_size))
            f.setAlignment_(NSTextAlignmentCenter)
            f.setBezeled_(False)
            f.setDrawsBackground_(False)
            f.setEditable_(False)
            f.setSelectable_(False)
            cv.addSubview_(f)
            return f

        # ASCII art — takes up the middle half of the screen
        add_label(art,     0,          int(h * 0.25), w,          int(h * 0.50), green,     "Menlo",      13)
        # Warning message
        add_label(message, int(w*0.1), int(h * 0.18), int(w*0.8), int(h * 0.08), orange,   "Menlo-Bold", 20)
        # Clock
        add_label(now_str, 0,          int(h * 0.13), w,          int(h * 0.04), gray,      "Menlo",      13)
        # Countdown
        countdown = add_label(
            f"Можно закрыть через {lock_secs} сек...",
            0, int(h * 0.08), w, int(h * 0.04),
            dark_gray, "Menlo", 13,
        )
        countdown_labels.append(countdown)

        # Close button — hidden until lock expires
        btn = NSButton.alloc().initWithFrame_(
            NSMakeRect(w / 2 - 150, int(h * 0.05), 300, 44)
        )
        btn.setTitle_("  Закрыть  (я понял)  ")
        btn.setTarget_(handler)
        btn.setAction_("closeAll:")
        btn.setHidden_(True)
        cv.addSubview_(btn)
        close_buttons.append(btn)

        panel.makeKeyAndOrderFront_(None)
        panels.append(panel)

    app.activateIgnoringOtherApps_(True)

    NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats_(
        1.0, handler, "tick:", None, True
    )

    app.run()


if __name__ == "__main__":
    logging.basicConfig(level=logging.WARNING)
    data = json.loads(sys.stdin.read())
    _run_overlay(data["art"], data["message"], data["lock_secs"])
