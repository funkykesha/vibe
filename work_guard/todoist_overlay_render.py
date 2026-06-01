"""
PyObjC renderer for the Todoist engagement reminder overlay
(redesign-todoist-overlay).

Pure layout (design D6): consumes the `columns`/`counts` dashboard shape from
`TodoistApiClient.dashboard` and paints a dark backdrop with a centered rounded
"Todoist-in-terminal" panel — header band, a priority-section grid, centered
actions. Two width tiers (D4) and a screen-height-driven dynamic row cap (D9).

Must run on the process main thread (own NSApplication). Imported lazily by
`todoist_overlay.py`'s subprocess entry point so the parent never imports AppKit.

Visual source of truth: `docs/design/todoist-overlay-prototype.html`.
"""

import datetime
import logging
import math
import subprocess
from typing import Callable, Optional

logger = logging.getLogger(__name__)

# ---- D4: width tier ----------------------------------------------------
WIDE_TIER_MIN_WIDTH = 2560

# ---- D5/D9: layout constants (absolute px / screen points) -------------
GUTTER = 22
PANEL_PAD_H = 34            # panel left/right inner padding
HEADER_H = 40              # section header strip
FOOTER_H = 30              # section stat footer
ROW_H = 46                 # task-card row pitch (incl. gap)
PANEL_MARGIN_V = 64        # screen-edge → panel, top and bottom
PANEL_PAD_TOP = 30
PANEL_PAD_BOTTOM = 26
HEADER_BAND_H = 120        # eyebrow + headline + clock + gaps
ACTIONS_BAND_H = 92        # dashed separator + centered button row
COUNTCARD_H = 64

PANEL_RADIUS = 16
SECTION_RADIUS = 10
ROW_RADIUS = 7

# ---- D3: Todoist palette + surface/ink tokens --------------------------
# RGB tuples (0..1); turned into NSColor in `run_overlay`.
C_P1 = (0.82, 0.27, 0.23)        # #d1453b
C_P2 = (0.92, 0.54, 0.04)        # #eb8909
C_P3 = (0.14, 0.44, 0.88)        # #246fe0
C_P4 = (0.49, 0.49, 0.49)        # #7d7d7d
C_OVERDUE = (1.00, 0.42, 0.37)   # #ff6b5e

C_BG0 = (0.08, 0.08, 0.08)       # screen backdrop #141414
C_BG1 = (0.11, 0.11, 0.11)       # panel bg #1c1c1c
C_BG2 = (0.14, 0.14, 0.14)       # task-card bg #242424
C_LINE = (0.19, 0.19, 0.19)      # hairline #313131
C_LINE2 = (0.235, 0.235, 0.235)  # #3c3c3c

C_INK0 = (0.95, 0.95, 0.93)      # primary text #f2f1ec
C_INK1 = (0.725, 0.722, 0.698)   # #b9b8b2
C_INK2 = (0.435, 0.431, 0.412)   # secondary #6f6e69
C_INK3 = (0.29, 0.286, 0.275)    # #4a4946

_SECTIONS = {
    "p1": ("P1", "срочно", C_P1),
    "p2": ("P2", "важно", C_P2),
    "p3": ("P3", "обычные", C_P3),
    "p4": ("P4", "потом", C_P4),
}

_RU_MONTHS_GEN = [
    "января", "февраля", "марта", "апреля", "мая", "июня",
    "июля", "августа", "сентября", "октября", "ноября", "декабря",
]


def _plural_task(n: int) -> str:
    """Russian grammatical plural for 'задача'."""
    n10, n100 = n % 10, n % 100
    if n10 == 1 and n100 != 11:
        return "задача"
    if 2 <= n10 <= 4 and not 12 <= n100 <= 14:
        return "задачи"
    return "задач"


def _clock_str(now: datetime.datetime) -> str:
    return f"{now:%H:%M}, {now.day:02d} {_RU_MONTHS_GEN[now.month - 1]} {now.year}"


