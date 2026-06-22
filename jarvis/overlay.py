"""
Overlay micro-button widget (PyObjC / AppKit).

A small floating, draggable, always-on-top panel that lives above every
window — including full-screen Spaces. Click toggles the "call":

  - idle  -> click starts a call: the button glows and a borderless input
    field appears. The user dictates into it with Handy (or types); pressing
    Enter submits one transcript turn.
  - in-call -> click (or a "hang up" voice command) ends the call.

"Liquid glass" look via NSVisualEffectView (concept iteration 3 refines this).

This module needs a real NSApplication main thread — it is driven by
`jarvis.py`, not run standalone.
"""

import logging

from AppKit import (
    NSPanel, NSScreen, NSColor, NSView, NSTextField, NSVisualEffectView,
    NSVisualEffectBlendingModeBehindWindow, NSVisualEffectStateActive,
    NSWindowCollectionBehaviorCanJoinAllSpaces,
    NSWindowCollectionBehaviorStationary,
    NSWindowCollectionBehaviorFullScreenAuxiliary,
    NSScreenSaverWindowLevel, NSBorderlessWindowMask,
    NSEvent, NSTextAlignmentCenter,
)
from Foundation import NSObject, NSMakeRect, NSMakePoint

logger = logging.getLogger(__name__)

BUTTON_SIZE = 64
FIELD_WIDTH = 320
FIELD_HEIGHT = 28
MARGIN = 8


class _ButtonView(NSView):
    """The clickable, draggable circular button. Forwards events to controller."""

    def initWithController_(self, controller):
        self = self.initWithFrame_(NSMakeRect(0, 0, BUTTON_SIZE, BUTTON_SIZE))
        if self is None:
            return None
        self._controller = controller
        self._drag_origin = None
        return self

    def mouseDown_(self, event):
        self._drag_origin = NSEvent.mouseLocation()
        self._win_origin = self.window().frame().origin
        self._moved = False

    def mouseDragged_(self, event):
        if self._drag_origin is None:
            return
        now = NSEvent.mouseLocation()
        dx = now.x - self._drag_origin.x
        dy = now.y - self._drag_origin.y
        if abs(dx) > 3 or abs(dy) > 3:
            self._moved = True
        self.window().setFrameOrigin_(
            NSMakePoint(self._win_origin.x + dx, self._win_origin.y + dy)
        )

    def mouseUp_(self, event):
        # A click (no real drag) toggles the call; a drag just repositions.
        if not getattr(self, "_moved", False):
            self._controller.toggleCall_(self)
        self._drag_origin = None


class JarvisOverlay(NSObject):
    """
    Owns the floating panel. `on_transcript(text)` is called for each submitted
    turn; `on_hangup()` when the call ends. Wired by jarvis.py.
    """

    def initWithCallbacks_hangup_(self, on_transcript, on_hangup):
        self = self.init()
        if self is None:
            return None
        self._on_transcript = on_transcript
        self._on_hangup = on_hangup
        self._in_call = False
        self._build()
        return self

    def _build(self):
        screen = NSScreen.mainScreen().frame()
        # Bottom-right corner by default.
        x = screen.size.width - BUTTON_SIZE - 40
        y = 60
        rect = NSMakeRect(x, y, BUTTON_SIZE, BUTTON_SIZE + FIELD_HEIGHT + MARGIN)

        panel = NSPanel.alloc().initWithContentRect_styleMask_backing_defer_(
            rect, NSBorderlessWindowMask, 2, False
        )
        panel.setLevel_(NSScreenSaverWindowLevel)
        panel.setCollectionBehavior_(
            NSWindowCollectionBehaviorCanJoinAllSpaces
            | NSWindowCollectionBehaviorStationary
            | NSWindowCollectionBehaviorFullScreenAuxiliary
        )
        panel.setOpaque_(False)
        panel.setBackgroundColor_(NSColor.clearColor())
        panel.setHidesOnDeactivate_(False)
        panel.setMovableByWindowBackground_(False)

        content = panel.contentView()

        # "Liquid glass" blur backing for the button.
        blur = NSVisualEffectView.alloc().initWithFrame_(
            NSMakeRect(0, FIELD_HEIGHT + MARGIN, BUTTON_SIZE, BUTTON_SIZE)
        )
        blur.setBlendingMode_(NSVisualEffectBlendingModeBehindWindow)
        blur.setState_(NSVisualEffectStateActive)
        blur.setWantsLayer_(True)
        blur.layer().setCornerRadius_(BUTTON_SIZE / 2)
        blur.layer().setMasksToBounds_(True)
        content.addSubview_(blur)

        button = _ButtonView.alloc().initWithController_(self)
        button.setFrameOrigin_(NSMakePoint(0, FIELD_HEIGHT + MARGIN))
        button.setWantsLayer_(True)
        button.layer().setCornerRadius_(BUTTON_SIZE / 2)
        content.addSubview_(button)

        glyph = NSTextField.alloc().initWithFrame_(
            NSMakeRect(0, FIELD_HEIGHT + MARGIN, BUTTON_SIZE, BUTTON_SIZE)
        )
        glyph.setStringValue_("🎙")
        glyph.setBezeled_(False)
        glyph.setDrawsBackground_(False)
        glyph.setEditable_(False)
        glyph.setSelectable_(False)
        glyph.setAlignment_(NSTextAlignmentCenter)
        glyph.setFont_(glyph.font().fontWithSize_(28))
        button.addSubview_(glyph)

        # Hidden until a call starts. Handy dictates into this field.
        field = NSTextField.alloc().initWithFrame_(
            NSMakeRect(BUTTON_SIZE - FIELD_WIDTH, 0, FIELD_WIDTH, FIELD_HEIGHT)
        )
        field.setPlaceholderString_("Говорите (Handy) или печатайте, Enter — отправить")
        field.setHidden_(True)
        field.setTarget_(self)
        field.setAction_("fieldSubmit:")
        content.addSubview_(field)

        panel.makeKeyAndOrderFront_(None)

        self._panel = panel
        self._button = button
        self._field = field
        self._set_idle_color()

    # -- call state -------------------------------------------------------

    def toggleCall_(self, sender):
        if self._in_call:
            self.endCall()
        else:
            self._start_call()

    def _start_call(self):
        self._in_call = True
        self._field.setHidden_(False)
        self._field.setStringValue_("")
        self._panel.makeFirstResponder_(self._field)
        self._button.layer().setBackgroundColor_(
            NSColor.systemGreenColor().colorWithAlphaComponent_(0.5).CGColor()
        )
        logger.info("Call started")

    def endCall(self):
        self._in_call = False
        self._field.setHidden_(True)
        self._set_idle_color()
        if self._on_hangup:
            self._on_hangup()
        logger.info("Call ended")

    def fieldSubmit_(self, sender):
        text = self._field.stringValue()
        self._field.setStringValue_("")
        if text and self._on_transcript:
            self._on_transcript(text)

    def _set_idle_color(self):
        self._button.layer().setBackgroundColor_(
            NSColor.whiteColor().colorWithAlphaComponent_(0.25).CGColor()
        )
