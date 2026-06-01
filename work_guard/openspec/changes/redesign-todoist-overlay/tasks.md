## 1. Producer: new dashboard data shape

- [x] 1.1 Add russian weekday-short and month-short constant tables to `todoist_signals.py`
- [x] 1.2 Add a `_due_label(due, now)` helper returning `(label: str, overdue: bool, due_sort: str)` per design D2 (просрочено Nд / сегодня[+HH:MM] / завтра / weekday+day / day+month)
- [x] 1.3 Rewrite `TodoistApiClient.dashboard()` to the D1 shape: `columns` (p1–p4 lists of `{content, due_label, overdue, due_sort}`) + `counts` (per-priority `{dated, overdue, undated_hidden}`)
- [x] 1.4 Filter to dated tasks only; tally undated into `counts[pX].undated_hidden`; drop the old cap/overflow precompute (renderer slices)
- [x] 1.5 Sort each priority list by `due_sort` ascending (overdue first)
- [x] 1.6 Map REST priority ints to p1–p4 keys (4→p1, 3→p2, 2→p3, 1→p4)

## 2. Snapshot persistence compatibility

- [x] 2.1 In `engagement_monitor.py`, on restore discard a persisted dashboard missing the `columns` key (D7)
- [x] 2.2 Confirm serialize path stores the new shape unchanged; update `task_list_cap` usage (no longer a producer cap — renderer-driven)

## 3. Renderer: responsive priority-column overlay

Visual reference: `docs/design/todoist-overlay-prototype.html` (port both tiers).

- [ ] 3.1 Add priority/overdue/today + surface/ink color constants (D3) to `todoist_overlay.py`; set font to SF Mono with Menlo fallback
- [ ] 3.2 Add `WIDE_TIER_MIN_WIDTH = 2560` and layout constants `HEADER_H=40 / FOOTER_H=30 / ROW_H=46`, panel width caps, gutter; plus the D9 vertical-budget constants `PANEL_MARGIN_V=64 / PANEL_PAD_TOP=30 / PANEL_PAD_BOTTOM=26 / HEADER_BAND_H=120 / ACTIONS_BAND_H=92 / COUNTCARD_H=64` (D5/D9)
- [ ] 3.3 Paint dark backdrop + centered rounded panel (header band / grid / centered actions); add eyebrow, accented headline, clock, and the terminal framing (window dots, WORK·GUARD tag) (D5/D8)
- [ ] 3.4 Implement tier selection from `screen.frame().size.width`: tier 1 = 2 cols (p1 left full, p2 right full + p3/p4 count-cards), tier 2 = 4 cols (all full) (D4)
- [ ] 3.5 Compute vertical budget from `screen.frame().size.height`: `panel_h → grid_h → section_h` per tier; tier-1 right column reserves `2·COUNTCARD_H + 2·gutter` first, P2 list takes remainder (D9). Then panel inner rect, column rects, section rects.
- [ ] 3.6 Implement full-list section rendering: header (accent flag + `PX · name` + dated count), task cards (dot/ring, content truncated to `col_width` via runtime `NSString.sizeWithAttributes:` in the actual font — not a char budget, `# project` sub-line, due label colored by overdue/today/neutral), `└─ ещё N` overflow line, stat footer `просрочено O · без даты U` (D8)
- [ ] 3.7 Implement count-card rendering for tier-1 p3/p4: accent flag, `PX · name`, `просрочено O · без даты U` sub-line, large `N задач(и/а)` count with grammatical plural (D8)
- [ ] 3.8 Compute dynamic cap `floor(rows_region / ROW_H)` (min 1); slice list; reserve last row for overflow when exceeded
- [ ] 3.9 Replace `_dashboard_lines` + the single-block render in `_run_overlay`; keep subprocess/stdin/result contract; render both buttons centered (primary red `Перейти в Todoist →`, ghost `Свернуть оверлей`)
- [ ] 3.10 Guard: dashboard without `columns` key renders headline + buttons only (D7)

## 4. Verification

- [ ] 4.1 Unit-test `_due_label` boundaries (overdue / today / tomorrow / 2–6d / ≥7d) and `dashboard()` shape, filtering, sorting, counts
- [ ] 4.2 `bash rebuild.sh`, trigger overlay on a tier-1 monitor (laptop, ≤2560px) — verify 2 columns (p1 left, p2 right), p3/p4 count-cards, colors, due labels, red overdue / orange today, stat footers, overflow, centered buttons
- [ ] 4.3 Trigger overlay on a tier-2 monitor (>2560px) — verify 4 single-priority full-list columns and that a taller screen shows more rows
- [ ] 4.4 Verify post-upgrade restore with an old-shape persisted snapshot degrades to headline-only, then repopulates on next refresh
