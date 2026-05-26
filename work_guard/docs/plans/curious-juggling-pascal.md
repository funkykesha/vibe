# Fix: settings dialog crash on launch

## Context

User reports "не открывается экран настроек" (settings screen doesn't open).

OpenSpec change `add-overlay-deferral-period-policy` (56/58 tasks done) rewrote
`settings_dialog.py` for Mode 1 / Mode 2 layout (tasks 9.1–9.9). Manual test
task `10.8` ("open settings dialog in Mode 1 and Mode 2") was never run, so the
regression slipped past CI.

`open_settings` in `work_guard.py:525` launches `settings_dialog.py` via
`subprocess.Popen([sys.executable, str(script)])` and detaches it — stderr is
discarded, so the crash is silent from the user's POV.

Running `python3 settings_dialog.py` reproduces:

```
TypeError: tkinter.Label() got multiple values for keyword argument 'font'
  File ".../settings_dialog.py", line 109, in main
    lbl(hours_frame, "Следующий / Текущий", font=FONT_SM, fg=MUTED).pack(...)
  File ".../settings_dialog.py", line 68, in lbl
    return tk.Label(parent, text=text, bg=BG, fg=FG, font=FONT, **kw)
```

## Root cause

`settings_dialog.py:67-68`:

```python
def lbl(parent, text, **kw):
    return tk.Label(parent, text=text, bg=BG, fg=FG, font=FONT, **kw)
```

Helper hardcodes `font=FONT` and `fg=FG` in body, but call sites pass
`font=FONT_SM` and `fg=MUTED` through `**kw` → Python collision → `TypeError`.

Affected call sites (all crash, both modes):

- `113` — Mode 1, "Текущий" label
- `109, 145` — Mode 2, "Следующий / Текущий"
- `125, 167` — Mode 2, "Было / —"

Mode 1 hits at line 113 unconditionally, so settings dialog has been
fully broken for all users since the rewrite landed.

## Fix

Edit `settings_dialog.py:67-68` only. Change `lbl` helper so `font` and `fg`
are overridable defaults instead of hardcoded constants:

```python
def lbl(parent, text, font=FONT, fg=FG, **kw):
    return tk.Label(parent, text=text, bg=BG, fg=fg, font=font, **kw)
```

No call sites need changes — every existing call already passes `font=` /
`fg=` as keyword arguments that now bind cleanly.

Scope: 1 file, 2 lines. No spec, no architecture, no IPC change.

## Critical file

- `settings_dialog.py:67-68`

## Verification

1. From repo root, run:
   ```bash
   python3 settings_dialog.py
   ```
   Expect: window opens (Mode 1, since current config has no
   `pending_period_settings` and likely no active deferral period).
   No traceback in terminal. Close window manually.

2. To exercise Mode 2 path, in another terminal set a pending value:
   ```bash
   python3 -c "from config import load_config, save_config; c=load_config(); c['pending_period_settings']={'work_start':'10:00','work_end':'20:00','work_days':[1,2,3,4,5]}; save_config(c)"
   python3 settings_dialog.py
   ```
   Expect: banner at top + "Следующий / Текущий" + "Было / —" rows render.
   Revert pending after:
   ```bash
   python3 -c "from config import load_config, save_config; c=load_config(); c['pending_period_settings']=None; save_config(c)"
   ```

3. Full app path:
   ```bash
   bash rebuild.sh
   ```
   Click menu bar → "Настройки..." → dialog opens.

4. Close OpenSpec task `10.8` (manual test) in beads / tasks.md once
   verification passes, since this fix is the missing piece that blocked it.

## Out of scope

- `subprocess.Popen` swallowing stderr from `settings_dialog.py` — useful to
  capture in a log file, but separate change. Not blocking user.
- Remaining 2 incomplete tasks (`10.7` overlay manual, `10.8` settings manual)
  — close `10.8` after this fix verifies; `10.7` independent.
