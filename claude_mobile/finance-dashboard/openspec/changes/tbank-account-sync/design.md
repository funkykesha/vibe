## Context

Context7 did not provide suitable personal TBank mobile API docs. Archived research used local `tbank-mobile-api` source/docs and public repository evidence with medium confidence.

## Decisions

### D1: Adapter isolation is mandatory

All unofficial TBank behavior SHALL live behind a provider adapter. Backend routes, bot commands, and mapping logic use normalized provider account data.

### D2: Mapping state is first-class

Provider account mapping SHALL use explicit states and transitions, not ad hoc name matching.

### D3: Provider IDs require user confirmation

Provider ID mappings become write-eligible only after the user confirms the internal account match.

### D4: Live sync writes are gated

Before provider balances can update app accounts, the implementation must pass mocked adapter contract tests and a live local account fetch against the user's account.

### D5: No silent financial changes

Unmapped, ambiguous, stale, conflict, hidden, external/no-balance, currency mismatch, or type mismatch cases SHALL NOT update balances silently.

## Evidence

- Archived research `03-mini-spikes-and-context7.md` section 3.3: fallback `tbank-mobile-api` source is unofficial, medium confidence, supports account list and storage but can break.
- Archived research section 3.4: mapping states and safety rules.
- Archived research section 3.2: HTTPX explicit timeouts and provider error handling.

## Handoff

Entry criteria:
- `backend-foundation` has account persistence and config.
- Account mapping storage shape is approved.

Exit criteria:
- Mocked adapter tests prove normalized behavior.
- Live local account fetch has been performed before live writes are enabled.
- Any future bot-triggered or dashboard sync action can depend on confirmed mappings only.
