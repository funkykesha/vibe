## Why

OCR/photo extraction can help later, but it is not required for MVP and can corrupt financial data if it writes balances without review. This replacement change keeps OCR/photo and historical import visible as deferred scope with strict confirmation requirements.

## What Changes

- Defer OCR/photo extraction from MVP implementation.
- Defer historical import tooling from the core snapshot workflow.
- Define future OCR/photo behavior as candidate extraction only.
- Require manual review and confirmation before any future financial write.
- Allow Telegram/photo surfaces to acknowledge unavailable OCR safely.

## Capabilities

### New Capabilities

- `deferred-ocr-photo-flow`: Deferred OCR/photo and historical import boundaries with manual confirmation safety.

## Impact

- MVP implementation can proceed without OCR.
- Future OCR work must create reviewable candidates, not direct balance writes.
