## Context

Research found OCR is technically plausible but not MVP-critical. Historical spreadsheet import is also feasible only as separate review tooling because converted files are messy and name/category drift is real.

## Decisions

### D1: OCR/photo is deferred

No MVP stage depends on OCR/photo extraction. Bot `/photo` behavior may acknowledge the unavailable feature without changing data.

### D2: Future OCR creates candidates

OCR/photo extraction may produce candidate account balances or imported rows, but not committed financial state.

### D3: Manual confirmation is mandatory

Every future OCR or historical import write SHALL require explicit user review and confirmation.

### D4: Historical import is separate tooling

Existing historical documents may become reviewable snapshot/event candidates later. App-created snapshots must work without them.

## Evidence

- Archived research `03-mini-spikes-and-context7.md` section 3.8: OpenAI image input and structured outputs are viable later; MarkItDown is more document-oriented; confirmation is required.
- Archived research section 3.12: historical import files contain repeated headers, `NaN`, mixed sections, derived totals, and name/category drift.
- Decision log D5: keep OCR outside MVP.

## Handoff

Entry criteria:
- MVP planning needs an explicit boundary for OCR/photo and historical import.

Exit criteria:
- MVP stages do not depend on OCR or imported history.
- Future OCR/import proposals have a safety contract requiring candidate review and confirmation before writes.
