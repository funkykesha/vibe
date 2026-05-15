import crypto from "node:crypto";

export function normalizeUrl(url) {
  if (!url) return null;
  try {
    const u = new URL(url);
    u.hash = "";
    // strip common tracking params
    const drop = ["utm_source", "utm_medium", "utm_campaign", "utm_content", "utm_term", "ref", "ref_src", "fbclid", "gclid"];
    for (const k of drop) u.searchParams.delete(k);
    u.hostname = u.hostname.toLowerCase().replace(/^www\./, "");
    let s = u.toString().toLowerCase();
    if (s.endsWith("/")) s = s.slice(0, -1);
    return s;
  } catch {
    return url.toLowerCase().trim();
  }
}

export function normalizeTitle(title) {
  if (!title) return null;
  return title
    .toLowerCase()
    .replace(/[^\p{L}\p{N}\s]/gu, " ")
    .replace(/\s+/g, " ")
    .trim();
}

export function normalizeKey(item) {
  const u = normalizeUrl(item.url);
  if (u) return `url:${u}`;
  const t = normalizeTitle(item.title);
  if (t) return `title:${crypto.createHash("md5").update(t).digest("hex").slice(0, 12)}`;
  return `raw:${crypto.createHash("md5").update(item.raw_content || "").digest("hex").slice(0, 12)}`;
}

/**
 * Dedupe items against each other AND against existing notes.
 * Returns:
 *   unique: items to enrich and write as new
 *   merges: { key, sources, tags, captured_ats } to merge into existing notes
 */
export function dedupe(items, existingKeys) {
  const seen = new Map(); // key -> item
  const merges = [];

  for (const item of items) {
    const key = normalizeKey(item);
    item._key = key;

    if (existingKeys.has(key)) {
      merges.push({ key, item });
      continue;
    }
    if (seen.has(key)) {
      // batch-internal merge: combine sources/tags
      const prev = seen.get(key);
      prev._extra_sources = prev._extra_sources || [];
      prev._extra_sources.push(item.source);
      prev.tags = [...new Set([...(prev.tags || []), ...(item.tags || [])])];
      continue;
    }
    seen.set(key, item);
  }

  return { unique: [...seen.values()], merges };
}
