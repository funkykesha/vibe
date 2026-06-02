## Context

The Todoist reminder overlay (`todoist_overlay.py`) runs as a separate PyObjC subprocess (main-thread compliance, design decision D4 in the archived change). It receives a `dashboard` dict produced by `TodoistApiClient.dashboard()` (`todoist_signals.py`) and persisted/restored across restarts by `EngagementMonitor` (`engagement_monitor.py`). Today it renders one centered green monospace text block via `_dashboard_lines`, with fixed fractional `NSMakeRect` positions identical on every monitor.

This redesign keeps the subprocess/stdin/JSON-result contract and the three-signal engagement logic untouched. It only changes (a) the dashboard data shape, (b) the rendering, and (c) the persisted snapshot shape. No network, config-file, or privacy-boundary change.

Approved product decisions (from explore):
- Filter: only tasks with a due date; undated excluded and counted.
- All four priorities listed (not p1/p2 only).
- Priority = explicit columns/sections, Todoist colors, per-section counter footer.
- Per-task relative due label; overdue dates red (Todoist convention).
- Two-tier width-responsive layout; per-section cap dynamic (fits screen height).

## Goals / Non-Goals

**Goals:**
- Deadline-first dashboard: every shown row carries a due date; sorted ascending within its priority.
- Unambiguous priority structure via colored column-sections + footers.
- Layout adapts to monitor width (2 tiers) and to monitor height (dynamic row cap).
- Self-contained rendering math (absolute pixel pitch) so bigger screens show more rows automatically.

**Non-Goals:**
- No change to engagement detection, signals, cadence, or the two action buttons.
- No clickable/interactive tasks (overlay stays non-interactive per spec).
- No new config keys, no API changes, no per-task time-zone handling beyond existing `_parse_iso`.
- No mid-resolution live re-layout (overlay is built once per show; monitor hot-plug not handled).

## Decisions

### D1 — New `dashboard()` output shape
Replace flat shape with per-priority dated structure:

```python
{
  "columns": {
    "p1": [ {"content": str, "due_label": str, "overdue": bool, "due_sort": "YYYY-MM-DDTHH:MM"} , ... ],
    "p2": [...], "p3": [...], "p4": [...],
  },
  "counts": {
    "p1": {"dated": int, "overdue": int, "undated_hidden": int},
    "p2": {...}, "p3": {...}, "p4": {...},
  },
}
```

