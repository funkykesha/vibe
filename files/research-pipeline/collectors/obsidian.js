import fs from "node:fs/promises";
import path from "node:path";
import { config } from "../config.js";

async function* walk(dir) {
  const entries = await fs.readdir(dir, { withFileTypes: true });
  for (const e of entries) {
    if (e.name.startsWith(".")) continue;
    const p = path.join(dir, e.name);
    if (e.isDirectory()) yield* walk(p);
    else if (e.name.endsWith(".md")) yield p;
  }
}

function extractFrontmatter(content) {
  const m = content.match(/^---\n([\s\S]*?)\n---/);
  if (!m) return {};
  const fm = {};
  for (const line of m[1].split("\n")) {
    const mm = line.match(/^(\w+):\s*(.*)$/);
    if (mm) fm[mm[1]] = mm[2].trim();
  }
  return fm;
}

function extractTags(content) {
  // both #tag/style and frontmatter tags
  const inline = [...content.matchAll(/(?:^|\s)#([\w/-]+)/g)].map((m) => m[1]);
  return [...new Set(inline)];
}

function extractFirstUrl(content) {
  const m = content.match(/https?:\/\/\S+/);
  return m ? m[0].replace(/[)\].,]+$/, "") : null;
}

export async function collectObsidian(lastRunAt) {
  if (!config.vault.root) {
    console.warn("[obsidian] VAULT_ROOT is not set");
    return { items: [], cursor: { last_run_at: lastRunAt } };
  }

  const since = lastRunAt ? new Date(lastRunAt) : new Date(0);
  const items = [];
  let newest = since;
  // skip the processed output dir so we don't loop on our own output

  const scanDir = config.vault.inboxScanDir
    ? path.join(config.vault.root, config.vault.inboxScanDir)
    : config.vault.root;

  for await (const file of walk(scanDir)) {
    const stat = await fs.stat(file);
    if (stat.mtime <= since) continue;
    const content = await fs.readFile(file, "utf8");
    const tags = extractTags(content);
    // When scanning a dedicated dir (inboxScanDir), folder location is the implicit filter
    if (!config.vault.inboxScanDir && !tags.includes(config.vault.sourceTag)) continue;
    if (stat.mtime > newest) newest = stat.mtime;

    const fm = extractFrontmatter(content);
    items.push({
      source: "obsidian",
      url: extractFirstUrl(content),
      title: fm.title || path.basename(file, ".md"),
      raw_content: content.replace(/^---[\s\S]*?---/, "").trim(),
      tags: tags.filter((t) => t !== config.vault.sourceTag),
      captured_at: stat.mtime.toISOString(),
      origin_path: file,
    });
  }

  return { items, cursor: { last_run_at: newest.toISOString() } };
}
