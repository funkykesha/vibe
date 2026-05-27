import fs from 'node:fs';
import readline from 'node:readline';
import { DATA_FILE, ensureDirs } from './paths.mjs';
import { logger } from './logger.mjs';

export async function appendRecord(record) {
  ensureDirs();
  await fs.promises.appendFile(DATA_FILE, JSON.stringify(record) + '\n');
}

export async function readRecords({ from = null, to = null } = {}) {
  if (!fs.existsSync(DATA_FILE)) return [];
  const records = [];
  const stream = fs.createReadStream(DATA_FILE, { encoding: 'utf8' });
  const rl = readline.createInterface({ input: stream, crlfDelay: Infinity });
  for await (const raw of rl) {
    const line = raw.trim();
    if (!line) continue;
    let rec;
    try {
      rec = JSON.parse(line);
    } catch (e) {
      logger.warn('skip invalid ndjson line:', e.message);
      continue;
    }
    const ts = rec.ts;
    if (from != null && ts < from) continue;
    if (to != null && ts > to) continue;
    records.push(rec);
  }
  return records;
}

export async function lastRecordTs() {
  if (!fs.existsSync(DATA_FILE)) return null;
  const stat = await fs.promises.stat(DATA_FILE);
  if (stat.size === 0) return null;
  const chunkSize = Math.min(stat.size, 8192);
  const fh = await fs.promises.open(DATA_FILE, 'r');
  try {
    const buf = Buffer.alloc(chunkSize);
    await fh.read(buf, 0, chunkSize, stat.size - chunkSize);
    const text = buf.toString('utf8');
    const lines = text.split('\n').filter((l) => l.trim());
    for (let i = lines.length - 1; i >= 0; i--) {
      try {
        const rec = JSON.parse(lines[i]);
        if (typeof rec.ts === 'number') return rec.ts;
      } catch {}
    }
    return null;
  } finally {
    await fh.close();
  }
}
