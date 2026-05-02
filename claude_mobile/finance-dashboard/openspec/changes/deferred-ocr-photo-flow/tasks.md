## 1. Deferred Boundaries

- [ ] 1.1 Keep OCR/photo out of MVP task dependencies.
- [ ] 1.2 Keep historical spreadsheet import out of core snapshot implementation.
- [ ] 1.3 Ensure bot/photo placeholders do not write financial data.

## 2. Future Safety Contract

- [ ] 2.1 Define future OCR output as reviewable candidates.
- [ ] 2.2 Require explicit user confirmation before any candidate becomes a financial write.
- [ ] 2.3 Preserve original source reference for future audit/review.

## 3. Verification

Entry criteria:
- MVP roadmap has isolated product, UX, backend, dashboard migration, salary/snapshot, Telegram, TBank, and deployment stages.
- Archived OCR and historical import evidence is available for future planning.

Exit criteria:
- OCR/photo and historical import remain visible but do not block MVP implementation.
- Any future extraction output is reviewable and cannot write balances without explicit confirmation.

- [ ] 3.1 Verify MVP changes do not require OCR libraries or LLM vision credentials.
- [ ] 3.2 Verify app-created snapshots work without historical import.
- [ ] 3.3 Run `openspec status --change "deferred-ocr-photo-flow"`.
