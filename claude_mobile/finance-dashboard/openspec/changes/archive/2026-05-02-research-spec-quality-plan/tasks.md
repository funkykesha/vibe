## 1. Research Inputs

- [x] 1.1 Read `finance-product-rituals` proposal, design, tasks, and all capability specs
- [x] 1.2 Read `finance-automation-system` proposal, design, tasks if present, and all capability specs
- [x] 1.3 Read `finance-product-design-system` proposal, design, tasks, and `product-design-system` spec
- [x] 1.4 Identify all external dependencies, frameworks, APIs, and hosting platforms that require Context7 documentation checks and library ID resolution
- [x] 1.5 Extract the current stage list and normalize stage names across all planning changes
- [x] 1.6 Extract open questions, risks, non-goals, and assumptions into a single research backlog

## 2. Spec Audit

- [x] 2.1 Compare product ritual requirements against automation stages and identify missing implementation coverage
- [x] 2.2 Compare technical design decisions against product requirements and identify conflicts or hidden constraints
- [x] 2.3 Audit data model assumptions for accounts, settings, salary events, snapshots, provider mappings, and historical context
- [x] 2.4 Audit API contracts for dashboard, Telegram bot, provider sync, snapshots, settings, and salary events
- [x] 2.5 Audit safety boundaries for single-user access, manual updates, automated sync, ambiguous matches, and no silent financial changes
- [x] 2.6 Compare `finance-product-design-system` against `finance-product-rituals` and identify mismatched navigation, ritual, capital, history, theme, and responsive assumptions
- [x] 2.7 Audit current `index.html` UI constraints against the design-system requirements and identify migration risks
- [x] 2.8 Record audit findings with severity, affected spec files, and recommended follow-up action

## 3. Mini Spikes

- [x] 3.1 Spike current dashboard data model in `index.html` and document migration constraints from localStorage to API state
- [x] 3.2 Use Context7 to check FastAPI, SQLAlchemy, Pydantic settings, and python-dotenv docs relevant to backend and config verdicts
- [x] 3.3 Spike TBank provider feasibility: auth/session flow, account identity fields, balance shape, and failure modes, using Context7 or an explicit fallback source for provider documentation
- [x] 3.4 Spike account mapping safety rules for mapped, unmapped, renamed, duplicate, and ambiguous accounts
- [x] 3.5 Use Context7 to check python-telegram-bot docs relevant to polling, webhook, auth flow, and process model verdicts
- [x] 3.6 Use Context7 or explicit fallback sources to check hosting and storage options for SQLite, persistent disk, Postgres migration, backups, and secrets
- [x] 3.7 Use Context7 to check React, Tailwind, and browser storage/API docs relevant to dashboard migration and design-system feasibility
- [x] 3.8 Use Context7 or explicit fallback sources to check OCR/Vision dependency docs before assigning the `vision-ocr` verdict
- [x] 3.9 For every Context7 check, resolve the Context7-compatible library ID before querying documentation
- [x] 3.10 For every Context7 check, record dependency name, resolved Context7 library ID, resolved documentation source, retrieved topics, date, and impact on verdict
- [x] 3.11 For every unavailable Context7 source, record fallback source, retrieval date, and confidence level
- [x] 3.12 Spike historical import feasibility and decide whether imported history belongs in MVP, later stage, or separate tooling
- [x] 3.13 Spike design-system feasibility in the current single-file React/Tailwind setup: theme tokens, responsive two-column layout, compact top navigation, and avoiding app-code rewrites beyond the redesign scope

## 4. Stage Verdicts

- [x] 4.1 Record verdict for `config-layer`: keep, change, split, or drop
- [x] 4.2 Record verdict for `backend-foundation`: keep, change, split, or drop
- [x] 4.3 Record verdict for `dashboard-api-migration`: keep, change, split, or drop
- [x] 4.4 Record verdict for `tbank-sync`: keep, change, split, or drop
- [x] 4.5 Record verdict for `telegram-bot`: keep, change, split, or drop
- [x] 4.6 Record verdict for `history-snapshots`: keep, change, split, or drop
- [x] 4.7 Record verdict for `salary-events`: keep, change, split, or drop
- [x] 4.8 Record verdict for `vision-ocr`: keep, change, split, or drop
- [x] 4.9 Record verdict for `deployment`: keep, change, split, or drop
- [x] 4.10 Record verdict for `product-design-system`: keep, change, split, or drop

## 5. Roadmap Impact

- [x] 5.1 Summarize which existing specs need edits after research
- [x] 5.2 Summarize which findings must feed `finance-product-design-system`
- [x] 5.3 Propose the rebuilt implementation sequence based on verdicts
- [x] 5.4 Recommend whether implementation should be one change per stage or a smaller number of grouped changes
- [x] 5.5 Define the readiness criteria for starting the first implementation change

## 6. Verification

- [x] 6.1 Verify every requirement in `research-quality-gate` has a corresponding completed task or output
- [x] 6.2 Verify every current stage has a decision log entry with evidence and roadmap impact
- [x] 6.3 Verify no production implementation work is included in this research change
- [x] 6.4 Run `openspec status --change "research-spec-quality-plan"` and confirm the change is apply-ready
