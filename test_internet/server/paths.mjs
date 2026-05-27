import { fileURLToPath } from 'node:url';
import path from 'node:path';
import fs from 'node:fs';

const __filename = fileURLToPath(import.meta.url);
export const ROOT = path.resolve(path.dirname(__filename), '..');
export const DATA_FILE = path.join(ROOT, 'data', 'speed-tests.ndjson');
export const LOG_FILE = path.join(ROOT, 'logs', 'internet-speed.log');
export const DIST_DIR = path.join(ROOT, 'web', 'dist');

export function ensureDirs() {
  fs.mkdirSync(path.dirname(DATA_FILE), { recursive: true });
  fs.mkdirSync(path.dirname(LOG_FILE), { recursive: true });
}
