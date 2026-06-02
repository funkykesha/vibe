# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`writer.js` and `research-pipeline.tar.gz` at the repo root are stray copies/snapshots — the
live code is under `research-pipeline/`. Edit there, not at the root.

## Build & Test

No build step, no test suite, no linter configured. Pure ESM, requires Node ≥ 20.

```bash
cd research-pipeline
npm install              # only dependency is dotenv
cp ../.env.example .env  # then fill in tokens (.env lives in research-pipeline/)

node index.js run        # full pipeline: collect → dedupe → enrich → write → digest
node index.js digest     # regenerate _inbox-digest.md from existing notes (no LLM calls)
node index.js collect    # debug: print collected raw items as JSON, no writes
```

There are no automated tests — verify changes by running `node index.js collect` (read-only)
before `run`, and inspect the generated notes in the vault.

## External dependency: eliza-proxy

Enrichment calls **a separately-running local proxy** at `http://localhost:3100`
(`ELIZA_BASE_URL`), a sibling project at `../eliza-proxy`. The proxy handles Eliza OAuth
internally — there is no Eliza token in this project's `.env`. It must be started separately
(`cd ../eliza-proxy && npm start`) before `node index.js run`, or every enrichment fails.
The wire format is SSE over `POST /v1/chat` (`data: {"text": ...}` chunks, `[DONE]`
terminator); see `callEliza` in `enrich.js`.

Default models `glm-4-7` / `deepseek-v3-1-terminus` are internal/communal and work without
sec-review. Override with `ENRICH_MODEL` / `FALLBACK_MODEL` for quality reruns.

## Architecture

`index.js` orchestrates a four-stage pipeline; each stage is its own module:

1. **Collect** (`collectors/*.js`) — three collectors run concurrently under
   `Promise.allSettled`, so one source failing never aborts the others. Each returns
   `{ items, cursor }`. Collection is **incremental**: cursors are persisted in
   `state.json` (`state.js`) and only items newer than the last cursor are fetched
   (Raindrop by `created`, Obsidian by file `mtime`, Telegram by `update_id`).
2. **Dedupe** (`dedupe.js`) — identity is `normalizeKey(item)`: a normalized URL (tracking
   params stripped, hash dropped, `www.` removed, lowercased), falling back to a title hash,
   then a content hash. Dedupes both within the batch and against existing notes. The set of
   existing keys comes from reading the `key:` frontmatter line of every note already in the
   vault (`loadExistingKeys` in `writer.js`). Duplicates become **merges** (append source to
   the existing note) instead of new notes — no re-enrichment.
3. **Enrich** (`enrich.js`) — runs in batches of 3 (`CONCURRENCY`) to be polite to the proxy.
   System prompt is loaded from `prompts/enrich.md`; the model must return strict JSON. On
   primary-model failure it retries with the fallback model; on JSON-parse failure it retries
   once with a stricter "JSON only" instruction. For thin captures (`raw_content` < 200 chars)
   it fetches and crudely strips the page HTML first.
4. **Write** (`writer.js`) — emits one markdown note per item into
   `VAULT_ROOT/Research/Processed/`, with YAML frontmatter whose `key:` field is the dedupe
   identity (this is what makes the pipeline idempotent across runs). Then regenerates
   `Research/_inbox-digest.md`, grouping by `try_now`, then `score ≥ 6`, then the rest.

The cursor advance is the last step (`saveState`) — if a run crashes mid-pipeline, the next
run re-collects the same window rather than silently skipping items.

### Key invariant

The `key:` frontmatter line in each generated note is the source of truth for dedupe. Do not
change the key format in `normalizeKey` without a migration, or every existing note becomes
invisible to dedupe and gets re-created as a duplicate.

## OpenSpec workflow

This project uses spec-driven development via OpenSpec (`openspec/`). Proposed changes live
under `openspec/changes/<name>/` (`proposal.md`, `design.md`, `tasks.md`, `specs/`). There is
an active change `add-research-feedback-calibration`. Use the `openspec-*` skills to create,
continue, verify, and archive changes rather than editing spec files by hand.

## Shell conventions

Per `AGENTS.md`: always use non-interactive flags for file ops (`cp -f`, `mv -f`, `rm -rf`) —
these may be aliased to `-i` and hang the agent on a confirmation prompt.
