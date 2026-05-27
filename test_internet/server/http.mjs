import fs from 'node:fs';
import path from 'node:path';
import Fastify from 'fastify';
import fastifyStatic from '@fastify/static';
import { DIST_DIR, LOG_FILE } from './paths.mjs';
import { readRecords, lastRecordTs } from './storage.mjs';
import { bucketSeries, BUCKET_SEC } from './bucketing.mjs';
import { logger } from './logger.mjs';

export async function buildApp({ scheduler }) {
  const app = Fastify({ logger: false });

  app.get('/api/series', async (req, reply) => {
    const q = req.query || {};
    const bucket = q.bucket || '1h';
    const sec = BUCKET_SEC[bucket] || 3600;
    const tsFrom = q.from ? Number(q.from) : null;
    const tsTo = q.to ? Number(q.to) : null;
    const recs = await readRecords();
    const payload = bucketSeries(recs, sec, { from: tsFrom, to: tsTo });
    payload.from = tsFrom;
    payload.to = tsTo;
    payload.total = recs.length;
    reply.header('Cache-Control', 'no-store');
    return payload;
  });

  app.get('/api/logs', async (req, reply) => {
    const limit = Number((req.query && req.query.limit) || 200);
    reply.header('Content-Type', 'text/plain; charset=utf-8');
    reply.header('Cache-Control', 'no-store');
    if (!fs.existsSync(LOG_FILE)) return '';
    const content = await fs.promises.readFile(LOG_FILE, 'utf8');
    const lines = content.split('\n');
    const nonEmpty = lines[lines.length - 1] === '' ? lines.slice(0, -1) : lines;
    return nonEmpty.slice(-limit).join('\n') + (nonEmpty.length ? '\n' : '');
  });

  app.get('/api/state', async (req, reply) => {
    reply.header('Cache-Control', 'no-store');
    const st = scheduler.state();
    if (st.last_sample_ts == null) {
      st.last_sample_ts = await lastRecordTs();
    }
    return st;
  });

  app.post('/api/sample', async () => {
    const r = scheduler.trigger();
    return r;
  });

  app.post('/api/interval', async (req) => {
    const minutes = Number((req.query && req.query.minutes) ?? 30);
    const interval = scheduler.setIntervalMin(minutes);
    return { interval_min: interval };
  });

  if (fs.existsSync(DIST_DIR)) {
    await app.register(fastifyStatic, { root: DIST_DIR, prefix: '/', wildcard: false });
    app.setNotFoundHandler((req, reply) => {
      if (req.method !== 'GET') {
        reply.code(404).type('text/plain').send('not found');
        return;
      }
      if (req.url.startsWith('/api/')) {
        reply.code(404).type('text/plain').send('not found');
        return;
      }
      reply.type('text/html').send(fs.readFileSync(path.join(DIST_DIR, 'index.html')));
    });
  } else {
    app.setNotFoundHandler((req, reply) => {
      if (req.method === 'GET' && !req.url.startsWith('/api/')) {
        reply.type('text/plain').send('web/dist not built. Run `npm run build`.');
        return;
      }
      reply.code(404).type('text/plain').send('not found');
    });
  }

  app.addHook('onResponse', (req, reply, done) => {
    logger.debug(`http ${req.method} ${req.url} -> ${reply.statusCode}`);
    done();
  });

  return app;
}
