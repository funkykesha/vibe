---
name: analyzing-codex-token-usage
description: Use when the user wants a local Codex token usage daily, weekly, or monthly report, trend table, spike analysis, or terminal summary from ~/.codex data.
---

# Analyzing Codex Token Usage

## Overview

Build Codex token usage reports from local data only.

Use SQLite thread metadata to discover threads and rollout paths. Use rollout `token_count`
events for exact period accounting. Treat `threads.tokens_used` as the current thread snapshot,
not as the default answer for "how many tokens were used during this day/week/month".

## When to Use

- The user asks for a Codex token daily report, weekly report, monthly report, or usage trend.
- The user wants terminal tables showing token totals, top threads, or spike events.
- The user wants to understand which local Codex threads consumed the most tokens.

Do not use this skill for semantic work summaries. Use `codex-daily-summary` for that.

## Core Rules

- Do not hardcode `state_5.sqlite` or `logs_1.sqlite`. Discover `state_*.sqlite` and
  `logs_*.sqlite` dynamically.
- Do not scan `sessions/` first. Use the state DB to discover `rollout_path`.
- Do not sum `last_token_usage.total_tokens` as if it were exact delta. It can overcount.
- For exact period usage, diff successive `total_token_usage.total_tokens` values inside each
  thread.
- Use `threads.tokens_used` as the current end-of-thread snapshot only.
- Make the report timezone-explicit and use absolute date bounds.

## Data Model

### What the implementation stores

- `threads.tokens_used`: latest observed cumulative token count for the thread
- `threads.rollout_path`: authoritative path to the rollout JSONL
- rollout `event_msg` with `payload.type == "token_count"`:
  - `info.total_token_usage.total_tokens`: cumulative count
  - `info.last_token_usage.*`: last-step usage, useful for intensity, not strict accounting

### What to use for which question

- "How many tokens did this thread use in total so far?"
  Use `threads.tokens_used`.
- "How many tokens were consumed during this day/week/month?"
  Use rollout deltas from `total_token_usage.total_tokens`.
- "Which moments spiked?"
  Use per-event strict delta derived from adjacent cumulative totals.

## Workflow

### 1. Resolve Codex home

Use an explicit user-provided path if present.

Otherwise, use the current local Codex home, usually `~/.codex`.

If the environment clearly points to another Codex home, use that path instead of assuming the
default.

### 2. Discover the current SQLite files dynamically

Find state DB candidates:

```bash
find "$CODEX_HOME" -maxdepth 1 -type f -name 'state_*.sqlite' | sort -V
```

Choose the candidate with the highest numeric suffix. If there is a tie, prefer the newest mtime.

Validate that the chosen DB has the required thread metadata:

```bash
sqlite3 "$STATE_DB" ".schema threads"
```

Required columns:

- `id`
- `rollout_path`
- `created_at`
- `updated_at`
- `source`
- `model_provider`
- `title`
- `tokens_used`

Optional:

- Discover `logs_*.sqlite` the same way if the user explicitly wants operational logs.
- Do not use the logs DB as the primary token source.

### 3. Define the reporting window

Use the user's local timezone unless they explicitly request another one.

Default windows:

- Daily: local `00:00:00` to next local midnight, bucket by hour
- Weekly: ISO week, Monday `00:00:00` to next Monday, bucket by day
- Monthly: first local day of the month to first local day of the next month, bucket by day

Always state the exact window in the final report.

### 4. Build the candidate thread set

For token usage reports, default to an activity window, not a thread-creation window.

That means a thread is a candidate when:

- `updated_at >= window_start`
- `created_at < window_end`

Query at least:

```sql
SELECT
  id,
  rollout_path,
  created_at,
  updated_at,
  source,
  model_provider,
  title,
  tokens_used
FROM threads
WHERE updated_at >= ? AND created_at < ?;
```

If the user explicitly asks for "threads created during the day" rather than "usage during the
day", switch to a `created_at` filter and say that the metric is thread-snapshot-oriented.

### 5. Parse rollout token events

For each candidate thread:

1. Open `rollout_path`.
2. Read only rollout lines where:
   - top-level `type == "event_msg"`
   - `payload.type == "token_count"`
3. Order by timestamp.
4. Compute strict delta with:

```text
delta = max(0, current_total_token_usage_total_tokens - previous_total_token_usage_total_tokens)
```

5. Attribute `delta` to the event timestamp when the timestamp falls inside the report window.

This is the exact accounting path for daily/weekly/monthly usage totals.

### 6. Build the report tables

Minimum tables:

- Overview
  - window
  - timezone
  - candidate thread count
  - active thread count in window
  - total period tokens
  - median and p95 current thread snapshot tokens when useful
- Trend table
  - daily report: hourly buckets
  - weekly report: daily buckets
  - monthly report: daily buckets
- Top threads
  - sort by period delta tokens
  - include title, source, created/updated time, and current `tokens_used`
- Top spikes
  - sort by single-event strict delta
  - include timestamp, delta, running cumulative total, title

Useful optional table:

- Source breakdown by period delta tokens and thread count

### 7. Render in the terminal

Prefer readable terminal tables over raw JSON.

Good options:

- `sqlite3 -header -column` for quick inspection
- `column -ts $'\\t'` for TSV-like formatting
- `python3` plus `rich` for multi-table reports

If a table is too wide, trim thread titles but keep the thread ID available when precision matters.

### 8. Explain the numbers

The analysis should call out:

- concentration in a few threads
- peak hours or days
- differences between snapshot totals and period deltas
- any missing rollout files or stale rollout paths
- whether the current active thread is still growing during the snapshot

Use the user's language for the report prose unless they ask for another language.

## Quick Reference

```bash
# Discover the current state DB
find "$CODEX_HOME" -maxdepth 1 -type f -name 'state_*.sqlite' | sort -V

# Inspect thread schema
sqlite3 "$STATE_DB" ".schema threads"

# List candidate threads for an activity window
sqlite3 -header -column "$STATE_DB" '
SELECT id, rollout_path, created_at, updated_at, source, title, tokens_used
FROM threads
WHERE updated_at >= ? AND created_at < ?;
'
```

## Common Mistakes

- Hardcoding `state_5.sqlite` in the workflow.
- Treating `threads.tokens_used` as the exact answer for period usage.
- Summing `last_token_usage.total_tokens` directly.
- Scanning `sessions/` by filename instead of trusting `rollout_path` from SQLite.
- Forgetting that weekly and monthly reports should use activity timestamps, not only thread
  creation time.
- Reporting relative windows like "today" or "this week" without printing exact dates.
