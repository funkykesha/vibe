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

**Prerequisites:** Groovy installed (`brew install groovy`), `.env` with `ELIZA_PROXY_URL`, eliza-proxy running at `../eliza-proxy`.

## Environment

| Variable | Purpose |
|---|---|
| `ELIZA_PROXY_URL` | URL of running eliza-proxy instance (required, e.g. `http://localhost:3100`) |
| `PORT` | Server port (default: 3000) |

**Setup:** Start eliza-proxy first (`cd ../eliza-proxy && npm run dev`), then start this server. The proxy handles Eliza auth (`ELIZA_TOKEN` lives in proxy's `.env`).

## Architecture

### Backend (`server.js`)

Single Express file with these subsystems:

**Eliza proxy client** (`createProxyClient()` in `server.js`) — thin HTTP client wrapping the eliza-proxy at `ELIZA_PROXY_URL`. Calls `GET /v1/models`, `POST /v1/chat` (SSE), `POST /v1/probe`. Model parsing, routing, and stream normalization live in `../eliza-proxy/lib/eliza-client/`.

**Model management** — `GET /api/models` calls proxy's `/v1/models`, returns `{ models, validated, updatedAt }`. Probe status (`validated: true/false`) comes from the proxy's background probe.

**Chat streaming** (`/api/chat`) — SSE from proxy's `/v1/chat`. Proxy normalizes Anthropic/OpenAI formats; groovy_agent receives unified format:
```
data: {"text":"chunk"}\n\n
data: {"usage":{...}}\n\n
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

Also read `AGENTS.md` — it has complementary workflow rules and the authoritative endpoint invariant list.

- Read `ARCHITECTURE.md` before any non-trivial change.
- Use `Grep` + targeted `Read` with `offset`/`limit` — do not read entire files blindly.
- Never read `models.json` in full — read only the first ~30 lines for structure.
- Modify **only** files directly related to the task. If touching an unrelated file seems necessary, stop and ask first.
- Do not refactor outside task scope.
- API contracts must stay stable; do not change function signatures without updating all callers.
- After changes: run `npm test`. If tests fail, revert the change and explain rather than patch blindly.

## Key Invariants

- `parseModels()` filters: test namespaces (`eliza_test`, `alice`, `gena_offline_batch_inference`, `internal`), non-chat models (embeddings, TTS, image-gen patterns), date-versioned IDs (`YYYY-MM-DD`), known old families.
- Streaming: both Anthropic and OpenAI SSE must be normalized to the same client format (see above).
- Groovy temp files must be cleaned up after execution.
- Use `res.on('close')` not `req.on('close')` for client disconnect detection.
