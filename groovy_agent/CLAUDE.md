# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Browser-based AI agent for writing and executing Groovy scripts for JSON transformation, powered by Yandex Eliza API (proxy to OpenAI, Anthropic, and other LLM providers).

**Stack:** Node.js 18+ (Express) + single-page HTML/CSS/JS frontend. No build step.

## Commands

```bash
npm run dev    # Start with --watch hot-reload (Node 18+)
npm start      # Start production server
```

**Prerequisites:** Groovy installed (`brew install groovy`), `.env` with `ELIZA_TOKEN`.

## Environment

| Variable | Purpose |
|---|---|
| `ELIZA_TOKEN` | OAuth token for Yandex Eliza API (required) |
| `PORT` | Server port (default: 3000) |

Token URL: `https://oauth.yandex-team.ru/authorize?response_type=token&client_id=60c90ec3a2b846bcbf525b0b46baac80`  
Auth header: `Authorization: OAuth <ELIZA_TOKEN>` (not Bearer).

## Architecture

### Backend (`server.js`)

Single Express file with these subsystems:

**Model management** — fetches from `https://api.eliza.yandex.net/v1/models` on startup, caches to `models.json`. `parseModels()` filters, deduplicates, and normalizes models. Deduplication key: `provider:family` — one canonical model per family is kept via `preferredModel()`.

**Model probing** (`scripts/test-models.js`) — background subprocess spawned at startup by `prefetchModels()`. Sends probe requests to each model to verify actual access, writes results back to `models.json` with `validated: true`. `/api/models` returns `pending: true` until this completes.

**Provider routing** (`elizaConfig()`) — Claude models use Anthropic API format + `/raw/anthropic/v1/messages`; all others use OpenAI-compatible format + `/raw/openai/v1/chat/completions`. Some internal Yandex models use dedicated `/raw/internal/<model>/...` endpoints. Provider inferred from model ID/title/developer fields.

**Chat streaming** (`/api/chat`) — proxies to Eliza with SSE. Normalizes both Anthropic and OpenAI stream formats to unified client format:
```
data: {"text":"chunk"}\n\n
data: [DONE]\n\n
data: {"error":"message"}\n\n
```
Uses `res.on('close')` for disconnect detection — **not** `req.on('close')`. In Node 18+ `req` 'close' fires when body is consumed by middleware, not on client disconnect, which would kill the stream immediately.

**Groovy execution** (`/api/execute`) — spawns `groovy <tempfile>` subprocess, feeds input JSON via stdin, 30s timeout. Temp file: `/tmp/groovy_agent_<timestamp>.groovy`. Suppresses EPIPE via `proc.stdin.on('error', () => {})`. Checks `PATH`, `/usr/local/bin`, `/opt/homebrew/bin`, `~/.sdkman/...`.

**System prompt** built per request in order: base instructions → key Groovy patterns → knowledge docs (`knowledge/*.md`) → user rules (`rules.json`) → current code → input JSON sample.

**Knowledge base** (`/api/knowledge/*`) — CRUD for `.md` files in `knowledge/`. All files concatenated into the system prompt.

### Frontend (`public/index.html`)

Single self-contained file. All UI text and prompts are in **Russian**.

- CodeMirror 5 editors for Groovy code and input JSON (loaded via CDN)
- SSE streaming rendered with `marked.js` for Markdown
- Model selection persisted in `localStorage` (`eliza-model` key)
- AI responses: largest ` ```groovy ` block auto-applied to editor; remaining text rendered as Markdown
- Diff highlighting: green = added lines, yellow = changed lines (6s fade)
- Keyboard shortcuts: `Ctrl/Cmd+Enter` = send, `F5` = execute, `Escape` = close modal

### API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/models` | Return validated model list (or `pending: true`) |
| `POST` | `/api/chat` | SSE streaming proxy to Eliza |
| `POST` | `/api/execute` | Spawn Groovy subprocess, return stdout/stderr |
| `GET/POST` | `/api/knowledge` | List / create-or-update knowledge docs |
| `DELETE` | `/api/knowledge/:name` | Delete knowledge doc |
| `GET/POST` | `/api/rules` | Read / overwrite `rules.json` |

## Agent Rules

- Read `ARCHITECTURE.md` before any non-trivial change.
- Use `Grep` + targeted `Read` with `offset`/`limit` — do not read entire files blindly.
- Never read `models.json` in full — read only the first ~30 lines for structure.
- Modify **only** files directly related to the task. If touching an unrelated file seems necessary, stop and ask first.
- Do not refactor outside task scope.
- API contracts must stay stable; do not change function signatures without updating all callers.
- After changes: `npm test` (no tests currently defined — verify manually). If tests fail, revert immediately.

## Key Invariants

- `parseModels()` filters: test namespaces (`eliza_test`, `alice`, `gena_offline_batch_inference`, `internal`), non-chat models (embeddings, TTS, image-gen patterns), date-versioned IDs (`YYYY-MM-DD`), known old families.
- Streaming: both Anthropic and OpenAI SSE must be normalized to the same client format (see above).
- Groovy temp files must be cleaned up after execution.
- Use `res.on('close')` not `req.on('close')` for client disconnect detection.
