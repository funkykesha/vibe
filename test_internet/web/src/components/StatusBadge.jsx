import React from 'react';

const fmt = new Intl.DateTimeFormat('ru-RU', {
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  second: '2-digit',
});

function formatTs(ts) {
  if (ts == null) return '—';
  return fmt.format(new Date(ts * 1000));
}

export function StatusBadge({ state }) {
  const { interval_min, last_sample_ts, sampling } = state || {};
  const mode = sampling ? 'sampling' : interval_min > 0 ? 'idle' : 'off';
  const label = sampling
    ? 'Sampling…'
    : interval_min > 0
      ? `Auto: every ${interval_min}m`
      : 'Auto: off';
  return (
    <div className={`badge ${mode}`}>
      <span className="dot" />
      <span>{label}</span>
      <span className="muted">· last: {formatTs(last_sample_ts)}</span>
    </div>
  );
}
