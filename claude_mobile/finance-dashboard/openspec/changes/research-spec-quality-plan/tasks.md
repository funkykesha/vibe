## 1. Research Inputs

- [ ] 1.1 Read `finance-product-rituals` proposal, design, tasks, and all capability specs
- [ ] 1.2 Read `finance-automation-system` proposal, design, tasks if present, and all capability specs
- [ ] 1.3 Read `finance-product-design-system` proposal, design, tasks, and `product-design-system` spec
- [ ] 1.4 Identify all external dependencies, frameworks, APIs, and hosting platforms that require Context7 documentation checks and library ID resolution
- [ ] 1.5 Extract the current stage list and normalize stage names across all planning changes
- [ ] 1.6 Extract open questions, risks, non-goals, and assumptions into a single research backlog

## 2. Spec Audit

- [ ] 2.1 Compare product ritual requirements against automation stages and identify missing implementation coverage
- [ ] 2.2 Compare technical design decisions against product requirements and identify conflicts or hidden constraints
- [ ] 2.3 Audit data model assumptions for accounts, settings, salary events, snapshots, provider mappings, and historical context
- [ ] 2.4 Audit API contracts for dashboard, Telegram bot, provider sync, snapshots, settings, and salary events
- [ ] 2.5 Audit safety boundaries for single-user access, manual updates, automated sync, ambiguous matches, and no silent financial changes
- [ ] 2.6 Compare `finance-product-design-system` against `finance-product-rituals` and identify mismatched navigation, ritual, capital, history, theme, and responsive assumptions
- [ ] 2.7 Audit current `index.html` UI constraints against the design-system requirements and identify migration risks
- [ ] 2.8 Record audit findings with severity, affected spec files, and recommended follow-up action

## 3. Mini Spikes

- [ ] 3.1 Spike current dashboard data model in `index.html` and document migration constraints from localStorage to API state
- [ ] 3.2 Use Context7 to check FastAPI, SQLAlchemy, Pydantic settings, and python-dotenv docs relevant to backend and config verdicts
- [ ] 3.3 Spike TBank provider feasibility: auth/session flow, account identity fields, balance shape, and failure modes, using Context7 or an explicit fallback source for provider documentation
- [ ] 3.4 Spike account mapping safety rules for mapped, unmapped, renamed, duplicate, and ambiguous accounts
- [ ] 3.5 Use Context7 to check python-telegram-bot docs relevant to polling, webhook, auth flow, and process model verdicts
- [ ] 3.6 Use Context7 or explicit fallback sources to check hosting and storage options for SQLite, persistent disk, Postgres migration, backups, and secrets
- [ ] 3.7 Use Context7 to check React, Tailwind, and browser storage/API docs relevant to dashboard migration and design-system feasibility
- [ ] 3.8 Use Context7 or explicit fallback sources to check OCR/Vision dependency docs before assigning the `vision-ocr` verdict
- [ ] 3.9 For every Context7 check, resolve the Context7-compatible library ID before querying documentation
- [ ] 3.10 For every Context7 check, record dependency name, resolved Context7 library ID, resolved documentation source, retrieved topics, date, and impact on verdict
- [ ] 3.11 For every unavailable Context7 source, record fallback source, retrieval date, and confidence level
- [ ] 3.12 Spike historical import feasibility and decide whether imported history belongs in MVP, later stage, or separate tooling
- [ ] 3.13 Spike design-system feasibility in the current single-file React/Tailwind setup: theme tokens, responsive two-column layout, compact top navigation, and avoiding app-code rewrites beyond the redesign scope

## 4. Stage Verdicts

- [ ] 4.1 Record verdict for `config-layer`: keep, change, split, or drop
- [ ] 4.2 Record verdict for `backend-foundation`: keep, change, split, or drop
- [ ] 4.3 Record verdict for `dashboard-api-migration`: keep, change, split, or drop
- [ ] 4.4 Record verdict for `tbank-sync`: keep, change, split, or drop
- [ ] 4.5 Record verdict for `telegram-bot`: keep, change, split, or drop
- [ ] 4.6 Record verdict for `history-snapshots`: keep, change, split, or drop
- [ ] 4.7 Record verdict for `salary-events`: keep, change, split, or drop
- [ ] 4.8 Record verdict for `vision-ocr`: keep, change, split, or drop
- [ ] 4.9 Record verdict for `deployment`: keep, change, split, or drop
- [ ] 4.10 Record verdict for `product-design-system`: keep, change, split, or drop

## 5. Roadmap Impact

- [ ] 5.1 Summarize which existing specs need edits after research
- [ ] 5.2 Summarize which findings must feed `finance-product-design-system`
- [ ] 5.3 Propose the rebuilt implementation sequence based on verdicts
- [ ] 5.4 Recommend whether implementation should be one change per stage or a smaller number of grouped changes
- [ ] 5.5 Define the readiness criteria for starting the first implementation change

## 6. Verification

- [ ] 6.1 Verify every requirement in `research-quality-gate` has a corresponding completed task or output
- [ ] 6.2 Verify every current stage has a decision log entry with evidence and roadmap impact
- [ ] 6.3 Verify no production implementation work is included in this research change
- [ ] 6.4 Run `openspec status --change "research-spec-quality-plan"` and confirm the change is apply-ready
