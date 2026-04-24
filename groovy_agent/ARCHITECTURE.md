# Groovy AI Agent — Architecture

## Overview

Browser-based AI agent for writing and executing Groovy scripts for JSON transformation.  
Stack: Node.js 18+ (Express) backend + single-page HTML/CSS/JS frontend.  
AI: Yandex Eliza API (proxy to OpenAI, Anthropic, etc.).

Tested on Node.js v25.9.0.

---

## File Structure

```
groovy_agent/
├── server.js            # Express backend
├── package.json         # deps: express, dotenv
├── .env                 # ELIZA_TOKEN, PORT (not committed)
├── .env.example         # template
├── models.json          # cached model list from Eliza
├── rules.json           # user-defined agent rules
├── public/
│   └── index.html       # full frontend (CSS + JS inline)
└── knowledge/
    ├── groovy-json.md          # JsonSlurper, JsonOutput, transformation patterns
    └── groovy-collections.md  # List/Map API, Groovy idioms
```

---

## Backend (server.js)

### Configuration
- Token loaded from `.env` via `dotenv` → `process.env.ELIZA_TOKEN`
- Never exposed to the client

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/models` | Fetch model list from Eliza, cache to `models.json`. Fallback to cache on error. |
| `POST` | `/api/chat` | Streaming SSE proxy to Eliza. Normalises both Anthropic and OpenAI streams. |
| `POST` | `/api/execute` | Run Groovy script. Code → temp file, input JSON → stdin, output → stdout. |
| `GET` | `/api/knowledge` | List all `.md` files in `knowledge/` |
| `POST` | `/api/knowledge` | Create/update a knowledge doc |
| `DELETE` | `/api/knowledge/:name` | Delete a knowledge doc |
| `GET` | `/api/rules` | Read `rules.json` |
| `POST` | `/api/rules` | Overwrite `rules.json` |

### Model Routing (`elizaConfig`)

Claude models require the Anthropic API format (different endpoint + request shape):

```
model starts with "claude-"
  → POST https://api.eliza.yandex.net/raw/anthropic/v1/messages
     body: { model, system, messages, max_tokens: 8096, stream: true }

everything else
  → POST https://api.eliza.yandex.net/raw/openai/v1/chat/completions
     body: { model, messages: [system, ...history], stream: true }
```

### Client Disconnect Detection

`res.on('close', ...)` is used (not `req.on('close', ...)`).  
In Node.js v17+ the `req` 'close' event fires when the request body is fully consumed by middleware (e.g. `express.json()`), not when the client disconnects. Using `req` would set `clientConnected = false` immediately, killing the stream before any data is sent.

### SSE Normalisation

Both Anthropic and OpenAI streams are normalised to a single client format:
```
data: {"text":"chunk"}\n\n
data: [DONE]\n\n
data: {"error":"message"}\n\n
```

Anthropic events mapped:
- `content_block_delta` → `{text}`
- `message_stop` → `[DONE]`
- `error` → `{error}`

OpenAI events mapped:
- `choices[0].delta.content` → `{text}`
- `choices[0].finish_reason` set → `[DONE]`

### System Prompt Construction (`buildSystemPrompt`)

Assembled per-request from:
1. Base Groovy expert instructions (Russian)
2. Key Groovy patterns (collect, filter, groupBy, safe navigation)
3. Knowledge base docs (all `.md` files, concatenated)
4. User rules (from `rules.json`)
5. Current code in editor (if non-empty)
6. Input JSON (if non-empty / non-`{}`)

### Groovy Execution (`runProcess`)

- Writes code to `/tmp/groovy_agent_<timestamp>.groovy`
- Spawns `groovy <file>` subprocess
- Feeds input JSON via `stdin`
- Captures `stdout` (result) and `stderr` (errors)
- 30-second timeout, auto-cleanup of temp file
- Checks common install paths: `PATH`, `/usr/local/bin`, `/opt/homebrew/bin`, `~/.sdkman/...`
- `proc.stdin.on('error', () => {})` suppresses EPIPE when script fails before stdin is fully written

---

## Frontend (public/index.html)

### Layout

```
┌─────────────────────────────────────────────────────┐
│ Header: title | model select | Rules | Knowledge     │
├──────────────────────┬──────────────────────────────┤
│                      │ Groovy Code Editor            │
│  Chat Panel          │ [Format] [Clear] [▶ Run]      │
│  (320px fixed)       │                               │
│                      ├───────────────┬───────────────┤
│  [message history]   │  Input JSON   │  Output       │
│                      │  (210px)      │  (210px)      │
│  [textarea] [Send]   │               │               │
├──────────────────────┴───────────────┴───────────────┤
│ Status bar                                           │
└──────────────────────────────────────────────────────┘
```

### Editors
- **Code editor**: CodeMirror 5, Groovy mode, Dracula theme, line numbers, bracket matching
- **Input editor**: CodeMirror 5, JSON mode, Dracula theme

### Keyboard Shortcuts
| Shortcut | Action |
|----------|--------|
| `Ctrl/Cmd+Enter` (chat textarea) | Send message |
| `F5` | Execute code |
| `Escape` | Close open modal |

### Chat / Streaming

1. User message → `POST /api/chat`
2. SSE chunks arrive → streamed into message bubble as plain text
3. On `[DONE]`: parse full content for ` ```groovy ` blocks
4. Largest code block → applied to editor + `showDiff()` highlights changes
5. Remaining text → rendered as Markdown via `marked.js`

### Diff Highlighting

- Line-by-line comparison of old vs new code
- Added lines: `cm-added` class (green background, 18% opacity)
- Changed lines: `cm-changed` class (yellow background, 18% opacity)
- Auto-removed after 6 seconds

### Model Loading

- On startup: `GET /api/models` → populates `<select>`
- Selected model saved to `localStorage`
- Status shows count: "225 моделей"

### Modals
- **Rules**: editable list of plain-text rules → saved to server on "Сохранить"
- **Knowledge**: split view (doc list + markdown editor) → CRUD via API

---

## Known Issues / TODO

- Model availability check: `/v1/models` returns all known models, not only those accessible to the current token — needs probe requests or access filtering
- Model family filter: no UI filter by provider (OpenAI / Anthropic / Google / etc.)

---

## Eliza API Reference

- **Base URL**: `https://api.eliza.yandex.net`
- **Auth**: `Authorization: OAuth <ELIZA_TOKEN>`
- **Models list**: `GET /v1/models`
- **OpenAI-compat (raw)**: `POST /raw/openai/v1/chat/completions`
- **Anthropic-compat (raw)**: `POST /raw/anthropic/v1/messages`
- Token: https://oauth.yandex-team.ru/authorize?response_type=token&client_id=60c90ec3a2b846bcbf525b0b46baac80
