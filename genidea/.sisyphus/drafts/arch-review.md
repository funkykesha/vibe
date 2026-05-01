# Draft: Prompt Generator Service Architecture Review

## Project Overview
**Working Title**: Prompt Generator Service (на базе CodeSpark идеи)
**Current State**: Концепция в `Генерация идей.md`
**Goal**: Создать полноценный сервис, а не просто HTML-страницу

## User Requirements (Clarified)
- [x] Сервис для генерации идей (CodeSpark-based)
- [x] Интеграция с eliza-proxy (есть отдельный сервис на порту 3100)
- [x] Target: самостоятельный продукт (web + mobile в будущем), но сейчас web
- [x] Scale: Prototype (до 100 users)
- [x] Features: генерация идей + аналитика + логирование (промпты, токены, запросы)
- [x] Future: анализатор с обсуждением результата
- [x] Auth: No auth (анонимно)

## Research Results - Yandex Internal

### Eliza API Integration
- **Endpoint**: `http://localhost:3100` (через eliza-proxy)
- **Auth**: OAuth токен (ELIZA_TOKEN), формат: `Authorization: OAuth <token>`
- **Available models (no sec-review)**:
  - `deepseek-v3-1-terminus` ✅
  - `deepseek-v3-2` ✅
  - `glm-4-7` ✅
  - `gpt-oss-20b/120b` ✅
  - `qwen3-235b` ✅
  - `zeliboba-32b` ✅
- **Gotchas**: Cold start 3-5 минут → решено через двухуровневый кеш

### Architecture Patterns from groovy_agent
- SSE streaming с нормализацией (все провайдеры → `data: {"text":"chunk"}`)
- Graceful degradation при недоступности моделей
- Usage tracking через Ya-Pool headers
- Background model validation + fast startup

## Research Results - External Solutions

### Database Schema (Enterprise Pattern)
```sql
-- Main table: HEAD state and metadata
CREATE TABLE prompt_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id VARCHAR(255) UNIQUE NOT NULL,  -- anonymous session ID
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'
);

-- Requests: LLM calls per session
CREATE TABLE prompt_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id VARCHAR(255) NOT NULL REFERENCES prompt_sessions(session_id),
    prompt TEXT NOT NULL,
    model VARCHAR(100) NOT NULL,
    tokens_input INTEGER,
    tokens_output INTEGER,
    tokens_reasoning INTEGER,
    cost_usd DECIMAL(10,6),
    latency_ms INTEGER,
    status VARCHAR(50),  -- success, error, timeout
    error_message TEXT,
    timestamp TIMESTAMP DEFAULT NOW()
);

-- Generated ideas: stored results
CREATE TABLE generated_ideas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL REFERENCES prompt_requests(id),
    idea_type VARCHAR(100),  -- project_name, tech_stack, feature, etc
    content TEXT NOT NULL,
    choices_path JSONB,  -- [choice_1, choice_2, ...] path through decision tree
    timestamp TIMESTAMP DEFAULT NOW()
);

-- Analytics: aggregated metrics
CREATE TABLE analytics_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id VARCHAR(255),
    event_type VARCHAR(100) NOT NULL,  -- choice_selected, result_exported, feedback_rated
    event_data JSONB,
    timestamp TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_prompt_sessions_session_id ON prompt_sessions(session_id);
CREATE INDEX idx_prompt_requests_session_id ON prompt_requests(session_id);
CREATE INDEX idx_prompt_requests_timestamp ON prompt_requests(timestamp DESC);
CREATE INDEX idx_generated_ideas_request_id ON generated_ideas(request_id);
CREATE INDEX idx_analytics_events_timestamp ON analytics_events(timestamp DESC);
```

### Best Practices Summary
1. ✅ **SSE streaming** (simpler than WebSocket, HTTP-compatible)
2. ✅ **PostgreSQL** (fast, reliable, ACID, production-ready)
3. ✅ **Two-table pattern** (sessions + requests for atomic queries)
4. ✅ **Anonymous sessions** (localStorage session ID for MVP)
5. ✅ **Usage tracking** (tokens, latency, cost via Ya-Pool)

### What to Skip for MVP
1. ❌ Semantic caching (too complex for 100 users)
2. ❌ A/B testing (no need yet)
3. ❌ WebSocket (SSE is simpler for our case)
4. ❌ Redis caching (not needed for small scale)
5. ❌ Multi-provider orchestration (use Yandex models only)

## Proposed Tech Stack

