## Why

The replacement roadmap needs a product contract before implementation stages add backend, bot, provider, or deployment behavior. The old broad product change mixed product meaning with implementation concerns; this change keeps only the shared meaning every later stage must preserve.

## What Changes

- Define the finance product around recurring rituals: salary day, quick capital refresh, progress check, and model maintenance.
- Define the dashboard and Telegram assistant as complementary surfaces over the same financial state.
- Establish the shared source-of-truth concepts: accounts, settings, salary events, explicit snapshots, and provider mappings.
- Clarify single-user boundaries without introducing a multi-user account system.
- Define salary event and snapshot semantics for later API and UX stages.

## Capabilities

### New Capabilities

- `finance-product-contract`: Product-level contract for rituals, shared state, surface responsibilities, and financial checkpoint semantics.

## Impact

- Later changes must preserve this product contract when implementing UX, backend APIs, bot commands, snapshots, provider sync, and deployment.
- This change does not modify production app code.
