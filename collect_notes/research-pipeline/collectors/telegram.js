import { config } from "../config.js";

const API = (token) => `https://api.telegram.org/bot${token}`;

function extractUrl(msg) {
  // entities from "url" or "text_link"
  const entities = msg.entities || msg.caption_entities || [];
  const text = msg.text || msg.caption || "";
  for (const e of entities) {
    if (e.type === "text_link") return e.url;
    if (e.type === "url") return text.slice(e.offset, e.offset + e.length);
  }
  // fallback regex
  const m = text.match(/https?:\/\/\S+/);
  return m ? m[0].replace(/[)\].,]+$/, "") : null;
}

function buildItem(msg) {
  const text = msg.text || msg.caption || "";
  const fwd = msg.forward_origin || {};
  const fwdName =
    fwd.chat?.title || fwd.sender_user?.first_name || fwd.sender_user_name || null;

  return {
    source: "telegram",
    url: extractUrl(msg),
    title: text.split("\n")[0].slice(0, 120) || `tg-${msg.message_id}`,
    raw_content: text,
    tags: [],
    captured_at: new Date(msg.date * 1000).toISOString(),
    forwarded_from: fwdName,
  };
}

export async function collectTelegram(lastUpdateId = 0) {
  if (!config.telegram.botToken) return { items: [], cursor: { last_update_id: lastUpdateId } };

  const items = [];
  let offset = lastUpdateId + 1;
  let maxId = lastUpdateId;

  // poll until empty (long polling kept short to be CLI-friendly)
  while (true) {
    const url = `${API(config.telegram.botToken)}/getUpdates?offset=${offset}&timeout=0&limit=100`;
    const res = await fetch(url);
    if (!res.ok) throw new Error(`telegram ${res.status}: ${await res.text()}`);
    const { result } = await res.json();
    if (!result.length) break;

    for (const update of result) {
      maxId = Math.max(maxId, update.update_id);
      const msg = update.message || update.channel_post;
      if (!msg) continue;
      if (
        config.telegram.allowedUserId &&
        msg.from?.id !== config.telegram.allowedUserId
      )
        continue;
      const text = msg.text || msg.caption;
      if (!text) continue;
      items.push(buildItem(msg));
    }
    offset = maxId + 1;
    if (result.length < 100) break;
  }

  return { items, cursor: { last_update_id: maxId } };
}
