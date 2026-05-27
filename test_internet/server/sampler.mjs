import { runCommand } from './runCommand.mjs';
import { ifaceIp, publicIp } from './netutil.mjs';
import { logger } from './logger.mjs';

const CACHEFLY_URL = 'https://cachefly.cachefly.net/10mb.test';
const UPLOAD_TARGETS = [
  { method: 'PUT', url: 'https://uploadtest.b-cdn.net/upload', acceptAny: true },
  { method: 'POST', url: 'https://httpbin.org/post', acceptAny: false },
  { method: 'POST', url: 'https://speed.cloudflare.com/__up', acceptAny: false },
];
const PING_TARGET = '1.1.1.1';

function nowTs() {
  return Date.now() / 1000;
}
function round2(n) {
  return Math.round(n * 100) / 100;
}

export async function sampleVpn() {
  const t0 = Date.now();
  const rec = {
    ts: nowTs(),
    profile: 'vpn',
    method: 'networkQuality',
    ok: false,
  };
  const { code, stdout, stderr } = await runCommand('networkQuality', ['-c'], { timeoutMs: 120_000 });
  rec.duration_sec = round2((Date.now() - t0) / 1000);
  if (code !== 0) {
    rec.error = (stderr || stdout).slice(0, 500);
    return rec;
  }
  let j;
  try {
    j = JSON.parse(stdout);
  } catch (e) {
    rec.error = `json: ${e.message}`;
    return rec;
  }
  const dlBps = j.dl_throughput;
  const ulBps = j.ul_throughput;
  rec.interface_name = j.interface_name ?? null;
  rec.download_mbps = dlBps ? round2(dlBps / 1_000_000) : null;
  rec.upload_mbps = ulBps ? round2(ulBps / 1_000_000) : null;
  const baseRtt = j.base_rtt ?? 0;
  rec.ping_ms = baseRtt ? round2(baseRtt) : null;
  rec.public_ip = await publicIp();
  rec.ok = rec.download_mbps != null;
  return rec;
}

async function curlDownloadMbps(iface, url, timeout = 30) {
  const args = [
    '-o', '/dev/null', '--silent', '--show-error',
    '--max-time', String(timeout),
    '--interface', iface,
    '-w', '%{speed_download} %{size_download} %{http_code}',
    url,
  ];
  const { code, stdout, stderr } = await runCommand('curl', args, { timeoutMs: (timeout + 5) * 1000 });
  if (code !== 0) return [null, (stderr || stdout).slice(0, 300)];
  const parts = stdout.trim().split(/\s+/);
  if (parts.length !== 3) return [null, `bad output: ${stdout}`];
  const bps = parseFloat(parts[0]) * 8;
  const httpCode = parts[2];
  if (httpCode !== '200' || !(bps > 0)) return [null, `http=${httpCode} bps=${bps}`];
  return [round2(bps / 1_000_000), null];
}

async function curlUploadOnce(iface, target, payload, timeout) {
  const args = [
    '-o', '/dev/null', '--silent', '--show-error',
    '--max-time', String(timeout),
    '--interface', iface,
    '-X', target.method,
    '--data-binary', '@-',
    '-H', 'Content-Type: application/octet-stream',
    '-H', 'Expect:',
    '-w', '%{speed_upload} %{size_upload} %{http_code}',
    target.url,
  ];
  const { code, stdout, stderr } = await runCommand('curl', args, { timeoutMs: (timeout + 5) * 1000, stdin: payload });
  if (code !== 0) return { ok: false, error: `${target.url}: ${(stderr || stdout).slice(0, 200)}` };
  const parts = stdout.trim().split(/\s+/);
  if (parts.length !== 3) return { ok: false, error: `${target.url}: bad output ${stdout}` };
  const bps = parseFloat(parts[0]) * 8;
  const sizeUploaded = Number(parts[1]);
  const httpCode = parts[2];
  if (!(bps > 0) || !(sizeUploaded >= payload.length)) {
    return { ok: false, error: `${target.url}: http=${httpCode} bps=${bps} size=${sizeUploaded}/${payload.length}` };
  }
  if (!target.acceptAny && !['200', '201', '204'].includes(httpCode)) {
    return { ok: false, error: `${target.url}: http=${httpCode} bps=${bps}` };
  }
  return { ok: true, mbps: round2(bps / 1_000_000), httpCode };
}

async function curlUploadMbps(iface, sizeMb = 5, timeout = 30) {
  const payload = Buffer.alloc(sizeMb * 1024 * 1024, 'x');
  const errors = [];
  for (const target of UPLOAD_TARGETS) {
    const result = await curlUploadOnce(iface, target, payload, timeout);
    if (result.ok) return [result.mbps, null];
    errors.push(result.error);
  }
  return [null, errors.join(' | ').slice(0, 400)];
}

async function pingMs(sourceIp, target = PING_TARGET, count = 5) {
  const { code, stdout, stderr } = await runCommand('ping', ['-S', sourceIp, '-c', String(count), target], { timeoutMs: 15_000 });
  if (code !== 0) return [null, (stderr || stdout).slice(0, 300)];
  const m = stdout.match(/min\/avg\/max\/\S+\s*=\s*[\d.]+\/([\d.]+)\//);
  if (!m) return [null, 'no rtt'];
  return [round2(parseFloat(m[1])), null];
}

export async function sampleModem(iface, vpnPublicIp) {
  const t0 = Date.now();
  const rec = {
    ts: nowTs(),
    profile: 'modem',
    interface_name: iface,
    ok: false,
  };
  const src = await ifaceIp(iface);
  rec.source_ip = src;
  if (!src) {
    rec.error = `no IP on ${iface}`;
    rec.duration_sec = round2((Date.now() - t0) / 1000);
    return rec;
  }
  const pub = await publicIp({ iface });
  rec.public_ip = pub;
  rec.bypass_verified = Boolean(pub && vpnPublicIp && pub !== vpnPublicIp);

  const [dl, dlErr] = await curlDownloadMbps(iface, CACHEFLY_URL);
  rec.download_mbps = dl;
  rec.method = 'curl-bound';

  const [ul, ulErr] = await curlUploadMbps(iface);
  rec.upload_mbps = ul;

  const [pm, pErr] = await pingMs(src);
  rec.ping_ms = pm;

  const errs = [dlErr, ulErr, pErr].filter(Boolean);
  if (errs.length) rec.error = errs.join(' | ').slice(0, 500);
  rec.ok = dl != null && pm != null;
  rec.duration_sec = round2((Date.now() - t0) / 1000);
  return rec;
}

export async function sampleAll({ modemIface, appendRecord }) {
  logger.info('sample start');
  const vpn = await sampleVpn();
  await appendRecord(vpn);
  logger.info(`vpn: dl=${vpn.download_mbps} ul=${vpn.upload_mbps} ping=${vpn.ping_ms} iface=${vpn.interface_name} ok=${vpn.ok}`);
  const modem = await sampleModem(modemIface, vpn.public_ip);
  await appendRecord(modem);
  logger.info(`modem: dl=${modem.download_mbps} ul=${modem.upload_mbps} ping=${modem.ping_ms} bypass=${modem.bypass_verified} ok=${modem.ok} err=${modem.error ?? ''}`);
  return { vpn, modem };
}