- Priority keys map from REST priority ints (4→p1, 3→p2, 2→p3, 1→p4).
- A task enters a `columns[pX]` list only if it has `due.date` or `due.datetime`; else it increments `counts[pX].undated_hidden`.
- Each list sorted by `due_sort` ascending (overdue first, then nearest).
- `overflow` is NOT precomputed by the producer — the renderer decides the cap from screen geometry, so producer returns the FULL dated list and the renderer slices it. Cap-related fields dropped from the data model. (Alternative: producer caps — rejected because the producer can't know per-monitor section height.)

### D2 — Relative due label (`due_label`)
Computed in the producer from `due` vs `today`/`now` (local):
- past date → `просрочено Nд` (N≥1), uniform — no `вчера`/`N дней назад` aliases; `overdue=True`. (Resolves the 3-way label conflict: design/spec wording wins; the prototype's `2 дня назад` / `вчера` are corrected to match. Uniform form keeps the producer simple and the truncation width predictable.)
- today → `сегодня` (+ ` HH:MM` if `due.datetime` present).
- tomorrow → `завтра` (+ ` HH:MM` if `due.datetime` present).
- 2–6 days ahead → russian weekday short + day-of-month: `Пн 12`.
- ≥7 days → day + russian month short: `23 июн`.
Russian weekday/month tables are static module constants. Producer-side so the renderer stays pure layout.

### D3 — Priority colors (Todoist palette) + red overdue
Calibrated RGB constants in the renderer (validated against the HTML prototype `docs/design/todoist-overlay-prototype.html`):
- p1 red `#D1453B` → (0.82, 0.27, 0.23)
- p2 orange `#EB8909` → (0.92, 0.54, 0.04)
- p3 blue `#246FE0` → (0.14, 0.44, 0.88)
- p4 gray `#7D7D7D` → (0.49, 0.49, 0.49)
- overdue label red `#FF6B5E` → (1.00, 0.42, 0.37) — Todoist red lifted for legibility on the dark panel
- today label uses p2 orange (a due-today task reads as "act now")

Surface/ink tokens (dark "terminal" base):
- panel bg `#1C1C1C` → (0.11, 0.11, 0.11); screen backdrop `#141414` → (0.08, 0.08, 0.08)
- task-card bg `#242424` → (0.14, 0.14, 0.14); hairline `#313131` → (0.19, 0.19, 0.19)
- primary text `#F2F1EC` (warm off-white) → (0.95, 0.95, 0.93); secondary `#6F6E69` → (0.44, 0.43, 0.41)

Font: SF Mono → Menlo via `NSFont(name:)` fallback; ship NO bundled font (both are macOS system fonts — no licensing/bundle weight). The prototype's JetBrains Mono is web-preview only and is not a render target. Text widths are measured at runtime (see Risks), so the font swap costs no calibration.

Priority accent appears three ways per section: a colored flag bar at the section header, the `PX` level token in the accent color, and a filled priority dot `●` on each task row (p4 dot is a hollow ring, not filled). Task content is near-white; the `due_label` token is secondary-gray normally, overdue-red when `overdue`, orange when due today.

### D4 — Two-tier width-responsive packing
Per `screen.frame().size.width` (`W`). The two tiers differ in BOTH column count and in how p3/p4 are presented (revised after the prototype review):

- **Tier 1, `W < 2560` (laptop / compact monitor)**: `n_cols = 2`.
  - Left column: **P1 full task list** (header + dated rows + per-section stat).
  - Right column: **P2 full task list** (same), stacked above two **count-cards** for P3 and P4.
  - P3/P4 are NOT listed task-by-task here — each is a single compact count-card (see D8): accent flag, `PX · <name>`, a sub-line `просрочено O · без даты U`, and a large task count (`N задач`). Rationale: a laptop column can't show four full lists legibly; the high-priority work gets the rows, the low-priority load is conveyed as a number.
- **Tier 2, `W ≥ 2560` (wide / external monitor)**: `n_cols = 4`, `sections_per_col = 1`. One priority per column, P1→P4 left to right, **all four as full task lists** with per-section stat footers.

Threshold `2560` is an inclusive module constant `WIDE_TIER_MIN_WIDTH`: a 2560×1440 external display gets the wide 4-column tier. (Alternatives rejected: 3 tiers — user wants 2 only; tier-1 four-full-lists — illegible in a laptop column, hence the count-card treatment for p3/p4.)

### D5 — Layout proportions (APPROVED via prototype)
Validated visually in `docs/design/todoist-overlay-prototype.html` (both tiers). The overlay paints a dark full-screen backdrop and centers a single rounded **panel** that holds the headline, the grid, and the actions — content is not stretched edge-to-edge. All vertical bands below are relative to the panel; row pitch stays absolute px so taller panels fit more rows.

Panel: centered, width `min(0.92W, 1180px)` in tier 1 and `min(0.96W, 2200px)` in tier 2; corner radius ~16px; 1px hairline border; subtle drop shadow. The wider tier-2 cap keeps 2560×1440 displays from feeling cramped.

Panel zones (top → bottom):
| Zone | Content |
|------|---------|
| Header band | eyebrow `напоминание · todoist`, headline message (accent on the verb phrase), clock line `HH:MM, DD <month> YYYY` |
| Grid area | priority sections / count-cards |
| Actions row | two buttons, **centered** (not split left/right) |

Grid horizontal: column gutter ~22px; tier 1 = 2 equal columns, tier 2 = 4 equal columns. `col_width = (panel_inner_w − (n_cols−1)·gutter) / n_cols`.

Section box (within a column):
- Tier 1 left column: P1 fills the column height.
- Tier 1 right column: P2 list on top; remaining height holds the P3 and P4 count-cards (fixed height each, see D8).
- Tier 2: each section fills its column.

Section internal (absolute px):
| Element | Size |
|---------|------|
| Header (flag + `PX · name` + right-aligned count) | `HEADER_H = 40px` |
| Stat footer | `FOOTER_H = 30px` |
| Row pitch (task card incl. gap) | `ROW_H = 46px` |
| Rows region | `section_height − HEADER_H − FOOTER_H` |

Dynamic cap: `cap = floor(rows_region / ROW_H)`, min 1.
If `len(tasks) > cap`: show `cap − 1` rows + final `└─ ещё N` line (`N = len − (cap−1)`). Else show all.

Section header right-aligned count shows the dated total (e.g. `3 / 4` when capped, else `2`). Stat footer per section shows `просрочено O · без даты U` (from `counts[pX]`; the dated total already lives in the header). Per the prototype review the per-section stat replaces the single global footer.

Fonts — SF Mono preferred, Menlo fallback (`NSFont` name `"SF Mono"` then `"Menlo"`): headline ~27 bold, eyebrow 12, section header 13 bold, task name ~14 medium, project sub-line 11, due label 12, stat footer 12, count-card number ~30 bold, clock 13.

### D6 — Producer/renderer split
Producer (`dashboard()`) = pure data: filter, group, sort, label, count. Renderer (`_run_overlay`) = pure layout: tier, geometry, slice-to-cap, color. This keeps the cap dynamic per monitor and the producer unit-testable without AppKit.

### D7 — Persisted snapshot compatibility
`EngagementMonitor` serializes the last dashboard to disk. On restore, a pre-redesign dashboard has the old shape (`p1p2`/`p3_count`). Mitigation: the renderer treats a dashboard lacking the `columns` key as empty (renders headline + buttons only, no task block) and `EngagementMonitor` discards a restored dashboard missing `columns`. First post-upgrade refresh repopulates the new shape. No version bump needed.

### D8 — Visual treatment ("Todoist-in-terminal")
Refined from the prototype. Keeps a monospace/terminal soul but reads like a Todoist surface, not a raw text dump.

- **Task row = card**, not a line of text: rounded-rect fill (`#242424`), priority dot `●` on the left (hollow ring for p4), task content (near-white, single line, ellipsis-truncated to `col_width`), optional `# <project>` sub-line in secondary gray, and the `due_label` right-aligned (overdue-red / today-orange / neutral-gray).
- **Section** = bordered rounded box: header strip (colored flag bar + `PX · <name>` with the level token in accent color + right-aligned dated count) over the rows region over the dashed-top stat footer.
- **Count-card** (tier-1 p3/p4): a single card the width of the column — accent flag bar, `PX · <name>` with a `просрочено O · без даты U` sub-line, and a large right-aligned task count (`N задач`, grammatical plural). No task rows. Fixed height (~64px).
- **Header**: small uppercase eyebrow `напоминание · todoist`, the reminder message as the headline with the active phrase in p1-red, then the clock line. A small `WORK·GUARD ENGAGEMENT` tag sits in the panel's top-right; `● ● ●` "window dots" in the top-left — terminal framing.
- **Actions**: primary button = p1-red filled (`Перейти в Todoist →`), secondary = ghost/outline (`Свернуть оверлей`); both centered in the actions row.
- **Atmosphere** (best-effort in AppKit; degrade gracefully): faint radial glows top/bottom, hairline separators, soft shadow on the panel. These are decorative — correctness of the dashboard never depends on them.

The HTML prototype `docs/design/todoist-overlay-prototype.html` is the visual source of truth for spacing, color, and the two tier layouts; the PyObjC renderer ports it. Caveat: the prototype is CSS auto-height — it validates skin (colors, card style, tier structure, footers), NOT the vertical packing math. The packing rule lives in D9, not the prototype.

### D9 — Panel is screen-height; vertical budget drives the cap
The prototype lets the panel hug its content (CSS grid), so the dynamic cap never runs there. The real overlay does the opposite: the panel claims a **fixed share of screen height**, and sections cap rows to fit. This makes "a taller monitor shows more rows" true (D5 intent) and resolves the tier-1 right-column overflow precedence.

Vertical budget (top → bottom), screen points from `screen.frame().size.height` (`H`):

```
PANEL_MARGIN_V  = 64       # screen-edge → panel, top and bottom
panel_h = H − 2·PANEL_MARGIN_V                  # panel fills screen vertically (no max; bigger screen ⇒ more rows)
grid_h  = panel_h − PANEL_PAD_TOP(30) − HEADER_BAND_H(120) − ACTIONS_BAND_H(92) − PANEL_PAD_BOTTOM(26)
```

- `HEADER_BAND_H = 120` = eyebrow + headline + clock + gaps; `ACTIONS_BAND_H = 92` = dashed separator + centered button row.
- Each grid column gets the full `grid_h`.

Per-column section height:
- **Tier 2** (4 cols, 1 section each): `section_h = grid_h`.
- **Tier 1 left** (P1): `section_h = grid_h`.
- **Tier 1 right** (P2 list + P3 + P4 cards stacked): **count-cards reserve their height first**, P2 takes the remainder:
  ```
  COUNTCARD_H = 64
  p2_section_h = grid_h − 2·COUNTCARD_H − 2·gutter(22)
  ```
  Fixes Thread D: in the narrow tier P3/P4 cards are never pushed off-screen; the P2 list flexes and caps to the leftover height. If `p2_section_h` is below one row, P2 cap forces to 1 (per global `cap ≥ 1`).

Within any section: `rows_region = section_h − HEADER_H(40) − FOOTER_H(30)`, `cap = max(1, floor(rows_region / ROW_H(46)))`.

(Rejected: content-height panel — kills the "more rows on taller screen" goal, leaves cap undefined; P2-flexes-cards-shrink — count-cards are a fixed compact treatment, shrinking defeats them.)

## Risks / Trade-offs

- **Stale-shape persisted snapshot after upgrade** → renderer + monitor guard on `columns` key; degrade to headline-only until next refresh.
- **Content overflow in narrow columns** (long task text) → truncate with ellipsis to `col_width` measured at RENDER time via `NSString.sizeWithAttributes:` / `NSAttributedString` bounding width in the actual `NSFont`, NOT a static per-font character budget. The prototype uses JetBrains Mono (a web font absent on macOS); the renderer uses SF Mono → Menlo (D3), whose glyph advance differs, so a char-count budget calibrated on the prototype would be wrong. Runtime measurement is font-agnostic and exact.
- **Very short monitors** (cap → 0 or 1) → enforce `cap ≥ 1`; if 1 and overflow, show only `…ещё N`. Acceptable edge.
- **Dynamic cap drops low-priority/far-future tasks silently** → footer `всего D` shows the true dated count per section, so nothing hidden is invisible.
- **2560 threshold misclassifies a wide external monitor as compact** → resolved by treating `WIDE_TIER_MIN_WIDTH` as inclusive; 2560×1440 now gets tier 2.

## Migration Plan

1. Land producer (`dashboard()`) new shape + russian label tables + unit tests.
2. Update `EngagementMonitor` serialize/restore guards.
3. Replace renderer in `todoist_overlay.py`.
4. Rebuild via `bash rebuild.sh`; verify on laptop (tier 1) and external/wide (tier 2) monitor.
Rollback: revert the three files together (shape is internal, no persisted migration to undo beyond the discard-on-missing-key guard, which is forward-safe).

## Open Questions

- ~~Approve D5 proportions/pitch constants~~ — RESOLVED for the *horizontal/skin* dimension via the HTML prototype. The *vertical* packing the prototype could not validate (CSS auto-height) is now specified in D9, not "approved by prototype". Pixel pitch (`ROW_H` etc.) may still be fine-tuned during the PyObjC port on a real monitor.
- ~~Overdue label wording (3-way conflict)~~ — RESOLVED in D2: uniform `просрочено Nд`; prototype text corrected.
- ~~Font / truncation budget mismatch~~ — RESOLVED in D3 + Risks: SF Mono → Menlo, no bundled font, runtime text measurement instead of a static char budget.
- ~~`due_label` for tasks with a time component — `HH:MM` only for `сегодня`/`завтра`, or always?~~ — RESOLVED (variant A): show `HH:MM` only on `сегодня`/`завтра`; dated labels further out (`Пн 12`, `23 июн`) omit the time. Time matters only when the deadline is near.
- AppKit fidelity of D8 atmosphere (radial glow, grain): port as far as `NSView`/`CALayer` allows; drop purely-decorative effects that aren't worth the complexity without blocking the redesign.
