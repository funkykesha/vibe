# research-pipeline

Collects research findings from Raindrop, Obsidian, and Telegram → dedupes → enriches via Eliza → writes structured notes back to Obsidian with a ranked digest.

## Setup

```bash
cp .env.example .env
# fill in tokens
npm install
```

Assumes **eliza-proxy is running locally** (default `http://localhost:3100`). The proxy handles OAuth internally — no Eliza token in this project's `.env`. Start it separately:

```bash
cd ../eliza-proxy && npm start
```

## Run

```bash
node index.js run       # full pipeline
node index.js digest    # regenerate digest only (cheap, no LLM calls)
node index.js collect   # debug: print what collectors found, no writes
```

## How each source works

**Raindrop** — fetches everything created after the last successful run. State stored in `state.json`.

**Obsidian** — walks `VAULT_ROOT`, picks notes mtime'd after last run that contain `#research/inbox` tag. To send something into the pipeline, just tag a note with `#research/inbox`. Processed output goes to `Research/Processed/` (skipped on the next walk).

**Telegram** — bot polling via `getUpdates`. To capture an item: forward a message or send a link to your bot. Only messages from `TG_ALLOWED_USER_ID` are accepted.

## Dedupe

Key is normalized URL (tracking params stripped, hash dropped, lowercased), falling back to normalized title. When a duplicate is seen, the new source is appended to the existing note's frontmatter `sources:` list and a trailer line is added. No re-enrichment.

## Output structure

```
VAULT_ROOT/
  Research/
    Processed/
      2026-05-15-some-paper-title.md
      2026-05-15-some-other-finding.md
    _inbox-digest.md
```

Each processed note has YAML frontmatter (key, sources, url, category, tags, applicability_score, try_now, captured_at, processed_at) and a body with TL;DR, score reasoning, related links, and raw capture.

The digest groups by:
- **🔥 Try now** — score ≥ 7 and concrete action available
- **High applicability** — score ≥ 6
- **Rest** — everything else

## Tuning

- **Model**: `ENRICH_MODEL` and `FALLBACK_MODEL` in `.env`. Defaults `glm-4-7` / `deepseek-v3-1-terminus` are the internal/communal ones that work without sec-review. Swap to Claude/GPT for quality reruns once sec-review is approved.
- **Eliza base URL**: `ELIZA_BASE_URL` in `.env` if proxy runs on non-default port.
- **Context for scoring**: edit `config.enrich.contextSummary` in `config.js`. This is what the model uses to judge applicability.
- **Tag vocabulary**: edit `prompts/enrich.md`.
- **Source tag** for Obsidian inbox: `config.vault.sourceTag` (default `research/inbox`).

## Cron later

When ready, add a launchd plist that runs `node /path/to/index.js run` every N hours. Logs to `~/Library/Logs/research-pipeline.log`.

## Known gaps / TODO

- HTML extraction is crude (regex). Swap in `@mozilla/readability` + `jsdom` if you want article body parsing that doesn't choke on JS-heavy pages.
- No image/PDF handling — links to PDFs will be enriched from URL + title only.
- `related_to` field is generated but not back-linked into note bodies automatically. Could be a follow-up pass.
- Telegram bot polling is at-most-once per `getUpdates` call; if the script crashes mid-batch, you may miss updates. For zero-loss, switch to webhook or persist offset before processing.
