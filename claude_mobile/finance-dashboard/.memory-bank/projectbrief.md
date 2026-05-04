# Project Brief

## Project Name
Финансовый помощник

## Purpose and Vision
Single-file personal finance dashboard for salary distribution, capital tracking, and lightweight ritual-driven planning.

## Core Requirements
- React 18 in a single `index.html` file with Babel-in-browser JSX.
- Salary distribution tab with local calculations and copy/export actions.
- Capital tab with bank-grouped balances and derived totals.
- Settings tab for categories, salary inputs, and persisted preferences.
- Local persistence through `fin-v3`, plus backend-backed settings/accounts/snapshots.

## Goals and Success Criteria
- Fast local editing with predictable calculations.
- Preserve state across reloads.
- Keep the UI small and explicit rather than abstracted.

## Scope

### In Scope
- Salary ritual workflow.
- Capital overview and copy actions.
- Settings for categories, deduction mapping, USD rate, and mortgage.

### Out of Scope
- Multi-file frontend architecture.
- New npm build pipeline.
- Broad backend expansion beyond the current API surface.

---
*Source of truth for the project. Updated rarely, only when fundamental goals change.*
