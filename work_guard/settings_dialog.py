#!/usr/bin/env python3
"""
Standalone settings dialog for WorkGuard.
Launched as a subprocess so tkinter runs in its own process/main thread.
"""

import datetime
import json
import sys
from pathlib import Path
import tkinter as tk

sys.path.insert(0, str(Path(__file__).resolve().parent))
from config import DEFAULTS as CFG_DEFAULTS, CONFIG_FILE as CONFIG_PATH, load_config, save_config  # noqa: E402
from production_calendar import ProductionCalendar  # noqa: E402

WEEKDAY_NAMES = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
WEEKDAY_RU_SHORT = ["ПН", "ВТ", "СР", "ЧТ", "ПТ", "СБ", "ВС"]


def _next_work_start_str(cfg: dict) -> str:
    ps = cfg.get("current_period_settings", {})
    work_start = ps.get("work_start", "09:00")
    work_days = ps.get("work_days", [1, 2, 3, 4, 5])
    try:
        start_time = datetime.datetime.strptime(work_start, "%H:%M").time()
    except ValueError:
        start_time = datetime.time(9, 0)
    calendar = ProductionCalendar(cfg)
    now = datetime.datetime.now()
    for i in range(1, 15):
        candidate = now.date() + datetime.timedelta(days=i)
        try:
            day_info = calendar.classify_date(candidate)
            is_work = day_info.is_workday
        except Exception:
            is_work = candidate.isoweekday() in work_days
        if is_work:
            dt = datetime.datetime.combine(candidate, start_time)
            weekday = WEEKDAY_RU_SHORT[candidate.weekday()]
            return f"{weekday} {dt.strftime('%H:%M')}, {dt.strftime('%Y-%m-%d')}"
    return work_start


def _parse_time(s: str):
    try:
        return datetime.datetime.strptime(s.strip(), "%H:%M").time()
    except ValueError:
        return None


def _days_equal(a: list, b: list) -> bool:
    return sorted(a) == sorted(b)


