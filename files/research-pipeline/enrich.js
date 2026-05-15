import { config } from "./config.js";
import fs from "node:fs/promises";

let SYSTEM_PROMPT;
async function loadPrompt() {
  if (!SYSTEM_PROMPT) {
    SYSTEM_PROMPT = await fs.readFile(new URL("./prompts/enrich.md", import.meta.url), "utf8");
  }
  return SYSTEM_PROMPT;
}

async function maybeFetchPage(url) {
  if (!url) return null;
  try {
    const res = await fetch(url, {
      headers: { "user-agent": "Mozilla/5.0 (research-pipeline)" },
      signal: AbortSignal.timeout(10_000),
    });
    if (!res.ok) return null;
    const html = await res.text();
    const text = html
      .replace(/<script[\s\S]*?<\/script>/gi, "")
      .replace(/<style[\s\S]*?<\/style>/gi, "")
      .replace(/<[^>]+>/g, " ")
      .replace(/\s+/g, " ")
      .trim();
    return text.slice(0, 8000);
  } catch {
    return null;
  }
}

function buildUserPrompt(item, fetched) {
  return [
    `# Context for assessment`,
    config.enrich.contextSummary,
    ``,
    `# Item to assess`,
    `**Source:** ${item.source}${item._extra_sources?.length ? ` (also: ${item._extra_sources.join(", ")})` : ""}`,
    `**Title:** ${item.title}`,
    `**URL:** ${item.url || "—"}`,
    item.tags?.length ? `**Existing tags:** ${item.tags.join(", ")}` : "",
    ``,
    `**Captured content:**`,
    item.raw_content || "(no body)",
    fetched ? `\n**Page content (truncated):**\n${fetched}` : "",
    ``,
    `Return ONLY valid JSON matching the schema in the system prompt. No markdown fences, no commentary.`,
  ]
    .filter(Boolean)
    .join("\n");
}

function parseJsonResponse(text) {
  const cleaned = text
    .replace(/^```(?:json)?\s*/i, "")
    .replace(/```\s*$/, "")
    .trim();
  return JSON.parse(cleaned);
}

/**
 * Call eliza-proxy /v1/chat (SSE) and collect the full text response.
 * Event format per eliza-proxy CLAUDE.md:
 *   data: {"text":"Hello"}
 *   data: {"usage":{...}}
 *   data: [DONE]
 */
async function callEliza({ model, messages, temperature = 0.2 }) {
  const res = await fetch(`${config.eliza.baseUrl}/v1/chat`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ model, messages, temperature, stream: true }),
  });

  if (!res.ok) {
    const errText = await res.text().catch(() => "");
    throw new Error(`eliza /v1/chat ${res.status}: ${errText.slice(0, 200)}`);
  }

  const reader = res.body.getReader();
  const decoder = new TextDecoder();
  let buffer = "";
  let output = "";
  let usage = null;

  while (true) {
    const { value, done } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value, { stream: true });

    const lines = buffer.split(/\r?\n/);
    buffer = lines.pop(); // keep incomplete trailing line

    for (const line of lines) {
      if (!line.startsWith("data:")) continue;
      const payload = line.slice(5).trim();
      if (!payload || payload === "[DONE]") continue;
      try {
        const evt = JSON.parse(payload);
        if (typeof evt.text === "string") output += evt.text;
        if (typeof evt.delta === "string") output += evt.delta;
        if (evt.usage) usage = evt.usage;
        if (evt.error) throw new Error(`eliza stream error: ${JSON.stringify(evt.error)}`);
      } catch (e) {
        if (e.message?.startsWith("eliza stream error")) throw e;
        // skip malformed lines silently
      }
    }
  }

  return { text: output, usage };
}

export async function probeModel(model) {
  try {
    const res = await fetch(`${config.eliza.baseUrl}/v1/probe`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ model }),
      signal: AbortSignal.timeout(8_000),
    });
    return res.ok;
  } catch {
    return false;
  }
}

export async function enrichItem(item) {
  const system = await loadPrompt();
  const fetched = item.raw_content?.length > 200 ? null : await maybeFetchPage(item.url);

  const messages = [
    { role: "system", content: system },
    { role: "user", content: buildUserPrompt(item, fetched) },
  ];

  let result;
  try {
    result = await callEliza({ model: config.eliza.enrichModel, messages, temperature: 0.2 });
  } catch (e) {
    console.warn(`primary model ${config.eliza.enrichModel} failed: ${e.message} — falling back`);
    result = await callEliza({ model: config.eliza.fallbackModel, messages, temperature: 0.2 });
  }

  let parsed;
  try {
    parsed = parseJsonResponse(result.text);
  } catch {
    const retry = await callEliza({
      model: config.eliza.enrichModel,
      messages: [...messages, { role: "user", content: "Return ONLY the JSON object. No prose, no fences." }],
      temperature: 0,
    });
    parsed = parseJsonResponse(retry.text);
  }

  return {
    tldr: parsed.tldr || "",
    tags: Array.isArray(parsed.tags) ? parsed.tags : [],
    category: parsed.category || "article",
    applicability_score: Number(parsed.applicability_score ?? 0),
    applicability_reason: parsed.applicability_reason || "",
    try_now: Boolean(parsed.try_now),
    related_to: Array.isArray(parsed.related_to) ? parsed.related_to : [],
    _usage: result.usage,
  };
}
