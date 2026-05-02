## Why

Current finance planning specs already describe a broad product and automation pipeline, but implementation should not start while key assumptions, external risks, and cross-spec consistency are still unverified. This change defines a research and spec-quality gate that must produce clear decisions before the pipeline is rebuilt.

## What Changes

- Introduce a pre-implementation research gate that covers every currently planned stage, including configuration, backend, dashboard migration, TBank sync, Telegram bot, history, salary events, OCR, deployment, and product design system readiness.
- Add explicit mini spikes for risks that can change architecture or stage ordering.
- Require Context7-backed documentation checks for external libraries, frameworks, APIs, and hosting platforms used in research decisions.
- Add a spec audit pass across `finance-product-rituals`, `finance-automation-system`, and `finance-product-design-system` to find mismatches, missing contracts, unsafe assumptions, and design/implementation gaps.
- Require a decision log with a `keep`, `change`, `split`, or `drop` verdict for each stage before roadmap rewrite.
- Require roadmap impact notes that explain how research findings should reshape the next implementation changes.
- Treat `finance-product-design-system` as an audited input and feed any findings back into the rebuilt roadmap.

## Capabilities

### New Capabilities

- `research-quality-gate`: Defines the required research, spec audit, decision log, and roadmap impact outputs before implementation resumes.

### Modified Capabilities

None. This change adds a meta-level quality gate and does not directly change the product requirements of existing capabilities.

## Impact

- OpenSpec planning: blocks implementation-oriented changes until research verdicts and audit findings are complete.
- Existing OpenSpec changes: `finance-product-rituals`, `finance-automation-system`, and `finance-product-design-system` become audited inputs rather than direct implementation plans.
- Future roadmap: expected to be rebuilt after this gate, likely as one change per implementation stage.
- Research process: external dependency decisions should cite Context7 documentation checks where available, or record an explicit fallback source when Context7 is unavailable.
- Code: no production code changes are introduced by this proposal.