def main():
    cfg = load_config()
    mode2 = cfg.get("deferral") is not None

    current_snap = dict(cfg.get("current_period_settings") or CFG_DEFAULTS["current_period_settings"])
    defaults_ps = CFG_DEFAULTS["current_period_settings"]

    pending = cfg.get("pending_period_settings")
    edit_source = dict(pending) if pending else dict(current_snap)

    root = tk.Tk()
    root.title("WorkGuard — Настройки")
    root.configure(bg="#1e1e1e")
    root.resizable(True, True)
    root.lift()
    root.attributes("-topmost", True)
    root.after(200, lambda: root.attributes("-topmost", False))
    root.focus_force()

    BG = "#1e1e1e"
    FG = "#d4d4d4"
    ACCENT = "#00ff41"
    WARN = "#ff6b6b"
    ENTRY_BG = "#2d2d2d"
    FONT = ("Menlo", 12)
    FONT_SM = ("Menlo", 10)

    pad = {"padx": 12, "pady": 6}

    content = tk.Frame(root, bg=BG)
    content.pack(fill="both", expand=True, padx=10, pady=(10, 6))

    def lbl(parent, text, fg=FG, font=FONT, **kw):
        return tk.Label(parent, text=text, bg=BG, fg=fg, font=font, **kw)

    def entry_widget(parent, var, w=10):
        return tk.Entry(parent, textvariable=var, width=w,
                        bg=ENTRY_BG, fg=FG, font=FONT,
                        insertbackground=FG, relief="flat")

    # ── Banner (Mode 2 only) ──
    if mode2:
        next_str = _next_work_start_str(cfg)
        banner_text = f"Изменения применятся в следующий рабочий период\n(начнётся: {next_str})"
        tk.Label(content, text=banner_text, bg="#2a2a1e", fg="#e5c07b",
                 font=FONT_SM, relief="flat", padx=8, pady=6,
                 justify="left", wraplength=420).pack(fill="x", **pad)

    # ── Work hours ──
    hours_frame = tk.LabelFrame(content, text="Рабочие часы", bg=BG, fg=ACCENT, font=FONT)
    hours_frame.pack(fill="x", **pad)

    edit_label = "Следующий / Текущий:" if mode2 else "Текущий:"

    start_var = tk.StringVar(value=edit_source.get("work_start", "09:00"))
    end_var = tk.StringVar(value=edit_source.get("work_end", "19:00"))

    row = tk.Frame(hours_frame, bg=BG)
    row.pack(fill="x", padx=8, pady=4)
    lbl(row, edit_label, font=FONT_SM).pack(side="left", padx=(0, 8))
    lbl(row, "С:").pack(side="left")
    entry_widget(row, start_var, 8).pack(side="left", padx=(4, 16))
    lbl(row, "До:").pack(side="left")
    entry_widget(row, end_var, 8).pack(side="left", padx=4)

    if mode2:
        snap_start = current_snap.get("work_start", "09:00")
        snap_end = current_snap.get("work_end", "19:00")
        snap_row = tk.Frame(hours_frame, bg=BG)
        snap_row.pack(fill="x", padx=8, pady=(0, 4))
        lbl(snap_row, "Было / —:", font=FONT_SM).pack(side="left", padx=(0, 8))
        lbl(snap_row, "С:", font=FONT_SM).pack(side="left")
        _s = "—" if snap_start == start_var.get() else snap_start
        _start_was_lbl = lbl(snap_row, _s, font=FONT_SM, fg="#888888")
        _start_was_lbl.pack(side="left", padx=(4, 16))
        lbl(snap_row, "До:", font=FONT_SM).pack(side="left")
        _e = "—" if snap_end == end_var.get() else snap_end
        _end_was_lbl = lbl(snap_row, _e, font=FONT_SM, fg="#888888")
        _end_was_lbl.pack(side="left", padx=4)

    # hours validation message
    hours_err_lbl = lbl(hours_frame, "", fg=WARN, font=FONT_SM)
    hours_err_lbl.pack(anchor="w", padx=8)

    # ── Work days ──
    days_frame = tk.LabelFrame(content, text="Рабочие дни", bg=BG, fg=ACCENT, font=FONT)
    days_frame.pack(fill="x", **pad)

    edit_days = edit_source.get("work_days", [1, 2, 3, 4, 5])
    day_vars = []

    lbl(days_frame, edit_label, font=FONT_SM).pack(anchor="w", padx=8, pady=(4, 0))
    days_row = tk.Frame(days_frame, bg=BG)
    days_row.pack(padx=8, pady=2)
    for i, name in enumerate(WEEKDAY_NAMES):
        var = tk.BooleanVar(value=(i + 1) in edit_days)
        day_vars.append(var)
        tk.Checkbutton(days_row, text=name, variable=var,
                       bg=BG, fg=FG, selectcolor=ENTRY_BG,
                       activebackground=BG, font=FONT).pack(side="left", padx=2)

    if mode2:
        snap_days = current_snap.get("work_days", [1, 2, 3, 4, 5])
        lbl(days_frame, "Было / —:", font=FONT_SM).pack(anchor="w", padx=8)
        snap_days_row = tk.Frame(days_frame, bg=BG)
        snap_days_row.pack(padx=8, pady=(0, 4))
        snap_day_labels = []
        for i, wd in enumerate(WEEKDAY_NAMES):
            was_checked = (i + 1) in snap_days
            now_checked = (i + 1) in edit_days
            text = "—" if was_checked == now_checked else wd
            lbl_w = lbl(snap_days_row, text, font=FONT_SM, fg="#888888")
            lbl_w.pack(side="left", padx=2)
            snap_day_labels.append((lbl_w, i + 1, was_checked))

    days_err_lbl = lbl(days_frame, "", fg=WARN, font=FONT_SM)
    days_err_lbl.pack(anchor="w", padx=8)

    # ── Validation & save button state ──
    save_btn_ref = [None]

    def validate(_=None):
        errors_hours = []
        errors_days = []

        s = _parse_time(start_var.get())
        e = _parse_time(end_var.get())
        if s is None or e is None:
            errors_hours.append("Формат времени: ЧЧ:ММ")
        elif s >= e:
            errors_hours.append("Начало должно быть раньше конца")

        selected_days = [i + 1 for i, v in enumerate(day_vars) if v.get()]
        if not selected_days:
            errors_days.append("Выберите хотя бы один день")

        hours_err_lbl.config(text=" ".join(errors_hours))
        days_err_lbl.config(text=" ".join(errors_days))

        ok = not errors_hours and not errors_days
        if save_btn_ref[0]:
            save_btn_ref[0].config(state="normal" if ok else "disabled")

        if mode2:
            # update was-labels for hours
            try:
                ns = start_var.get()
                ne = end_var.get()
                _start_was_lbl.config(text="—" if snap_start == ns else snap_start)
                _end_was_lbl.config(text="—" if snap_end == ne else snap_end)
            except Exception:
                pass
            # update was-labels for days
            try:
                cur_checked = [i + 1 for i, v in enumerate(day_vars) if v.get()]
                for lbl_w, day_num, was_checked in snap_day_labels:
                    now_checked = day_num in cur_checked
                    lbl_w.config(text="—" if was_checked == now_checked else WEEKDAY_NAMES[day_num - 1])
            except Exception:
                pass

    start_var.trace_add("write", validate)
    end_var.trace_add("write", validate)
    for v in day_vars:
        v.trace_add("write", validate)

    # ── Buttons ──
    def apply_defaults():
        start_var.set(defaults_ps.get("work_start", "09:00"))
        end_var.set(defaults_ps.get("work_end", "19:00"))
        dd = defaults_ps.get("work_days", [1, 2, 3, 4, 5])
        for i, v in enumerate(day_vars):
            v.set((i + 1) in dd)

    def apply_previous():
        start_var.set(current_snap.get("work_start", "09:00"))
        end_var.set(current_snap.get("work_end", "19:00"))
        dd = current_snap.get("work_days", [1, 2, 3, 4, 5])
        for i, v in enumerate(day_vars):
            v.set((i + 1) in dd)

    def save_and_close():
        form = {
            "work_start": start_var.get().strip(),
            "work_end": end_var.get().strip(),
            "work_days": [i + 1 for i, v in enumerate(day_vars) if v.get()],
        }
        fresh = load_config()
        if not mode2:
            fresh["current_period_settings"] = form
            fresh["pending_period_settings"] = None
        else:
            cur = fresh.get("current_period_settings", {})
            same = (
                form["work_start"] == cur.get("work_start")
                and form["work_end"] == cur.get("work_end")
                and _days_equal(form["work_days"], cur.get("work_days", []))
            )
            if same:
                fresh["pending_period_settings"] = None
            else:
                fresh["pending_period_settings"] = form
        save_config(fresh)
        root.destroy()

    actions = tk.Frame(root, bg=BG)
    actions.pack(fill="x", padx=12, pady=(4, 12))

    btn_kw = dict(bg=ENTRY_BG, fg=ACCENT, font=FONT, relief="flat", padx=14, pady=6, cursor="hand2")
    tk.Button(actions, text="Дефолт", command=apply_defaults, **btn_kw).pack(side="left")
    if mode2:
        tk.Button(actions, text="Предыдущий", command=apply_previous, **btn_kw).pack(side="left", padx=(8, 0))
    save_btn = tk.Button(actions, text="Сохранить", command=save_and_close, **btn_kw)
    save_btn.pack(side="right")
    save_btn_ref[0] = save_btn

    validate()  # initial state

    root.update_idletasks()
    req_w = root.winfo_reqwidth()
    req_h = root.winfo_reqheight()
    root.minsize(req_w, req_h)
    root.geometry(f"{req_w}x{req_h}")

    root.mainloop()


if __name__ == "__main__":
    main()
