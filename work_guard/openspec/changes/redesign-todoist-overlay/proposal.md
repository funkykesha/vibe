## Why

The current Todoist reminder overlay renders a single flat green text block: priority p1/p2 tasks only, no due dates, bare p3/p4/overdue counters, and one fixed layout stretched by fractional positioning across any monitor. It is hard to scan, hides deadlines, blurs priority boundaries, and ignores screen size. The user wants a deadline-driven, priority-structured, screen-adaptive dashboard.

## What Changes

- **BREAKING** (internal data contract): `dashboard()` output shape changes from flat `{p1p2, p1p2_overflow, p3_count, p4_count, overdue}` to per-priority dated columns `{columns, overflow, counts}`. Producer (`todoist_signals.py`), consumer (`todoist_overlay.py`), and the persisted snapshot in `engagement_monitor.py` change together.
- Dashboard lists **only tasks that have a due date**; undated tasks are excluded and tallied as `undated_hidden` per priority.
- All four priorities (p1–p4) are surfaced. Presentation is tier-dependent: on a wide monitor every priority is a full task list; on a laptop p1/p2 are full lists while p3/p4 collapse to compact count-cards (see layout below).
- Each task row shows a **relative due label** (`просрочено 3д / сегодня / завтра / Пн 12 / 23 июн`); overdue dates are colored red and due-today orange, mirroring Todoist.
- Priorities become **explicit visual columns/sections** with Todoist priority colors (p1 red, p2 orange, p3 blue, p4 gray), each a bordered card box with an accent flag, a header count, and a per-section stat footer.
- Tasks within a section are **sorted by due date ascending** (most urgent on top).
- **Two-tier responsive layout** driven by `screen.frame().width`: tier 1 (≤ 2560px) = two columns — p1 list left, p2 list + p3/p4 count-cards right; tier 2 (> 2560px) = four columns, one full priority list each.
- Per-section task **cap is dynamic** — computed from available section height and a fixed row pitch — with a `…ещё N` overflow indicator.
- **Visual redesign** ("Todoist-in-terminal"): monospace type (SF Mono / Menlo) on a dark panel, task rows as rounded cards with a priority dot, centered action buttons, terminal framing. Visual source of truth: `docs/design/todoist-overlay-prototype.html`.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `todoist-engagement-reminder`: the "Reminder overlay presents a non-interactive task dashboard" requirement changes — dated-only task selection across all four priorities, per-task due labels with red overdue, card-based priority sections with per-section counters, a two-tier width-responsive layout (narrow tier collapses p3/p4 to count-cards), and centered action buttons.

## Impact

- `todoist_signals.py` — `TodoistApiClient.dashboard()` rewritten to the new shape (due filter, per-priority grouping, relative labels, overdue flag, dynamic-cap inputs).
- `todoist_overlay.py` — `_dashboard_lines` / `_run_overlay` replaced with column-section rendering, width-tier selection, dynamic cap from section height, priority colors, red overdue.
- `engagement_monitor.py` — persisted snapshot dashboard shape + `task_list_cap` semantics (now per-section/dynamic) updated; serialize/restore stay shape-compatible.
- `work_guard.py` — `dashboard()` call site unchanged in signature; only payload shape differs (no API change).
- No external API, network, or config-file schema change. Privacy/activity boundaries untouched.
