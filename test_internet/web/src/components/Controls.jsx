import React from 'react';
import Flatpickr from 'react-flatpickr';

const BUCKETS = ['1m', '3m', '5m', '15m', '30m', '1h', '3h', '6h', '12h', '1d'];

const LOOKBACK_OPTIONS = [
  { value: '', label: '— нет —' },
  { value: '30m', label: '30 минут' },
  { value: '1h', label: '1 час' },
  { value: '3h', label: '3 часа' },
  { value: '12h', label: '12 часов' },
  { value: '24h', label: '24 часа' },
  { value: 'midnight', label: 'с полуночи' },
];

const INTERVALS = [
  { value: 0, label: 'Off' },
  { value: 5, label: '5m' },
  { value: 10, label: '10m' },
  { value: 15, label: '15m' },
  { value: 30, label: '30m' },
  { value: 60, label: '1h' },
  { value: 180, label: '3h' },
];

export function ViewControls({
  bucket,
  onBucketChange,
  range,
  onRangeChange,
  lookback,
  onLookbackChange,
  onClearAll,
  onRefresh,
}) {
  return (
    <div className="card controls view-controls">
      <label>
        Bucket
        <select value={bucket} onChange={(e) => onBucketChange(e.target.value)}>
          {BUCKETS.map((b) => (
            <option key={b} value={b}>
              {b}
            </option>
          ))}
        </select>
      </label>
      <label>
        Range
        <Flatpickr
          value={range}
          options={{ mode: 'range', dateFormat: 'Y-m-d' }}
          onChange={onRangeChange}
          placeholder="select range"
        />
      </label>
      <label>
        Lookback
        <select value={lookback} onChange={(e) => onLookbackChange(e.target.value)}>
          {LOOKBACK_OPTIONS.map((l) => (
            <option key={l.value} value={l.value}>
              {l.label}
            </option>
          ))}
        </select>
      </label>
      <button type="button" className="secondary" onClick={onClearAll}>
        All-time
      </button>
      <button type="button" className="secondary refresh-btn" onClick={onRefresh}>
        Refresh
      </button>
    </div>
  );
}

export function ActionControls({
  onSample,
  sampling,
  intervalMin,
  onIntervalChange,
}) {
  return (
    <div className="card controls action-controls">
      <button type="button" onClick={onSample} disabled={sampling}>
        {sampling ? 'Sampling…' : '▶ Sample now'}
      </button>
      <label>
        Interval
        <select
          value={intervalMin}
          onChange={(e) => onIntervalChange(Number(e.target.value))}
        >
          {INTERVALS.map((i) => (
            <option key={i.value} value={i.value}>
              {i.label}
            </option>
          ))}
        </select>
      </label>
    </div>
  );
}
