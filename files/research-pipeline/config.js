import dotenv from "dotenv";
import path from "node:path";
import { fileURLToPath } from "node:url";

export const projectRoot = path.dirname(fileURLToPath(import.meta.url));

dotenv.config({ path: path.join(projectRoot, ".env") });

export const config = {
  vault: {
    root: process.env.VAULT_ROOT,
    inboxScanDir: process.env.VAULT_INBOX_DIR || "Clippings", // <-- new
    inboxDir: "Research/Processed",
    digestFile: "Research/_inbox-digest.md",
    sourceTag: "research/inbox",
  },
  raindrop: {
    token: process.env.RAINDROP_TOKEN,
    collectionId: 0, // 0 = all
  },
  telegram: {
    botToken: process.env.TG_BOT_TOKEN,
    allowedUserId: Number(process.env.TG_ALLOWED_USER_ID),
  },
  eliza: {
    // local eliza-proxy — handles OAuth internally, no client token needed
    baseUrl: process.env.ELIZA_BASE_URL || "http://localhost:3100",
    // models verified working without sec-review per eliza-proxy CLAUDE.md
    enrichModel: process.env.ENRICH_MODEL || "glm-4-7",
    fallbackModel: process.env.FALLBACK_MODEL || "deepseek-v3-1-terminus",
  },
  enrich: {
    contextSummary:
      "User builds multi-agent AI workflows on macOS centered on Claude Code, " +
      "with model tiers routed through a personal Node.js Eliza proxy. " +
      "Internal/communal models (GLM-4.7, DeepSeek-v3) handle bulk work; paid models for quality-critical tasks. " +
      "Interested in: agent frameworks, memory systems, evaluation, tool-use patterns, " +
      "prompt engineering, multi-agent orchestration, MCP, RAG, model routing.",
  },
  statePath: path.join(projectRoot, "state.json"),
};
