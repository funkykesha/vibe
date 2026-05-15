import { config } from "../config.js";

const API = "https://api.raindrop.io/rest/v1";

export async function collectRaindrop(lastRunAt) {
  if (!config.raindrop.token) return { items: [], cursor: { last_run_at: lastRunAt } };

  const since = lastRunAt ? new Date(lastRunAt) : new Date(Date.now() - 7 * 86400000);
  const items = [];
  let page = 0;
  let newest = since;

  while (true) {
    const url = `${API}/raindrops/${config.raindrop.collectionId}?perpage=50&page=${page}&sort=-created`;
    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${config.raindrop.token}` },
    });
    if (!res.ok) throw new Error(`raindrop ${res.status}: ${await res.text()}`);
    const data = await res.json();

    let stopped = false;
    for (const r of data.items) {
      const created = new Date(r.created);
      if (created <= since) {
        stopped = true;
        break;
      }
      if (created > newest) newest = created;
      items.push({
        source: "raindrop",
        url: r.link,
        title: r.title,
        raw_content: [r.excerpt, r.note].filter(Boolean).join("\n\n"),
        tags: r.tags || [],
        captured_at: r.created,
      });
    }
    if (stopped || data.items.length < 50) break;
    page++;
    if (page > 20) break; // safety
  }

  return { items, cursor: { last_run_at: newest.toISOString() } };
}
