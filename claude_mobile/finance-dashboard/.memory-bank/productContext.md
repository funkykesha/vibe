# Product Context

## Problem Statement
The dashboard supports a personal finance ritual: calculate salary distribution, maintain current capital, save explicit salary events, and create explicit capital snapshots for history.

## User Personas

| Persona | Description | Primary Need |
|---------|-------------|--------------|
| Owner | Uses the dashboard for personal finance rituals | Fast edits, accurate totals, persistent source of truth |

## How It Works
1. User opens the FastAPI-served dashboard and lands on `Ритуалы`.
2. Backend loads accounts, settings, and snapshots as source-of-truth data.
3. User enters salary input, reviews deductions/net/distribution, and can explicitly save a salary event.
4. User edits accounts/settings; current state persists through backend APIs.
5. User explicitly creates a snapshot; history shows app-created snapshots and comparison deltas.

## Key Features

| Feature | Description | Priority |
|---------|-------------|----------|
| Ritual-first UX | `Ритуалы` is the first screen with salary workflow and compact capital context | P0 |
| Backend source of truth | Accounts/settings load and save through FastAPI APIs | P0 |
| Explicit local import | `fin-v3` import is shown only when backend is empty and user confirms | P0 |
| Salary events | Explicit save persists date/type/gross/deductions/net/distribution | P0 |
| Snapshots/history | Explicit snapshots capture context/totals and power history/comparison | P0 |
| Themes | System/Light/Dark modes via semantic tokens | P1 |

---
*Updated when product vision or user requirements change.*
