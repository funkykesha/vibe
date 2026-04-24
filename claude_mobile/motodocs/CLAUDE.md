# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**МотоБардачок** (Moto Bardachok) — reference app for motorcycle owners. Single-file HTML with inline CSS + vanilla JS. Dark theme, mobile-first (notch-safe), no dependencies.

## Quick start

Open `index.html` in browser. Works offline.

## Structure

Single `index.html` file, ~1841 lines:

- **CSS**: Dark theme, responsive grid layout, colors by document type (ВУ/СТС/ОСАГО/ПТС)
- **HTML**: Screens (home, document details), cards, forms
- **JS**: Screen navigation, data persistence via `localStorage` (key: `motodocs_db`), form handling

## Editing

All code is inline in `<script>` tag at end of HTML:

- **Add document type**: update `DOCUMENTS` array, add CSS vars in `:root` for `--accent-*` and `--accent-*-bg`
- **Add field**: extend `FIELDS` object, update document detail screen
- **Styling**: Tailwind-like classes inline in CSS, `--safe-top` / `--safe-bottom` for notch handling (iOS)
- **Data**: persisted to `localStorage` as JSON (key `motodocs_db`), loads on init

## Data persistence

localStorage (key: `motodocs_db`) stores:
- Document list with fields (date, expiry, notes)
- Loaded on page init via `loadDatabase()`
- Saved on each change via `saveDatabase()`
- Errors silently; resets if corrupted

## Permissions

None. Browser-only, no network, no system access.
