"""
Jarvis — voice dispatcher overlay that orchestrates Codex agents (iteration 1).

Wires the pieces together:
    overlay (click → call, dictated text)  →  router (answer vs delegate)
    →  codex_launcher (interactive iTerm tab, async)

Run on macOS with PyObjC installed:
    python jarvis.py

See ARCHITECTURE.md for the full roadmap.
"""

import logging

from config import Config
from router import classify, Intent
import codex_launcher

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger("jarvis")


class Jarvis:
    def __init__(self, cfg: Config):
        self.cfg = cfg
        self._overlay = None

    def handle_transcript(self, text: str) -> None:
        """One voice/text turn. Decides whether to delegate to Codex."""
        action = classify(text)
        if action.intent is Intent.DELEGATE:
            logger.info("Delegating to Codex: %s", action.prompt)
            codex_launcher.launch(
                action.prompt, self.cfg.base_dir_expanded, self.cfg.codex_cmd
            )
        elif action.intent is Intent.HANGUP:
            logger.info("Hang-up command recognised")
            if self._overlay is not None:
                self._overlay.endCall()
        else:
            # ANSWER: iteration 1 has no conversational backend yet.
            logger.info("Answer (no-op in iteration 1): %s", text)

    def on_hangup(self) -> None:
        logger.info("Call ended by user")

    def run(self) -> None:
        from AppKit import (
            NSApplication, NSApplicationActivationPolicyAccessory,
        )
        from overlay import JarvisOverlay

        app = NSApplication.sharedApplication()
        app.setActivationPolicy_(NSApplicationActivationPolicyAccessory)

        self._overlay = JarvisOverlay.alloc().initWithCallbacks_hangup_(
            self.handle_transcript, self.on_hangup
        )
        logger.info("Jarvis overlay ready (base_dir=%s)", self.cfg.base_dir_expanded)
        app.run()


def main() -> None:
    Jarvis(Config.load()).run()


if __name__ == "__main__":
    main()
