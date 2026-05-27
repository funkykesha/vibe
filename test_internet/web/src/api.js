async function jsonOrThrow(res) {
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

export async function fetchSeries({ bucket, from, to } = {}) {
  const params = new URLSearchParams();
  if (bucket) params.set('bucket', bucket);
  if (from != null) params.set('from', String(from));
  if (to != null) params.set('to', String(to));
  const res = await fetch('/api/series?' + params.toString(), { cache: 'no-store' });
  return jsonOrThrow(res);
}

export async function fetchState() {
  const res = await fetch('/api/state', { cache: 'no-store' });
  return jsonOrThrow(res);
}

export async function fetchLogs({ limit = 200 } = {}) {
  const res = await fetch(`/api/logs?limit=${limit}`, { cache: 'no-store' });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.text();
}

export async function postSample() {
  const res = await fetch('/api/sample', { method: 'POST' });
  return jsonOrThrow(res);
}

export async function postInterval(minutes) {
  const res = await fetch(`/api/interval?minutes=${encodeURIComponent(minutes)}`, { method: 'POST' });
  return jsonOrThrow(res);
}
