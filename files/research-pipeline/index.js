#!/usr/bin/env node
/**
 * Research pipeline: collect → dedupe → enrich → write
 *
 * Usage:
 *   node index.js run       # full pipeline
 *   node index.js digest    # regenerate _inbox-digest.md from existing notes
 *   node index.js collect   # only fetch raw items (debug)
 */

import { config } from "./config.js";
import { loadState, saveState } from "./state.js";
import { collectRaindrop } from "./collectors/raindrop.js";
import { collectObsidian } from "./collectors/obsidian.js";
import { collectTelegram } from "./collectors/telegram.js";
import { dedupe, normalizeKey } from "./dedupe.js";
import { enrichItem } from "./enrich.js";
import { writeNote, regenerateDigest, loadExistingKeys } from "./writer.js";

async function collectAll(state) {
  const results = await Promise.allSettled([
    collectRaindrop(state.raindrop?.last_run_at),
    collectObsidian(state.obsidian?.last_run_at),
    collectTelegram(state.telegram?.last_update_id),
  ]);

  const items = [];
  const newState = { ...state };

  for (const [i, r] of results.entries()) {
    const source = ["raindrop", "obsidian", "telegram"][i];
    if (r.status === "fulfilled") {
      items.push(...r.value.items);
      newState[source] = r.value.cursor;
      console.log(`[${source}] collected ${r.value.items.length}`);
    } else {
      console.error(`[${source}] FAILED:`, r.reason?.message || r.reason);
    }
  }

  return { items, newState };
}

async function run() {
  const state = await loadState();
  const { items, newState } = await collectAll(state);

  if (!items.length) {
    console.log("nothing new");
    return;
  }

  // dedupe within this batch + against existing notes
  const existingKeys = await loadExistingKeys();
  const { unique, merges } = dedupe(items, existingKeys);
  console.log(`unique: ${unique.length}, merges: ${merges.length}`);

  // enrich one-by-one (small concurrency to be polite to Eliza)
  const CONCURRENCY = 3;
  const enriched = [];
  for (let i = 0; i < unique.length; i += CONCURRENCY) {
    const batch = unique.slice(i, i + CONCURRENCY);
    const out = await Promise.allSettled(batch.map(enrichItem));
    for (const [j, r] of out.entries()) {
      if (r.status === "fulfilled") {
        enriched.push({ ...batch[j], ...r.value });
      } else {
        console.error(`enrich failed for ${batch[j].url || batch[j].title}:`, r.reason?.message);
      }
    }
    console.log(`enriched ${Math.min(i + CONCURRENCY, unique.length)}/${unique.length}`);
  }

  // write notes
  for (const item of enriched) await writeNote(item);
  for (const m of merges) await writeNote(m, { mergeMode: true });

  await regenerateDigest();
  await saveState(newState);
  console.log("done");
}

const cmd = process.argv[2] || "run";
const commands = {
  run,
  digest: regenerateDigest,
  collect: async () => {
    const state = await loadState();
    const { items } = await collectAll(state);
    console.log(JSON.stringify(items, null, 2));
  },
};

if (!commands[cmd]) {
  console.error(`unknown command: ${cmd}. use: ${Object.keys(commands).join(", ")}`);
  process.exit(1);
}

commands[cmd]().catch((e) => {
  console.error(e);
  process.exit(1);
});
