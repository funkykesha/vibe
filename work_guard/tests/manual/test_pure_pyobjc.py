#!/usr/bin/env python3
"""Минимальный NSStatusItem на чистом PyObjC, без rumps."""
import objc
from AppKit import (
    NSApplication,
    NSApplicationActivationPolicyAccessory,
    NSStatusBar,
    NSVariableStatusItemLength,
    NSFont,
    NSObject,
)
from PyObjCTools import AppHelper
import logging

logging.basicConfig(level=logging.DEBUG)
log = logging.getLogger("test_pyobjc")


class AppDelegate(NSObject):
    def applicationDidFinishLaunching_(self, notification):
        log.info("App launched, creating status item...")

        self.status_item = NSStatusBar.systemStatusBar().statusItemWithLength_(
            NSVariableStatusItemLength
        )
        btn = self.status_item.button()
        btn.setTitle_("PY")
        btn.setFont_(NSFont.menuBarFontOfSize_(0))

        # диагностика
        window = btn.window()
        log.info("PURE PYOBJC: title=%r", btn.title())
        log.info("PURE PYOBJC: button frame=%s", btn.frame())
        if window:
            log.info("PURE PYOBJC: window frame=%s", window.frame())
            log.info("PURE PYOBJC: window visible=%s", window.isVisible())
        else:
            log.info("PURE PYOBJC: window=None")

        # повторная проверка через 3 секунды
        from Foundation import NSTimer
        NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats_(
            3.0, self, "delayedDiag:", None, False
        )

    def delayedDiag_(self, timer):
        btn = self.status_item.button()
        window = btn.window()
        log.info("PURE PYOBJC [3s]: title=%r", btn.title())
        log.info("PURE PYOBJC [3s]: button frame=%s", btn.frame())
        if window:
            wf = window.frame()
            log.info("PURE PYOBJC [3s]: window frame=%s", wf)
            log.info("PURE PYOBJC [3s]: window visible=%s", window.isVisible())

            # Попытка 1: orderFront — может macOS просто не показал окно
            window.orderFront_(None)
            
            # Попытка 2: если origin неправильный — узнать где menu bar
            from AppKit import NSScreen
            screen = NSScreen.mainScreen()
            screen_frame = screen.frame()
            menu_bar_height = screen_frame.size.height - screen.visibleFrame().size.height - screen.visibleFrame().origin.y
            correct_y = screen_frame.size.height - menu_bar_height
            
            log.info("PURE PYOBJC [3s]: screen=%s menubar_h=%s correct_y=%s",
                    screen_frame, menu_bar_height, correct_y)

            # Попытка 3: переместить окно
            from AppKit import NSMakeRect
            new_frame = NSMakeRect(
                wf.origin.x if wf.origin.x > 0 else 100.0,
                correct_y,
                wf.size.width,
                wf.size.height if wf.size.height > 0 else 22.0,
            )
            window.setFrame_display_(new_frame, True)
            window.setLevel_(25)  # NSStatusWindowLevel
            window.orderFront_(None)
            
            log.info("PURE PYOBJC [3s]: MOVED to %s", window.frame())
        else:
            log.info("PURE PYOBJC [3s]: window=None")



def main():
    app = NSApplication.sharedApplication()
    app.setActivationPolicy_(NSApplicationActivationPolicyAccessory)

    delegate = AppDelegate.alloc().init()
    app.setDelegate_(delegate)

    log.info("Starting run loop...")
    AppHelper.runEventLoop()


if __name__ == "__main__":
    main()
