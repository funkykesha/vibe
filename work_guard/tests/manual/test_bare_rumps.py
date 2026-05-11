#!/usr/bin/env python3
"""Минимальный тест: rumps без кастомизации _pin_status_item."""
import rumps
import logging

logging.basicConfig(level=logging.DEBUG)
log = logging.getLogger("test")


class TestApp(rumps.App):
    def __init__(self):
        super().__init__("TestWG", title="WG", quit_button="Quit")

    @rumps.timer(3)
    def diag(self, timer):
        timer.stop()
        try:
            item = self._nsapp.nsstatusitem
            btn = item.button()
            if btn:
                w = btn.window()
                log.info("BARE RUMPS: title=%r frame=%s", btn.title(), btn.frame())
                if w:
                    log.info("BARE RUMPS: window_frame=%s visible=%s", w.frame(), w.isVisible())
                else:
                    log.info("BARE RUMPS: window=None")
            else:
                log.info("BARE RUMPS: button=None")
        except Exception as e:
            log.error("BARE RUMPS diag error: %s", e)


if __name__ == "__main__":
    TestApp().run()
