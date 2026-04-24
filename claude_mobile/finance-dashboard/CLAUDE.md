# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Финансовый помощник** (Financial Assistant) — single-file personal finance dashboard for salary distribution and capital tracking.

Pure HTML/React app (no build process). Uses React 18 with Babel for JSX, Tailwind CSS, localStorage for persistence.

## Quick Start

Open `index.html` in browser. Data auto-saves to localStorage (key: `fin-v3`).

## Architecture

Single-file structure: all React code inline in HTML `<script type="text/babel">`.

**Key Concepts:**
- App state: month, year, payDay, gross salary, categories (cats), deductions (deds), accounts (accs), USD rate, mortgage balance
- Three tabs: salary distribution (ЗП), capital overview (Капитал), settings (Настройки)
- All Russian currency (₽); USD accounts convert via exchange rate (usdRate)
- Numbers use custom fmt/parse helpers: format with Intl.NumberFormat (ru-RU), parse loose strings with comma→period replacement

**Data Structure:**
- `cats`: [{id, name, pct}] — budget categories with % allocation
- `deds`: [{id, name, val}] — monthly deductions (taxes, insurance, etc.)
- `accs`: [{id, bank, name, type, cat, val, currency?}] — accounts across 7 banks
- `mortgage`: remaining mortgage balance (used for "net worth minus mortgage" calculation)
- `usdRate`: RUB/USD exchange rate for currency conversion

**Tab: Salary Distribution (ЗП)**
- Input: month, year, payDay (5th or 20th), gross salary before deductions
- Calculated: totalDeds, net (gross − deds), distribution by % across categories
- Validation: category % should sum to 100 (tolerance 0.05%)
- Copy button: exports formatted distribution to clipboard

**Tab: Capital (Капитал)**
- Lists all accounts grouped by bank (BANK_ORDER: Тинькоф, Яндекс, ДОМ РФ, etc.)
- Each account shows bank/name, type (Счет/Вклад/ИИС/Брокер/Долг), category, balance
- USD accounts multiplied by USD rate for RUB totals
- Totals: full capital, capital (excl. debts), broken by category (Быстрые/Семейные/Сын), IIS, net worth (capital − mortgage)
- Copy button: exports all account lines + summary totals

**Tab: Settings (Настройки)**
- Edit categories: name, %; add/delete categories
- Edit deductions: name, default value; add/delete deductions
- Auto-saves via useEffect dependency on cats/deds/accs/usdRate/mortgage

## Editing

All editing happens in `<script type="text/babel">`:
- **Add feature:** update App state, add UI in JSX sections
- **Change initial data:** modify INIT_CATS, INIT_DEDS, INIT_ACCS
- **Add bank:** add to BANK_ORDER, BANK_COLORS
- **Styling:** Tailwind classes inline in JSX (dark theme: bg-zinc-950, text-white)

## Data Persistence

localStorage (key `fin-v3`) holds: cats, deds, accs, usdRate, mortgage
- Loads on mount (useEffect)
- Saves after each state change (useEffect dependency)
- Errors silently (try/catch); resets to defaults if corrupted

## Notes

- Number inputs parse loose: "133 267,46" → 133267.46 (space/comma handling)
- No USD conversion for type Долг (debt doesn't convert)
- Toast notification: copy action shows "Скопировано!" for 1.8s
- Bank colors defined as BANK_COLORS object for UI accent on collapse buttons
- Monospace font: IBM Plex Mono (or fallback to Courier New)
