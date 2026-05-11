from AppKit import NSStatusBar, NSVariableStatusItemLength, NSApplication
from Foundation import NSRunLoop, NSDate

NSApplication.sharedApplication()

bar = NSStatusBar.systemStatusBar()
item = bar.statusItemWithLength_(NSVariableStatusItemLength)
btn = item.button()
btn.setTitle_("HI")
print("button:", btn)
print("item visible:", item.isVisible())

loop = NSRunLoop.currentRunLoop()
for _ in range(100):
    loop.runUntilDate_(NSDate.dateWithTimeIntervalSinceNow_(0.1))
