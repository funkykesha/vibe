## Spec Audit Findings

Date: 2026-05-02

Severity scale: High blocks roadmap rewrite or can cause incorrect financial behavior. Medium should be resolved before implementation of the affected stage. Low can be handled during stage planning.

## Findings

### High: Automation change has no executable task coverage

Affected files:

- `openspec/changes/finance-automation-system/proposal.md`
- `openspec/changes/finance-automation-system/design.md`

`finance-automation-system` defines stages from config through deployment, but `openspec list --json` reports the change as `no-tasks`. That makes it unsuitable as an implementation plan.

Recommended follow-up: after this research gate, split the roadmap into implementation changes with task files, preferably one stage per change.

### High: Most automation capabilities lack specs

Affected files:

- `openspec/changes/finance-automation-system/proposal.md`
- `openspec/changes/finance-automation-system/specs/`

The proposal lists `dashboard-api-migration`, `tbank-sync`, `telegram-bot`, `history-snapshots`, `salary-calculator`, `vision-ocr`, and `deployment`, but only `config-layer` and `backend-foundation` specs exist.

Recommended follow-up: create specs for every stage before implementation, or drop/split stages that are not ready.

### High: Product ritual order conflicts with automation order

Affected files:

- `openspec/changes/finance-product-rituals/design.md`
- `openspec/changes/finance-automation-system/proposal.md`

Product direction implies source of truth first, then salary/refresh workflows, then explicit snapshots, then history. The automation sequence places `history-snapshots` before salary events and before some ritual completion constraints are specified.

Recommended follow-up: reorder toward source of truth -> safe update flows -> salary events -> explicit snapshots -> history UI/import.

### High: Snapshot model under-specifies correctness

Affected files:

- `openspec/changes/finance-automation-system/design.md`
- `openspec/changes/finance-product-rituals/specs/capital-history-progress/spec.md`

Product specs require snapshots to capture balances, interpretation settings, timestamp/label, and totals. The technical design lists `SnapshotEntry.val` only and does not define captured category, currency rate, mortgage, source freshness, or whether totals are stored or recomputed.

Recommended follow-up: define snapshot payload versioning, captured settings, and calculation contract before `history-snapshots`.

### High: API contracts are missing beyond accounts/settings

Affected files:

- `openspec/changes/finance-automation-system/specs/backend-foundation/spec.md`
- `openspec/changes/finance-automation-system/design.md`

The design lists routes for snapshots, salary events, TBank sync, and TBank auth steps, but the specs define only accounts, settings, seed, static serving, and CORS.

Recommended follow-up: add request/response/error contracts for snapshots, salary events, provider sync, auth-step, and Telegram-facing operations.

### Medium: Single-user safety boundary is too vague

Affected files:

- `openspec/changes/finance-product-rituals/specs/financial-source-of-truth/spec.md`
- `openspec/changes/finance-automation-system/specs/config-layer/spec.md`

Specs say single-user and no multi-user auth, but do not define whether the dashboard/API is local-only or deployed. Deployed financial data needs at least a concrete trusted boundary: local network only, secret header, session, reverse proxy protection, or equivalent.

Recommended follow-up: define local/deployed access model before `backend-foundation` and `deployment`.

### Medium: Account mapping needs a state machine

Affected files:

- `openspec/changes/finance-product-rituals/specs/financial-source-of-truth/spec.md`
- `openspec/changes/finance-product-rituals/specs/telegram-finance-assistant/spec.md`

Specs reject silent updates for unmapped/ambiguous accounts, but do not define renamed accounts, duplicates, provider-deleted accounts, currency mismatch, external accounts with no balance, or user-confirmed aliases.

Recommended follow-up: add mapping states: `unmapped`, `candidate`, `confirmed`, `stale`, `conflict`, `ignored`.

### Medium: Design system assumes backend states that do not exist yet

Affected files:

- `openspec/changes/finance-product-design-system/specs/product-design-system/spec.md`
- `openspec/changes/finance-product-design-system/design.md`

The design asks for capital update and snapshot status/actions in the ritual workspace. Backend specs do not yet define source freshness, snapshot availability, or disabled/placeholder behavior.

Recommended follow-up: define capability availability states before implementing design-system UI.

### Medium: Current app and specs disagree on salary persistence

Affected files:

- `index.html`
- `openspec/changes/finance-product-rituals/specs/financial-source-of-truth/spec.md`

The current app persists categories, deductions, accounts, USD rate, and mortgage only. Salary inputs (`gross`, `month`, `year`, `payDay`) are ephemeral. Product specs require saved salary event records.

Recommended follow-up: treat salary events as a new persisted concept, not a localStorage migration.

### Medium: Historical import is feasible but unsafe as implicit migration

Affected files:

- `docs/user_files/!3 2026 финансы.md`
- `docs/user_files/!1 Процентовка от ЗП ( MAIN ).md`

Converted spreadsheets contain useful history but also repeated headers, `NaN`, derived totals, mixed sections, and name/category drift.

Recommended follow-up: keep import as separate tooling that creates candidate snapshots/events for review.

## Coverage Summary

| Audit area | Result |
|---|---|
| Product vs automation | Conflicts found in stage order and missing stage specs |
| Technical decisions vs product requirements | Snapshot correctness and safety boundary gaps found |
| Data model | Needs versioned snapshots, salary events, provider mapping statuses |
| API contracts | Accounts/settings only; missing core future contracts |
| Safety boundaries | Single-user trust boundary must be specified before deployment |
| Design system | Feasible but depends on backend availability states |
