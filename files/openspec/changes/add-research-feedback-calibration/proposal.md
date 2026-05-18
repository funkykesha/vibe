## Why

The research pipeline currently ranks new findings only from static context and model judgment. It does not learn from the user's later decision that a processed item was actually useful, so future `applicability_score` values can drift away from the user's real preferences.

This change adds lightweight Obsidian-native feedback: the user can click "Прочитал" and "Взял" checkboxes in Reading view, and future runs use those marked notes as calibration examples.

## What Changes

- Add two native markdown checkboxes to each processed research note:
  - `Прочитал`
  - `Взял`
- Treat `Прочитал + Взял` as a positive calibration signal.
- Treat `Прочитал + not Взял` as a negative calibration signal.
- Treat unread notes as unreviewed and exclude them from calibration, even if `Взял` is checked.
- Move reviewed notes out of the active processed queue:
  - read and taken notes go to `Research/Taken/`
  - read and not taken notes go to `Research/Skipped/`
  - unread notes stay in `Research/Processed/`
- Update duplicate detection and digest generation to account for `Processed`, `Taken`, and `Skipped`.
- Include summarized feedback examples in enrichment prompts so new items receive more current applicability scores.
- No plugin dependency is introduced; the interaction uses Obsidian's native task checkbox behavior.

## Capabilities

### New Capabilities

- `research-feedback-calibration`: Covers Obsidian-clickable review controls, reviewed-note routing, calibration extraction, and scoring prompt feedback for research items.

### Modified Capabilities

None.

## Impact

- Affected code:
  - `research-pipeline/writer.js`
  - `research-pipeline/enrich.js`
  - `research-pipeline/index.js`
  - `research-pipeline/config.js`
  - `research-pipeline/README.md`
- Affected data in the Obsidian vault:
  - new checkbox section in generated processed notes
  - reviewed notes moved from `Research/Processed/` to `Research/Taken/` or `Research/Skipped/`
- No external API or package dependency changes are expected.
