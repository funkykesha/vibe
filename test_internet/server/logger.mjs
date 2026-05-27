import fs from 'node:fs';
import { LOG_FILE, ensureDirs } from './paths.mjs';

ensureDirs();
const stream = fs.createWriteStream(LOG_FILE, { flags: 'a' });

function fmt(level, args) {
  const ts = new Date().toISOString().replace('T', ' ').replace('Z', '');
  const msg = args
    .map((a) => (typeof a === 'string' ? a : JSON.stringify(a)))
    .join(' ');
  return `${ts} ${level} ${msg}\n`;
}

function emit(level, args) {
  const line = fmt(level, args);
  stream.write(line);
  process.stdout.write(line);
}

export const logger = {
  info: (...args) => emit('INFO', args),
  warn: (...args) => emit('WARN', args),
  error: (...args) => emit('ERROR', args),
  debug: (...args) => emit('DEBUG', args),
};
