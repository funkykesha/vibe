import fs from "node:fs/promises";
import { config } from "./config.js";

export async function loadState() {
  try {
    return JSON.parse(await fs.readFile(config.statePath, "utf8"));
  } catch {
    return {};
  }
}

export async function saveState(state) {
  await fs.writeFile(config.statePath, JSON.stringify(state, null, 2));
}
