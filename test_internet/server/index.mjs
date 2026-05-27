import { parseArgs } from 'node:util';
import fs from 'node:fs';
import { execSync } from 'node:child_process';
import { ROOT, DATA_FILE, LOG_FILE, ensureDirs } from './paths.mjs';
import { logger } from './logger.mjs';
import { appendRecord, lastRecordTs } from './storage.mjs';
import { sampleAll } from './sampler.mjs';
import { Scheduler } from './scheduler.mjs';
import { buildApp } from './http.mjs';
import { defaultRouteIface, ifaceIp, publicIp } from './netutil.mjs';

const MODEM_IFACE = process.env.SPEED_MODEM_IFACE || 'en0';
const DEFAULT_INTERVAL = Number(process.env.SPEED_INTERVAL_MIN || '30');

function which(cmd) {
  try {
    return execSync(`which ${cmd}`, { encoding: 'utf8' }).trim() || null;
  } catch {
    return null;
  }
}

async function cmdDoctor() {
  console.log('=== doctor ===');
  console.log(`ROOT: ${ROOT}`);
  console.log(`MODEM_IFACE: ${MODEM_IFACE}`);
  ensureDirs();
  console.log(`DATA_FILE: ${DATA_FILE} exists=${fs.existsSync(DATA_FILE)}`);
  console.log(`LOG_FILE:  ${LOG_FILE} exists=${fs.existsSync(LOG_FILE)}`);
  const src = await ifaceIp(MODEM_IFACE);
  console.log(`  ${MODEM_IFACE} ip: ${src}`);
  console.log(`  default route iface: ${await defaultRouteIface()}`);
  const pubDef = await publicIp();
  const pubModem = await publicIp({ iface: MODEM_IFACE });
  console.log(`  public ip (default): ${pubDef}`);
  console.log(`  public ip (${MODEM_IFACE}): ${pubModem}`);
  console.log(`  bypass differs: ${Boolean(pubDef && pubModem && pubDef !== pubModem)}`);
  console.log(`  tools: networkQuality=${which('networkQuality')} curl=${which('curl')} ping=${which('ping')} route=${which('route')} ifconfig=${which('ifconfig')}`);
  return 0;
}

async function cmdSample() {
  logger.info('sample (cli) start');
  const result = await sampleAll({ modemIface: MODEM_IFACE, appendRecord });
  process.stdout.write(JSON.stringify(result, null, 2) + '\n');
  return 0;
}

async function cmdServer({ host, port }) {
  ensureDirs();
  const scheduler = new Scheduler({
    intervalMin: DEFAULT_INTERVAL,
    modemIface: MODEM_IFACE,
    sampleAll,
    appendRecord,
  });
  scheduler.lastSampleTs = await lastRecordTs();
  scheduler.start();
  const app = await buildApp({ scheduler });
  await app.listen({ host, port });
  logger.info(`server listening http://${host}:${port} scheduler=${scheduler.intervalMin}m`);
  const shutdown = async () => {
    logger.info('server stop');
    scheduler.stop();
    try {
      await app.close();
    } catch {}
    process.exit(0);
  };
  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
  return 0;
}

async function main() {
  const argv = process.argv.slice(2);
  const sub = argv[0];
  if (!sub || !['doctor', 'sample', 'server'].includes(sub)) {
    console.error('usage: node server/index.mjs <doctor|sample|server> [--host H] [--port P]');
    process.exit(2);
  }
  const { values } = parseArgs({
    args: argv.slice(1),
    options: {
      host: { type: 'string', default: '127.0.0.1' },
      port: { type: 'string', default: '9876' },
    },
    allowPositionals: true,
  });
  if (sub === 'doctor') process.exit(await cmdDoctor());
  if (sub === 'sample') process.exit(await cmdSample());
  if (sub === 'server') {
    await cmdServer({ host: values.host, port: Number(values.port) });
  }
}

main().catch((e) => {
  console.error(e.stack || String(e));
  process.exit(1);
});
