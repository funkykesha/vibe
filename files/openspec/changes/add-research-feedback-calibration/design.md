## Context

`research-pipeline` collects findings, dedupes them, enriches them through Eliza, and writes markdown notes into the user's Obsidian vault. Current ranking uses `config.enrich.contextSummary` plus the model's judgment for each individual item. The user can read the generated notes later, but the pipeline does not capture whether the item was actually worth taking.

The interaction must work in Obsidian Reading view without additional plugins. Native markdown task checkboxes satisfy this constraint and persist directly in the note body.

Current note state is implicit:

```text
Research/Processed/
  new and already-reviewed notes mixed together
```

Target note state is explicit:

```text
Research/Processed/  unread queue
Research/Taken/      read and useful
Research/Skipped/    read and not useful
```

## Goals / Non-Goals

**Goals:**

- Add Obsidian-native clickable feedback controls to generated notes.
- Preserve unread notes as neutral; they MUST NOT become negative feedback.
- Move reviewed notes into outcome-specific folders.
- Use reviewed outcomes to calibrate future enrichment prompts.
- Keep duplicate detection aware of all research note folders.
- Keep the implementation dependency-free.

**Non-Goals:**

- Train or fine-tune a model.
- Add a custom Obsidian plugin.
- Build a UI beyond native markdown checkboxes.
- Re-enrich all existing notes automatically.
- Treat every unchecked note as a negative signal.

## Decisions

### Use body checkboxes instead of frontmatter values

Generated notes will include:

```md
## Мой сигнал
- [ ] Прочитал
- [ ] Взял
```

Rationale: native Obsidian task checkboxes are clickable in Reading view and require no plugin. A frontmatter select would need a plugin such as Meta Bind, and plain YAML is less ergonomic in Reading view.

Alternative considered: one checkbox `Беру`. This was rejected because unchecked would be ambiguous between "not reviewed" and "reviewed but not taken".

### Use folder location as reviewed state

`Research/Processed/` remains the active unread queue. `run` will move notes based on checkbox state:

```text
Прочитал = false, Взял = false -> stay in Processed
Прочитал = true,  Взял = false -> move to Skipped
Прочитал = true,  Взял = true  -> move to Taken
Прочитал = false, Взял = true  -> stay in Processed; taken is ignored until read
```

Rationale: folder state is simple to inspect in Obsidian and keeps the active queue clean. `Прочитал` is the authoritative review boundary: no note moves or affects calibration until it is marked read. It also gives the pipeline a cheap calibration corpus: `Taken` is positive, `Skipped` is negative.

Alternative considered: keep all notes in `Processed` and rely only on checkboxes. This keeps implementation smaller but leaves the queue noisy and makes reviewed state less visible.

### Scan all outcome folders for keys and feedback

Duplicate detection will load existing keys from `Processed`, `Taken`, and `Skipped`. Feedback extraction will scan `Taken` and `Skipped`, and may also scan reviewed notes still in `Processed` before moving them.

Rationale: moving files must not cause old items to be reprocessed as new. Feedback should survive after notes leave the active queue.

### Pass compact calibration context into enrichment

Before enriching new items, `run` will summarize reviewed notes into a bounded calibration block. The block will favor compact fields already present in the note:

- title
- category
- tags
- original applicability score
- short TL;DR
- outcome: taken or skipped

The prompt will tell the model to use these examples to calibrate `applicability_score` and `try_now`, while still judging each new item on its own content.

Rationale: this is simple and keeps the scoring behavior current without new persistence or model training.

### Keep digest focused on active queue

The main digest should list only active unreviewed notes from `Research/Processed/`. Reviewed notes are available in `Taken` and `Skipped` folders and should not crowd the triage digest.

Rationale: the digest is a work queue. Reviewed archives should be separate unless a later change adds historical reports.

### Route reviewed notes during digest-only regeneration

The `digest` command will route reviewed notes before regenerating the digest, without running fetch or enrichment. This keeps the digest command useful as a queue maintenance action after the user reviews notes in Obsidian.

Rationale: checkbox review happens outside the pipeline. If digest regeneration does not route first, reviewed notes would remain visible until the next full `run`, making the digest stale.

### Provide one-time checkbox migration for old notes

Older generated notes in `Research/Processed/` will be eligible for a one-time migration command that inserts the `## Мой сигнал` section when it is missing. The migration will not infer feedback, move notes, or re-enrich content; it only adds unchecked review controls.

Rationale: old notes should join the same review workflow without requiring manual edits or full reprocessing. Keeping the migration additive avoids accidentally converting unread historical notes into negative examples.

## Risks / Trade-offs

- Checkbox parsing can be brittle if labels are edited manually -> match a small set of accepted Russian labels and document the generated format.
- `Взял` without `Прочитал` is inconsistent -> keep the note in `Processed` and ignore it for calibration until `Прочитал` is checked.
- Large feedback history can bloat prompts -> cap examples by recency and count for positive and negative examples.
- Moving files can overwrite same-name files -> use existing filename when moving; if a collision exists, append a numeric suffix.
- Older generated notes lack checkboxes -> treat them as unreviewed until the migration command adds the section.
- Calibration may overfit to a small number of examples -> include both positive and negative examples only when available, and keep static context in the prompt.

## Migration Plan

1. Add configurable research outcome folders with defaults:
   - `Research/Processed`
   - `Research/Taken`
   - `Research/Skipped`
2. Generate feedback checkboxes in new notes.
3. Add readers for frontmatter, TL;DR, checkbox state, and existing keys across all outcome folders.
4. Add reviewed-note routing at the start of `run` and before digest regeneration.
5. Add a one-time migration command that inserts missing feedback checkboxes into old processed notes without moving or re-enriching them.
6. Add calibration summary generation and pass it into enrichment.
7. Update README with the feedback workflow.

Rollback: disable routing/calibration calls in `run`. Existing notes remain valid markdown; moved notes can be manually moved back to `Research/Processed/` if needed.
