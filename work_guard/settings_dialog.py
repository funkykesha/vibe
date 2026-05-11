#!/usr/bin/env python3
"""
Standalone settings dialog for WorkGuard.
Launched as a subprocess so tkinter runs in its own process/main thread.
"""

import sys
import json
from pathlib import Path
import tkinter as tk
from tkinter import messagebox

# Репозиторий должен быть в PYTHONPATH при запуске из work_guard.py
sys.path.insert(0, str(Path(__file__).resolve().parent))
from config import DEFAULTS as CFG_DEFAULTS, CONFIG_FILE as CONFIG_PATH  # noqa: E402


def load():
    cfg = CFG_DEFAULTS.copy()
    if CONFIG_PATH.exists():
        try:
            cfg.update(json.loads(CONFIG_PATH.read_text()))
        except Exception:
            pass
    for k, v in CFG_DEFAULTS.items():
        cfg.setdefault(k, v)
    return cfg


def save(cfg):
    """Сохранить настройки, не теряя полей вроде work_apps / pause_until."""
    merged = CFG_DEFAULTS.copy()
    merged.update(cfg)
    for k, v in CFG_DEFAULTS.items():
        merged.setdefault(k, v)
    CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
    CONFIG_PATH.write_text(json.dumps(merged, indent=2, ensure_ascii=False))


def main():
    cfg = load()

    root = tk.Tk()
    root.title("WorkGuard — Настройки")
    root.configure(bg="#1e1e1e")
    root.resizable(True, True)

    # Bring window to front
    root.lift()
    root.attributes("-topmost", True)
    root.after(200, lambda: root.attributes("-topmost", False))
    root.focus_force()

    BG = "#1e1e1e"
    FG = "#d4d4d4"
    ACCENT = "#00ff41"
    ENTRY_BG = "#2d2d2d"
    FONT = ("Menlo", 12)

    def lbl(parent, text, **kw):
        return tk.Label(parent, text=text, bg=BG, fg=FG, font=FONT, **kw)

    def entry(parent, var, w=10):
        return tk.Entry(parent, textvariable=var, width=w,
                        bg=ENTRY_BG, fg=FG, font=FONT,
                        insertbackground=FG, relief="flat")

    pad = {"padx": 12, "pady": 6}

    content = tk.Frame(root, bg=BG)
    content.pack(fill="both", expand=True, padx=10, pady=(10, 6))

    # ── Work hours ──
    hours_frame = tk.LabelFrame(content, text="Рабочие часы",
                                bg=BG, fg=ACCENT, font=FONT)
    hours_frame.pack(fill="x", **pad)

    start_var = tk.StringVar(value=cfg.get("work_start", "09:00"))
    end_var = tk.StringVar(value=cfg.get("work_end", "19:00"))

    row = tk.Frame(hours_frame, bg=BG)
    row.pack(fill="x", padx=8, pady=4)
    lbl(row, "С:").pack(side="left")
    entry(row, start_var, 8).pack(side="left", padx=(4, 20))
    lbl(row, "До:").pack(side="left")
    entry(row, end_var, 8).pack(side="left", padx=4)

    # ── Work days ──
    days_frame = tk.LabelFrame(content, text="Рабочие дни",
                               bg=BG, fg=ACCENT, font=FONT)
    days_frame.pack(fill="x", **pad)

    day_names = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    day_vars = []
    row2 = tk.Frame(days_frame, bg=BG)
    row2.pack(padx=8, pady=4)
    work_days = cfg.get("work_days", [1, 2, 3, 4, 5])
    for i, name in enumerate(day_names):
        var = tk.BooleanVar(value=(i + 1) in work_days)
        day_vars.append(var)
        cb = tk.Checkbutton(row2, text=name, variable=var,
                            bg=BG, fg=FG, selectcolor=ENTRY_BG,
                            activebackground=BG, font=FONT)
        cb.pack(side="left", padx=2)

    # ── Intervals ──
    int_frame = tk.LabelFrame(content, text="Интервалы уведомлений",
                              bg=BG, fg=ACCENT, font=FONT)
    int_frame.pack(fill="x", **pad)

    notif_var = tk.IntVar(value=cfg.get("notification_interval_min", 5))
    overlay_var = tk.IntVar(value=cfg.get("overlay_delay_min", 20))
    overlay_lock_initial_var = tk.IntVar(value=cfg.get("overlay_lock_initial_sec", 30))
    overlay_lock_max_var = tk.IntVar(value=cfg.get("overlay_lock_max_sec", 1800))

    for lbl_text, var in [
        ("Пуш каждые N мин:", notif_var),
        ("Оверлей каждые N мин:", overlay_var),
        ("Блок оверлея, старт (сек):", overlay_lock_initial_var),
        ("Блок оверлея, максимум (сек):", overlay_lock_max_var),
    ]:
        r = tk.Frame(int_frame, bg=BG)
        r.pack(fill="x", padx=8, pady=2)
        lbl(r, lbl_text).pack(side="left")
        entry(r, var, 5).pack(side="left", padx=4)

    # ── Save button ──
    def save_and_close():
        try:
            cfg["work_start"] = start_var.get()
            cfg["work_end"] = end_var.get()
            cfg["work_days"] = [i + 1 for i, v in enumerate(day_vars) if v.get()]
            cfg["notification_interval_min"] = notif_var.get()
            cfg["overlay_delay_min"] = overlay_var.get()
            cfg["overlay_lock_initial_sec"] = overlay_lock_initial_var.get()
            cfg["overlay_lock_max_sec"] = max(
                overlay_lock_initial_var.get(),
                overlay_lock_max_var.get(),
            )
            save(cfg)
            messagebox.showinfo("WorkGuard", "Настройки сохранены!")
            root.destroy()
        except Exception as e:
            messagebox.showerror("Ошибка", str(e))

    actions = tk.Frame(root, bg=BG)
    actions.pack(fill="x", padx=12, pady=(4, 12))
    tk.Button(
        actions, text="Сохранить", command=save_and_close,
        bg=ENTRY_BG, fg=ACCENT, font=FONT,
        relief="flat", padx=20, pady=8, cursor="hand2",
    ).pack(side="right")

    root.update_idletasks()
    req_w = root.winfo_reqwidth()
    req_h = root.winfo_reqheight()
    root.minsize(req_w, req_h)
    root.geometry(f"{req_w}x{req_h}")

    root.mainloop()


if __name__ == "__main__":
    main()
