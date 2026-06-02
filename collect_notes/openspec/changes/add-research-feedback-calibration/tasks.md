## 1. Configuration and Note Utilities

- [ ] 1.1 Add config defaults for `Research/Processed`, `Research/Taken`, and `Research/Skipped`
- [ ] 1.2 Add a shared note directory helper so code can scan active and reviewed research folders consistently
- [ ] 1.3 Add parsing helpers for note frontmatter, TL;DR, tags, score, and `Прочитал` / `Взял` checkbox state
- [ ] 1.4 Add collision-safe move helper for routing reviewed notes between research folders

## 2. Review Controls and Routing

- [ ] 2.1 Update generated note bodies to include the `## Мой сигнал` section with unchecked `Прочитал` and `Взял` checkboxes
- [ ] 2.2 Implement reviewed-note routing from `Processed` to `Taken` or `Skipped`
- [ ] 2.3 Ensure `Прочитал` has routing priority so `Взял`-without-`Прочитал` stays in `Processed` and is excluded from calibration
- [ ] 2.4 Ensure `run` routes reviewed notes before loading duplicate keys and before regenerating the digest
- [ ] 2.5 Ensure `digest` can route reviewed notes before regenerating the digest without running enrichment
- [ ] 2.6 Add a one-time migration command that inserts missing unchecked feedback checkboxes into old processed notes without moving or re-enriching them

## 3. Duplicate Detection and Digest Scope

- [ ] 3.1 Update existing-key loading to scan `Processed`, `Taken`, and `Skipped`
- [ ] 3.2 Keep merge-mode duplicate updates working for notes found in any research outcome folder
- [ ] 3.3 Keep the main digest scoped to active `Processed` notes only

## 4. Calibration Context

- [ ] 4.1 Build bounded positive calibration examples from `Taken` notes
- [ ] 4.2 Build bounded negative calibration examples from `Skipped` notes
- [ ] 4.3 Exclude unread `Processed` notes from calibration
- [ ] 4.4 Pass the calibration summary into `enrichItem`
- [ ] 4.5 Update the enrichment prompt to calibrate `applicability_score` and `try_now` from reviewed examples while preserving per-item judgment

## 5. Documentation and Verification

- [ ] 5.1 Document the `Прочитал` / `Взял` workflow and folder meanings in `research-pipeline/README.md`
- [ ] 5.2 Document the old-note checkbox migration command and its additive-only behavior
- [ ] 5.3 Verify generated markdown contains native clickable Obsidian task syntax
- [ ] 5.4 Verify migration adds unchecked controls to old processed notes without changing reviewed state
- [ ] 5.5 Verify reviewed notes move to `Taken` / `Skipped` and no longer appear in the digest
- [ ] 5.6 Verify duplicate detection still catches notes after they move out of `Processed`
- [ ] 5.7 Verify enrichment still works when there are zero feedback examples