### Backend
- **Runtime**: Bun (ultrafast, Node.js compatible)
- **Framework**: Hono (lightweight, faster than Express, TypeScript-first)
- **Database**: PostgreSQL (reliable, feature-rich)
- **ORM**: Drizzle ORM (TypeScript, lightweight, fast migrations)
- **Real-time**: SSE (Server-Sent Events via Hono)
- **Auth**: Anonymous sessions (localStorage session ID)

### Frontend
- **Runtime**: Bun (Vite-compatible)
- **Framework**: React 18 + Vite
- **State**: Zustand (lightweight, simple)
- **UI**: shadcn/ui + Tailwind (modern, production-ready)
- **HTTP client**: Native fetch (no axios needed)
- **Real-time**: EventSource API (native SSE support)

### Database
- **Primary**: PostgreSQL (host locally: docker or installed)
- **Migrations**: Drizzle Kit
- **Queries**: Drizzle ORM (type-safe SQL)
- **Analytics**: PostgreSQL with indexes

### Infrastructure
- **Eliza integration**: http://localhost:3100 (existing eliza-proxy)
- **Hosting**: Local development → later Vercel/RA for frontend + Railway/Railway-like for backend
- **Monitoring**: Winston logging + basic metrics (tokens, latency)

## Why This Stack?

### Hono over Express
- 2x faster (Cold start: 2ms vs 8ms)
- TypeScript-first (no @types/ needed)
- Better DX with async/await
- Built-in middleware (CORS, logging, etc)

### Bun over Node
- 2-3x faster execution
- Native TypeScript support
- Better bundler (Vite-compatible)
- Smaller memory footprint

### Drizzle over Prisma
- 5-7x faster queries
- Lightweight (<1MB vs 6MB+)
- Type-safe SQL without magic
- Better SQL control

### PostgreSQL over SQLite
- Production-ready from day 1
- No migration pain (SQLite → Postgres is complex)
- Better for analytics (indexes, JOINs, aggregates)
- Supports JSONB for flexible metadata

### SSE over WebSocket
- Simpler (no connection state to manage)
- HTTP-compatible (easier CORS, auth)
- One-way streaming is all we need (LLM → client)
- Native browser support (EventSource API)
- Less code to maintain

### Zustand over Redux
- Lightweight (1KB vs 100KB+)
- Simpler API (no reducers, actions, thunks)
- TypeScript support out of the box
- Perfect for small apps like ours

## Architecture Diagram

```
┌─────────────────┐
│   Frontend      │
│   (React + Vite)│
└────────┬────────┘
         │ SSE (EventSource)
         ▼
┌─────────────────┐
│  Backend API    │
│   (Hono + Bun)  │
└────────┬────────┘
         │
         ├─────────────────┬──────────────────┐
         ▼                 ▼                  ▼
┌─────────────────┐ ┌──────────────┐ ┌──────────────┐
│   PostgreSQL    │ │   Eliza API  │ │ Winston Logs │
│  (Drizzle ORM)  │ │   :3100      │ │  + Metrics   │
└─────────────────┘ └──────────────┘ └──────────────┘
```

## Database Relationships

```
prompt_sessions (1) ──────┬───┬─── (*) prompt_requests
                           │   │
                           │   └─── (*) generated_ideas
                           │
                           └─── (*) analytics_events
```

## Implementation Phases

### Phase 1: Core Infrastructure (Day 1)
1. Setup Bun + Hono backend
2. Setup PostgreSQL + Drizzle migrations
3. Setup React + Vite + Zustand frontend
4. Bootstrap database schema
5. Basic error handling + logging

### Phase 2: Eliza Integration (Day 1-2)
1. Implement SSE streaming endpoint
2. Connect to eliza-proxy
3. Usage tracking (tokens, latency, cost)
4. Error handling + graceful degradation

### Phase 3: Prompt Logic (Day 2)
1. Implement CodeSpark flow (4 choices)
2. Prompt engineering patterns
3. Session state management
4. Generate and store ideas

### Phase 4: Analytics (Day 3)
1. Track all user events
2. Basic analytics dashboard
3. Export functionality
4. Query optimization (indexes)

### Phase 5: Polish (Day 3-4)
1. UI/UX improvements
2. Performance optimization
3. Monitoring + alerting
4. Documentation

## Pending Decisions
- [ ] Final stack approval (User: "Нужно вернуться позже")
- [ ] Project structure organization

## Next Steps When User Returns
1. Confirm/adjust stack choices
2. Decide project structure
3. Create detailed architecture review plan
4. Generate implementation plan with TODOs

---

*Draft updated: All research complete, waiting for user to review stack proposals*
