## Roadmap Impact

Date: 2026-05-02

## Specs That Need Follow-Up Edits

| Area | Needed edit |
|---|---|
| `finance-automation-system` | Add missing specs/tasks or replace with rebuilt per-stage changes. |
| `backend-foundation` | Add access boundary, provider mapping model, snapshot payload/versioning, and API error contracts. |
| `config-layer` | Prefer `pydantic-settings`, include `DATABASE_URL`, bot/deploy variables, and secret handling. |
| `financial-source-of-truth` | Add provider mapping states, snapshot interpretation context, and salary event contract. |
| `telegram-finance-assistant` | Add conversation/confirmation state rules and polling/webhook split. |
| `capital-history-progress` | Specify snapshot payload, totals storage/recompute policy, and historical import boundary. |
| `product-design-system` | Add capability availability states for snapshot/history/backend-dependent actions. |

## Findings To Feed Product Design System

- Current UI is mobile-narrow and global mono/dark; design implementation must start with tokens and typography.
- `История` and snapshot UI should support disabled/empty states until snapshot backend exists.
- Ritual workspace should preserve expert workflow density; avoid wizard-only flow.
- Compact capital strip is feasible from current derived totals, but freshness/source indicators require backend state.
- Theme switch should be token-driven, not separate UI branches.

## Rebuilt Implementation Sequence

Recommended sequence:

```text
research-quality-gate (done here)
        |
        v
revise-finance-roadmap
        |
        v
config-layer
        |
        v
backend-core-source-of-truth
        |
        +--> account-mapping-contract
        |
        +--> salary-events-api
        |
        +--> app-snapshots-api
        |
        v
dashboard-api-migration
        |
        v
product-design-tokens-navigation
        |
        +--> tbank-provider-contract
        |         |
        |         v
        |   tbank-live-sync
        |
        +--> telegram-local-assistant
        |
        v
history-ui-and-progress
        |
        v
deployment-postgres-webhook-backups
        |
        v
historical-import-tooling
        |
        v
vision-ocr-research
```

## Change Structure Recommendation

Use one OpenSpec change per stage for high-risk work.

Recommended changes:

1. `revise-finance-roadmap`
2. `implement-config-layer`
3. `implement-backend-core-source-of-truth`
4. `define-account-mapping-contract`
5. `implement-salary-events-api`
6. `implement-app-snapshots-api`
7. `migrate-dashboard-api-state`
8. `implement-product-design-tokens-navigation`
9. `implement-tbank-provider-contract`
10. `implement-tbank-live-sync`
11. `implement-telegram-local-assistant`
12. `implement-history-progress-ui`
13. `implement-deployment-postgres-webhook`
14. `implement-historical-import-tooling`
15. `research-vision-ocr`

Do not create one large implementation change unless later planning proves these changes are tightly coupled. Current evidence says they are not.

## Readiness Criteria For First Implementation Change

The first implementation change can start when:

- `revise-finance-roadmap` exists or this research output is accepted as its source.
- Target stage has proposal, design, specs, and tasks.
- Context7/fallback documentation records exist for external dependencies used by the stage.
- Stage dependencies have verdicts and no unresolved high-severity blockers.
- Production implementation is scoped to one stage or one cohesive sub-stage.

## Immediate Next Step

Create `revise-finance-roadmap` to convert this research into the updated stage plan. Do not implement `finance-automation-system` directly.
