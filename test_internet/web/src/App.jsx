import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { SpeedChart } from './components/SpeedChart.jsx';
import { ViewControls, ActionControls } from './components/Controls.jsx';
import { StatusBadge } from './components/StatusBadge.jsx';
import { LogTail } from './components/LogTail.jsx';
import {
  fetchSeries,
  fetchState,
  fetchLogs,
  postSample,
  postInterval,
} from './api.js';

function useToast() {
  const [msg, setMsg] = useState(null);
  const timer = useRef(null);
  const show = useCallback((text, ms = 2500) => {
    setMsg(text);
    if (timer.current) clearTimeout(timer.current);
    timer.current = setTimeout(() => setMsg(null), ms);
  }, []);
  return [msg, show];
}

const LOOKBACK_SECONDS = {
  '30m': 30 * 60,
  '1h': 3600,
  '3h': 3 * 3600,
  '12h': 12 * 3600,
  '24h': 24 * 3600,
};

function computeLookbackBounds(lookback) {
  if (!lookback) return null;
  const now = Date.now() / 1000;
  if (lookback === 'midnight') {
    const d = new Date();
    d.setHours(0, 0, 0, 0);
    return { from: Math.floor(d.getTime() / 1000), to: Math.floor(now) };
  }
  const span = LOOKBACK_SECONDS[lookback];
  if (!span) return null;
  return { from: Math.floor(now - span), to: Math.floor(now) };
}

export default function App() {
  const [bucket, setBucket] = useState('1h');
  const [range, setRange] = useState([]);
  const [lookback, setLookback] = useState('');
  const [series, setSeries] = useState({ points: [], total: 0, bucket_sec: 3600 });
  const [state, setState] = useState({ interval_min: 30, last_sample_ts: null, sampling: false });
  const [logs, setLogs] = useState('');
  const [toast, showToast] = useToast();

  const rangeBounds = useMemo(() => {
    if (lookback) return computeLookbackBounds(lookback) || { from: null, to: null };
    if (range.length === 2) {
      const from = Math.floor(range[0].getTime() / 1000);
      const to = Math.floor((range[1].getTime() + 24 * 3600 * 1000 - 1) / 1000);
      return { from, to };
    }
    return { from: null, to: null };
  }, [range, lookback]);

  const loadSeries = useCallback(async () => {
    try {
      const s = await fetchSeries({ bucket, from: rangeBounds.from, to: rangeBounds.to });
      setSeries(s);
    } catch (e) {
      showToast('series error: ' + e.message, 4000);
    }
  }, [bucket, rangeBounds.from, rangeBounds.to, showToast]);

  const loadState = useCallback(async () => {
    try {
      setState(await fetchState());
    } catch (e) {
      showToast('state error: ' + e.message, 4000);
    }
  }, [showToast]);

  const loadLogs = useCallback(async () => {
    try {
      setLogs(await fetchLogs({ limit: 200 }));
    } catch (e) {
      showToast('logs error: ' + e.message, 4000);
    }
  }, [showToast]);

  const refreshAll = useCallback(async () => {
    await Promise.all([loadSeries(), loadState(), loadLogs()]);
  }, [loadSeries, loadState, loadLogs]);

  useEffect(() => {
    refreshAll();
    const t = setInterval(loadState, 30_000);
    return () => clearInterval(t);
  }, [refreshAll, loadState]);

  useEffect(() => {
    if (!state.sampling) return;
    const id = setInterval(async () => {
      const st = await fetchState();
      setState(st);
      if (!st.sampling) {
        loadSeries();
        loadLogs();
      }
    }, 2000);
    return () => clearInterval(id);
  }, [state.sampling, loadSeries, loadLogs]);

  const onSample = useCallback(async () => {
    try {
      const r = await postSample();
      if (r.started) {
        showToast('sample started');
        setState((s) => ({ ...s, sampling: true }));
      } else {
        showToast('already running');
      }
    } catch (e) {
      showToast('sample error: ' + e.message, 4000);
    }
  }, [showToast]);

  const onIntervalChange = useCallback(
    async (m) => {
      try {
        const r = await postInterval(m);
        setState((s) => ({ ...s, interval_min: r.interval_min }));
        showToast(r.interval_min ? `auto: every ${r.interval_min}m` : 'auto: off');
      } catch (e) {
        showToast('interval error: ' + e.message, 4000);
      }
    },
    [showToast]
  );

  const onRangeChange = useCallback((dates) => {
    setRange(dates);
    if (dates.length === 2) setLookback('');
  }, []);

  const onLookbackChange = useCallback((value) => {
    setLookback(value);
    if (value) setRange([]);
  }, []);

  const onClearAll = useCallback(() => {
    setRange([]);
    setLookback('');
  }, []);

  const vpnPoints = useMemo(() => series.points.filter((p) => p.profile === 'vpn'), [series.points]);
  const modemPoints = useMemo(() => series.points.filter((p) => p.profile === 'modem'), [series.points]);

  const meta = useMemo(() => {
    let rng = ' · range=все время';
    if (rangeBounds.from && rangeBounds.to) {
      const fromStr = new Date(rangeBounds.from * 1000).toLocaleString('ru-RU');
      const toStr = new Date(rangeBounds.to * 1000).toLocaleString('ru-RU');
      rng = ` · range=${fromStr}…${toStr}`;
    }
    return `bucket=${series.bucket_sec}s · points=${series.points.length}/${series.total ?? 0}${rng}`;
  }, [series, rangeBounds]);

  return (
    <div className="app">
      <header className="header">
        <div>
          <h1>Speed Monitor</h1>
          <div className="muted">{meta}</div>
        </div>
        <StatusBadge state={state} />
      </header>

      <ViewControls
        bucket={bucket}
        onBucketChange={setBucket}
        range={range}
        onRangeChange={onRangeChange}
        lookback={lookback}
        onLookbackChange={onLookbackChange}
        onClearAll={onClearAll}
        onRefresh={refreshAll}
      />

      <ActionControls
        onSample={onSample}
        sampling={state.sampling}
        intervalMin={state.interval_min}
        onIntervalChange={onIntervalChange}
      />

      <div className="charts">
        <SpeedChart points={vpnPoints} title="VPN" />
        <SpeedChart points={modemPoints} title="Modem" />
      </div>

      <LogTail text={logs} onRefresh={loadLogs} />

      {toast && <div className="toast">{toast}</div>}
    </div>
  );
}
