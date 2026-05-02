## Why

Telegram is the fast mobile surface for the single-user finance ritual. The old broad changes mixed bot behavior with provider sync and deployment webhooks; this change keeps local polling assistant behavior, authorization boundary, manual writes, snapshots, and shared-state visibility.

## What Changes

- Add local polling Telegram assistant for the authorized user.
- Add `/summary`, safe manual `/update`, and `/snapshot`.
- Require confirmations before manual financial writes.
- Keep webhook deployment in `deployment-readiness`.

## Capabilities

### New Capabilities

- `telegram-finance-assistant`: Local polling Telegram assistant commands over shared finance state.

## Impact

- Requires backend foundation for shared state.
- Snapshot command depends on `salary-events-snapshots`.
- Provider refresh commands are owned by `tbank-account-sync` or a later bot-trigger stage.
