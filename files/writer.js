import fs from "node:fs/promises";
import path from "node:path";
import { config } from "./config.js";
import { normalizeKey } from "./dedupe.js";

function slugify(s) {
  return s
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 80);
}

function yaml(obj) {
  const lines = ["---"];
  for (const [k, v] of Object.entries(obj)) {
    if (v === null || v === undefined) continue;
    if (Array.isArray(v)) {
      lines.push(`${k}:`);
      for (const x of v) lines.push(`  - ${x}`);
    } else if (typeof v === "string" && (v.includes(":") || v.includes("\n"))) {
      lines.push(`${k}: "${v.replace(/"/g, '\\"').replace(/\n/g, " ")}"`);
    } else {
      lines.push(`${k}: ${v}`);
    }
  }
  lines.push("---");
  return lines.join("\n");
}

function notePath(item) {
  const slug = slugify(item.title || "untitled");
  const date = item.captured_at.slice(0, 10);
  return path.join(
    config.vault.root,
    config.vault.inboxDir,
    `${date}-${slug}.md`,
  );
}

async function findNoteByKey(key) {
  const dir = path.join(config.vault.root, config.vault.inboxDir);
  try {
    const files = await fs.readdir(dir);
    for (const f of files) {
      if (!f.endsWith(".md")) continue;
      const content = await fs.readFile(path.join(dir, f), "utf8");
      const m = content.match(/^key:\s*(.+)$/m);
      if (m && m[1].trim() === key) return path.join(dir, f);
    }
  } catch {}
  return null;
}

export async function loadExistingKeys() {
  const keys = new Set();
  const dir = path.join(config.vault.root, config.vault.inboxDir);
  try {
    const files = await fs.readdir(dir);
    for (const f of files) {
      if (!f.endsWith(".md")) continue;
      const content = await fs.readFile(path.join(dir, f), "utf8");
      const m = content.match(/^key:\s*(.+)$/m);
      if (m) keys.add(m[1].trim());
    }
  } catch {}
  return keys;
}

export async function writeNote(itemOrMerge, { mergeMode = false } = {}) {
  if (mergeMode) {
    const { key, item } = itemOrMerge;
    const existing = await findNoteByKey(key);
    if (!existing) return;
    const content = await fs.readFile(existing, "utf8");
    // append source to sources list in frontmatter
    const updated = content.replace(
      /^sources:\n((?:\s*-\s*.+\n)+)/m,
      (_match, list) => {
        if (list.includes(`- ${item.source}`)) return _match;
        return `sources:\n${list}  - ${item.source}\n`;
      },
    );
    // also append a line to body noting the additional sighting
    const withTrail =
      updated +
      `\n\n> Also seen via **${item.source}** at ${item.captured_at}` +
      (item.forwarded_from ? ` (forwarded from ${item.forwarded_from})` : "");
    await fs.writeFile(existing, withTrail);
    return;
  }

  const item = itemOrMerge;
  const sources = [item.source, ...(item._extra_sources || [])];
  const fm = {
    key: item._key,
    title: item.title,
    sources,
    url: item.url,
    category: item.category,
    tags: [...new Set([...(item.tags || []), ...sources.map((s) => `src/${s}`)])],
    applicability_score: item.applicability_score,
    try_now: item.try_now,
    captured_at: item.captured_at,
    processed_at: new Date().toISOString(),
  };

  const body = [
    yaml(fm),
    ``,
    `# ${item.title}`,
    ``,
    `**TL;DR:** ${item.tldr}`,
    ``,
    `**Why score ${item.applicability_score}/10:** ${item.applicability_reason}`,
    ``,
    item.related_to?.length
      ? `**Related:** ${item.related_to.map((r) => `[[${r}]]`).join(", ")}`
      : "",
    ``,
    `## Raw capture`,
    ``,
    item.raw_content || "(no content captured)",
    ``,
    item.url ? `[Source](${item.url})` : "",
  ]
    .filter((l) => l !== "")
    .join("\n");

  const p = notePath(item);
  await fs.mkdir(path.dirname(p), { recursive: true });
  await fs.writeFile(p, body);
}

export async function regenerateDigest() {
  const dir = path.join(config.vault.root, config.vault.inboxDir);
  const entries = [];
  try {
    const files = await fs.readdir(dir);
    for (const f of files) {
      if (!f.endsWith(".md")) continue;
      const content = await fs.readFile(path.join(dir, f), "utf8");
      const fmMatch = content.match(/^---\n([\s\S]*?)\n---/);
      if (!fmMatch) continue;
      const fm = Object.fromEntries(
        fmMatch[1]
          .split("\n")
          .map((l) => l.match(/^(\w+):\s*(.*)$/))
          .filter(Boolean)
          .map((m) => [m[1], m[2].trim()]),
      );
      const tldrMatch = content.match(/\*\*TL;DR:\*\*\s*(.+)/);
      entries.push({
        file: f,
        title: fm.title?.replace(/^"|"$/g, "") || f,
        score: Number(fm.applicability_score || 0),
        try_now: fm.try_now === "true",
        category: fm.category || "",
        url: fm.url || "",
        tldr: tldrMatch ? tldrMatch[1] : "",
      });
    }
  } catch (e) {
    console.error("digest: no notes dir yet");
    return;
  }

  entries.sort((a, b) => b.score - a.score);

  const tryNow = entries.filter((e) => e.try_now);
  const high = entries.filter((e) => !e.try_now && e.score >= 6);
  const rest = entries.filter((e) => e.score < 6);

  const fmt = (e) =>
    `- **[${e.score}/10]** [[${e.file.replace(/\.md$/, "")}|${e.title}]] · _${e.category}_ — ${e.tldr}${e.url ? ` ([link](${e.url}))` : ""}`;

  const md = [
    `# Research inbox digest`,
    ``,
    `_Last regenerated: ${new Date().toISOString()}_`,
    `_Total processed items: ${entries.length}_`,
    ``,
    `## 🔥 Try now (${tryNow.length})`,
    ``,
    tryNow.length ? tryNow.map(fmt).join("\n") : "_nothing actionable right now_",
    ``,
    `## High applicability (${high.length})`,
    ``,
    high.length ? high.map(fmt).join("\n") : "_none_",
    ``,
    `## Rest (${rest.length})`,
    ``,
    rest.length ? rest.map(fmt).join("\n") : "_none_",
    ``,
  ].join("\n");

  const out = path.join(config.vault.root, config.vault.digestFile);
  await fs.mkdir(path.dirname(out), { recursive: true });
  await fs.writeFile(out, md);
  console.log(`digest written: ${out}`);
}
