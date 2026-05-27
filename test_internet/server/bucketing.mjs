export const BUCKET_SEC = {
  '1m': 60,
  '3m': 180,
  '5m': 300,
  '15m': 900,
  '30m': 1800,
  '1h': 3600,
  '3h': 10800,
  '6h': 21600,
  '12h': 43200,
  '1d': 86400,
};

function median(sorted) {
  const n = sorted.length;
  if (n === 0) return null;
  const mid = Math.floor(n / 2);
  return n % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
}

function trimmedMedian(vals) {
  const filtered = vals.filter((v) => v != null);
  if (!filtered.length) return null;
  if (filtered.length < 3) {
    return Math.round(median([...filtered].sort((a, b) => a - b)) * 100) / 100;
  }
  const s = [...filtered].sort((a, b) => a - b);
  const n = s.length;
  const lo = Math.max(0, Math.floor(n * 0.1));
  const hi = Math.max(lo + 1, Math.floor(n * 0.9 + 0.5));
  const trimmed = s.slice(lo, hi);
  const arr = trimmed.length ? trimmed : s;
  return Math.round(median(arr) * 100) / 100;
}

export function bucketSeries(records, bucketSec, { from = null, to = null } = {}) {
  const buckets = new Map();
  for (const r of records) {
    const ts = r.ts;
    const prof = r.profile;
    if (ts == null || !prof) continue;
    if (from != null && ts < from) continue;
    if (to != null && ts > to) continue;
    const b = Math.floor(ts / bucketSec) * bucketSec;
    const key = `${b}|${prof}`;
    let list = buckets.get(key);
    if (!list) {
      list = [];
      buckets.set(key, list);
    }
    list.push(r);
  }
  const keys = [...buckets.keys()].sort((a, b) => {
    const [ba, pa] = a.split('|');
    const [bb, pb] = b.split('|');
    if (ba !== bb) return Number(ba) - Number(bb);
    return pa < pb ? -1 : pa > pb ? 1 : 0;
  });
  const points = [];
  for (const key of keys) {
    const [bStr, prof] = key.split('|');
    const bucketRecs = buckets.get(key);
    points.push({
      ts: Number(bStr),
      profile: prof,
      count: bucketRecs.length,
      download_mbps: trimmedMedian(bucketRecs.map((r) => r.download_mbps)),
      upload_mbps: trimmedMedian(bucketRecs.map((r) => r.upload_mbps)),
      ping_ms: trimmedMedian(bucketRecs.map((r) => r.ping_ms)),
    });
  }
  return { bucket_sec: bucketSec, points };
}
