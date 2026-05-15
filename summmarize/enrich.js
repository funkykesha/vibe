import { createElizaClient } from "eliza-client";
import { config } from "./config.js";
import fs from "node:fs/promises";

const client = createElizaClient({ token: config.eliza.token });

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
    // crude readability: strip tags, dedupe whitespace, cap length
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
  // strip fences if model ignored instructions
  const cleaned = text
    .replace(/^```(?:json)?\s*/i, "")
    .replace(/```\s*$/, "")
    .trim();
  return JSON.parse(cleaned);
}

export async function enrichItem(item) {
  const system = await loadPrompt();
  const fetched = item.raw_content?.length > 200 ? null : await maybeFetchPage(item.url);

  const messages = [
    { role: "system", content: system },
    { role: "user", content: buildUserPrompt(item, fetched) },
  ];

  let raw;
  try {
    raw = await client.chatOnce({
      model: config.eliza.enrichModel,
      messages,
      temperature: 0.2,
    });
  } catch (e) {
    // fallback
    raw = await client.chatOnce({
      model: config.eliza.fallbackModel,
      messages,
      temperature: 0.2,
    });
  }

  const text = typeof raw === "string" ? raw : raw.content || raw.text || JSON.stringify(raw);
  let parsed;
  try {
    parsed = parseJsonResponse(text);
  } catch (e) {
    // one retry with explicit "json only" reminder
    const retry = await client.chatOnce({
      model: config.eliza.enrichModel,
      messages: [...messages, { role: "user", content: "Return ONLY the JSON object. No prose." }],
      temperature: 0,
    });
    parsed = parseJsonResponse(
      typeof retry === "string" ? retry : retry.content || retry.text,
    );
  }

  // safety defaults
  return {
    tldr: parsed.tldr || "",
    tags: Array.isArray(parsed.tags) ? parsed.tags : [],
    category: parsed.category || "article",
    applicability_score: Number(parsed.applicability_score ?? 0),
    applicability_reason: parsed.applicability_reason || "",
    try_now: Boolean(parsed.try_now),
    related_to: Array.isArray(parsed.related_to) ? parsed.related_to : [],
  };
}