def run_overlay(message: str, dashboard: Optional[dict], app_path: str,
                emit: Callable[[str], None]):
    """PyObjC reminder overlay. Must run on the main thread. No NSTimer."""
    from AppKit import (
        NSApplication, NSPanel, NSScreen, NSColor, NSFont, NSView,
        NSTextField, NSButton, NSMutableAttributedString,
        NSFontAttributeName, NSForegroundColorAttributeName, NSString,
        NSApplicationActivationPolicyAccessory,
        NSWindowCollectionBehaviorCanJoinAllSpaces,
        NSWindowCollectionBehaviorStationary,
        NSScreenSaverWindowLevel,
        NSBorderlessWindowMask,
        NSTextAlignmentCenter, NSTextAlignmentLeft, NSTextAlignmentRight,
    )
    from Foundation import NSObject, NSMakeRect, NSMakeRange

    class _Flipped(NSView):
        def isFlipped(self):
            return True

    app = NSApplication.sharedApplication()
    app.setActivationPolicy_(NSApplicationActivationPolicyAccessory)

    # -- colors --------------------------------------------------------
    def col(rgb, a=1.0):
        r, g, b = rgb
        return NSColor.colorWithCalibratedRed_green_blue_alpha_(r, g, b, a)

    NS = {k: col(v) for k, v in {
        "p1": C_P1, "p2": C_P2, "p3": C_P3, "p4": C_P4, "overdue": C_OVERDUE,
        "bg0": C_BG0, "bg1": C_BG1, "bg2": C_BG2, "line": C_LINE, "line2": C_LINE2,
        "ink0": C_INK0, "ink1": C_INK1, "ink2": C_INK2, "ink3": C_INK3,
    }.items()}
    NS["clear"] = NSColor.clearColor()

    # -- fonts (SF Mono → Menlo fallback, D3) --------------------------
    def font(size, weight="regular"):
        names = {
            "regular": ["SFMono-Regular", "Menlo-Regular", "Menlo"],
            "medium": ["SFMono-Medium", "Menlo-Regular", "Menlo"],
            "bold": ["SFMono-Bold", "Menlo-Bold"],
        }[weight]
        for n in names:
            f = NSFont.fontWithName_size_(n, size)
            if f is not None:
                return f
        return NSFont.monospacedSystemFontOfSize_weight_(size, 0)

    F = {
        "headline": font(27, "bold"), "eyebrow": font(12, "regular"),
        "tag": font(11, "medium"), "sec": font(13, "bold"),
        "task": font(14, "medium"), "due": font(12, "medium"),
        "stat": font(12, "regular"), "num": font(30, "bold"),
        "numsmall": font(12, "medium"), "clock": font(13, "medium"),
        "more": font(12, "regular"), "dots": font(11, "regular"),
        "btn": font(13, "bold"),
    }

    # -- low-level view builders --------------------------------------
    def label(text, x, y, w, h, color, fnt, align, parent):
        tf = NSTextField.alloc().initWithFrame_(NSMakeRect(x, y, w, h))
        tf.setStringValue_(text)
        tf.setTextColor_(color)
        tf.setFont_(fnt)
        tf.setAlignment_(align)
        tf.setBezeled_(False)
        tf.setDrawsBackground_(False)
        tf.setEditable_(False)
        tf.setSelectable_(False)
        parent.addSubview_(tf)
        return tf

    def two_color_label(prefix, prefix_color, rest, rest_color,
                        x, y, w, h, fnt, parent):
        full = f"{prefix}{rest}"
        attr = NSMutableAttributedString.alloc().initWithString_(full)
        full_len = len(full)
        attr.addAttribute_value_range_(NSFontAttributeName, fnt,
                                       NSMakeRange(0, full_len))
        attr.addAttribute_value_range_(NSForegroundColorAttributeName,
                                       rest_color, NSMakeRange(0, full_len))
        attr.addAttribute_value_range_(NSForegroundColorAttributeName,
                                       prefix_color, NSMakeRange(0, len(prefix)))
        tf = NSTextField.alloc().initWithFrame_(NSMakeRect(x, y, w, h))
        tf.setAttributedStringValue_(attr)
        tf.setBezeled_(False)
        tf.setDrawsBackground_(False)
        tf.setEditable_(False)
        tf.setSelectable_(False)
        parent.addSubview_(tf)
        return tf

    def box(x, y, w, h, parent, bg=None, radius=0, border=None, borderw=0.0):
        v = NSView.alloc().initWithFrame_(NSMakeRect(x, y, w, h))
        v.setWantsLayer_(True)
        layer = v.layer()
        if bg is not None:
            layer.setBackgroundColor_(bg.CGColor())
        if radius:
            layer.setCornerRadius_(radius)
        if border is not None and borderw:
            layer.setBorderColor_(border.CGColor())
            layer.setBorderWidth_(borderw)
        parent.addSubview_(v)
        return v

    def truncate(s, fnt, max_w):
        if not s:
            return s
        attrs = {NSFontAttributeName: fnt}
        if NSString.stringWithString_(s).sizeWithAttributes_(attrs).width <= max_w:
            return s
        cut = s
        while cut and NSString.stringWithString_(
                cut + "…").sizeWithAttributes_(attrs).width > max_w:
            cut = cut[:-1]
        return (cut + "…") if cut else "…"

    # -- section / count-card renderers (defined below scaffold) -------
    def render_section(parent, key, tasks, cnt, x, y, w, section_h):
        _render_section(parent, key, tasks, cnt, x, y, w, section_h,
                        NS, F, label, two_color_label, box, truncate,
                        NSTextAlignmentLeft, NSTextAlignmentRight)

    def render_countcard(parent, key, cnt, x, y, w):
        _render_countcard(parent, key, cnt, x, y, w,
                          NS, F, label, two_color_label, box,
                          NSTextAlignmentLeft, NSTextAlignmentRight)

    class Handler(NSObject):
        def openTodoist_(self, sender):
            emit("open")
            try:
                subprocess.Popen(["open", "-a", app_path])
            except Exception:
                pass
            app.terminate_(None)

        def dismiss_(self, sender):
            emit("dismiss")
            app.terminate_(None)

    handler = Handler.alloc().init()
    now = datetime.datetime.now()
    clock = _clock_str(now)
    has_grid = isinstance(dashboard, dict) and "columns" in dashboard

    panels = []
    for screen in NSScreen.screens():
        frame = screen.frame()
        W = float(frame.size.width)
        H = float(frame.size.height)
        tier = 2 if W > WIDE_TIER_MIN_WIDTH else 1

        sm_panel = NSPanel.alloc().initWithContentRect_styleMask_backing_defer_(
            frame, NSBorderlessWindowMask, 2, False,
        )
        sm_panel.setLevel_(NSScreenSaverWindowLevel)
        sm_panel.setCollectionBehavior_(
            NSWindowCollectionBehaviorCanJoinAllSpaces |
            NSWindowCollectionBehaviorStationary
        )
        sm_panel.setBackgroundColor_(NS["bg0"])
        sm_panel.setOpaque_(True)
        sm_panel.setHidesOnDeactivate_(False)
        cv = sm_panel.contentView()

        # Panel geometry.
        if tier == 2:
            panel_w = min(0.96 * W, 1680.0)
        else:
            panel_w = min(0.92 * W, 1180.0)
        panel_h = H - 2 * PANEL_MARGIN_V
        panel_x = (W - panel_w) / 2.0
        panel_y = (H - panel_h) / 2.0

        panel = _Flipped.alloc().initWithFrame_(
            NSMakeRect(panel_x, panel_y, panel_w, panel_h))
        panel.setWantsLayer_(True)
        play = panel.layer()
        play.setBackgroundColor_(NS["bg1"].CGColor())
        play.setCornerRadius_(PANEL_RADIUS)
        play.setBorderColor_(NS["line2"].CGColor())
        play.setBorderWidth_(1.0)
        play.setShadowColor_(NSColor.blackColor().CGColor())
        play.setShadowOpacity_(0.6)
        play.setShadowRadius_(40.0)
        cv.addSubview_(panel)

        _build_panel(panel, message, dashboard, has_grid, tier, panel_w, panel_h,
                     clock, NS, F, handler, label, two_color_label, box,
                     render_section, render_countcard,
                     NSTextAlignmentCenter, NSTextAlignmentLeft,
                     NSTextAlignmentRight)

        sm_panel.makeKeyAndOrderFront_(None)
        panels.append(sm_panel)

    app.activateIgnoringOtherApps_(True)
    app.run()
