## Context

When `npm start` launches, the server calls `eliza.getModels()` which:
1. Fetches raw models from Eliza API (1-2 sec)
2. Triggers async `runProbe()` in background (checks each model in parallel, max 15 concurrent)
3. Probes complete over 3-5 seconds, results cached for 30 sec

Currently there's zero visibility into this process. Users see only:
```
eliza-proxy: http://localhost:3100
ELIZA_TOKEN: OK
```

## Goals / Non-Goals

**Goals:**
- Show model availability status during startup (in real-time)
- Group models by provider (OpenAI, Anthropic, Google, etc.)
- Display progress bar per provider: `[████░░░░] 12/15`
- Show each model's status inline (✅ working, ❌ failed, ⏳ checking)
- Append groups as they complete (no screen flickering, no clearing)
- Compact format: 3-5 lines per provider

**Non-Goals:**
- Interactive UI or menu bar display (logging only)
- Persistent storage of probe results (cache already exists)
- Detailed error messages per model (only pass/fail)
- Configuration or filtering of which models to probe

## Decisions

### 1. When to Show Output

**Decision:** Show groups as they complete, not all at once.

**Rationale:** Groups finish in parallel order (first 15 models probe simultaneously). Showing all at once would require waiting for all probes to complete. Incremental output provides early feedback.

**Alternatives considered:**
- A: Show everything after all probes complete → waits 3-5 sec, loses real-time feel
- B: Show only final summary → no visibility during probe phase
- C: Show incrementally ✅ chosen

### 2. Output Format & Screen Updates

**Decision:** Compact format with provider header + inline model list, wraps to 2 lines if needed. Update only changed provider's lines (no full screen clear/redraw).

**Rationale:** 
- Compact format: fits terminal width, readable, not verbose
- Incremental update: prevents flicker/jitter, keeps earlier output visible
- Multiple providers appear on screen simultaneously

**Alternatives considered:**
- A: Full screen redraw each update → flicker, confusing
- B: Append every model change → becomes cluttered quickly, hard to follow
- C: Update per provider block ✅ chosen

### 3. Progress Bar Metric

**Decision:** `[████░░░░] X/Y` where X = probed models (✅ + ❌), Y = total in provider.

**Rationale:** Shows "work done" not just "work that succeeded". Mirrors actual progress through API calls.

**Alternatives considered:**
- A: Only count working models → misleading, doesn't show effort
- B: Count all models checked ✅ chosen

### 4. Integration Point

**Decision:** Callback-based. Modify `createElizaClient()` to accept optional `onModelProbed(provider, model, status)` callback. Server calls this as each model finishes probe.

**Rationale:**
- Non-invasive: doesn't break existing `getModels()` contract
- Reactive: output updates naturally as probes complete
- Testable: callback can be mocked

**Alternatives considered:**
- A: Global event emitter → coupling, harder to test
- B: Polling `validatedCache` → inefficient, racy
- C: Callback ✅ chosen

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| Terminal width varies; lines may wrap oddly | Use 80-char target, test on common widths (80, 120, 160) |
| ANSI codes won't render on some terminals | Graceful fallback: works without colors (code still functions) |
| Probe takes >5 sec; output fills screen | Expected behavior. Can scroll up if needed. Mitigated by compact format. |
| Callback adds latency to probe loop | Negligible: callback is synchronous console.write, <1ms per model |

## Architectural Decisions

### New Module: `lib/format-startup.js`
Handles all formatting logic:
- `formatProgressBar(completed, total)` → bar string
- `formatModelStatus(model)` → colored status symbol
- `formatGroup(provider, models)` → full group output

This keeps formatting separate from core probe logic.

### No Changes to Probe Logic
`lib/eliza-client/probe.js` unchanged. All changes in:
- `lib/eliza-client/index.js` (add callback invocation)
- `server.js` (subscribe to callback, output)
- New `lib/format-startup.js` (formatting)

## Migration Plan

1. Create `lib/format-startup.js` (new file, no dependencies)
2. Modify `lib/eliza-client/index.js`: add callback param, invoke on each model probe
3. Modify `server.js`: subscribe to callback at startup, output formatted groups
4. No config changes, no env vars needed, no breaking changes
5. Deploy with standard `npm start`

## Open Questions

None. Design is locked based on detailed grill discussion with user.
