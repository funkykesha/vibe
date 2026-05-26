#!/usr/bin/env python3
"""Internet speed monitor: VPN + modem profiles, local dashboard."""
from __future__ import annotations

import argparse
import json
import logging
import os
import re
import shutil
import socket
import subprocess
import sys
import threading
import time
from collections import defaultdict
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from statistics import median
from urllib.parse import parse_qs, urlparse

ROOT = Path(__file__).resolve().parent
DATA_FILE = ROOT / "data" / "speed-tests.ndjson"
LOG_FILE = ROOT / "logs" / "internet-speed.log"
MODEM_IFACE = os.environ.get("SPEED_MODEM_IFACE", "en0")
CACHEFLY_URL = "https://cachefly.cachefly.net/10mb.test"
CLOUDFLARE_UP = "https://speed.cloudflare.com/__up"
IPIFY_URL = "https://api.ipify.org"
PING_TARGET = "1.1.1.1"

LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
DATA_FILE.parent.mkdir(parents=True, exist_ok=True)

logger = logging.getLogger("speedmon")
logger.setLevel(logging.INFO)
_fmt = logging.Formatter("%(asctime)s %(levelname)s %(message)s")
_fh = logging.FileHandler(LOG_FILE)
_fh.setFormatter(_fmt)
_sh = logging.StreamHandler(sys.stdout)
_sh.setFormatter(_fmt)
logger.addHandler(_fh)
logger.addHandler(_sh)


def run(cmd: list[str], timeout: int = 60) -> tuple[int, str, str]:
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return p.returncode, p.stdout, p.stderr
    except subprocess.TimeoutExpired as e:
        return 124, e.stdout or "", e.stderr or f"timeout after {timeout}s"
    except FileNotFoundError as e:
        return 127, "", str(e)


def iface_ip(iface: str) -> str | None:
    rc, out, _ = run(["ifconfig", iface], timeout=5)
    if rc != 0:
        return None
    m = re.search(r"inet (\d+\.\d+\.\d+\.\d+)", out)
    return m.group(1) if m else None


def default_route_iface() -> str | None:
    rc, out, _ = run(["route", "-n", "get", "default"], timeout=5)
    if rc != 0:
        return None
    m = re.search(r"interface:\s*(\S+)", out)
    return m.group(1) if m else None


def public_ip(interface: str | None = None) -> str | None:
    cmd = ["curl", "-s", "--max-time", "8"]
    if interface:
        cmd += ["--interface", interface]
    cmd.append(IPIFY_URL)
    rc, out, _ = run(cmd, timeout=10)
    out = out.strip()
    if rc == 0 and re.match(r"^\d+\.\d+\.\d+\.\d+$", out):
        return out
    return None


def sample_vpn() -> dict:
    rec = {
        "ts": time.time(),
        "profile": "vpn",
        "method": "networkQuality",
        "ok": False,
    }
    t0 = time.time()
    rc, out, err = run(["networkQuality", "-c"], timeout=120)
    rec["duration_sec"] = round(time.time() - t0, 2)
    if rc != 0:
        rec["error"] = (err or out)[:500]
        return rec
    try:
        j = json.loads(out)
    except json.JSONDecodeError as e:
        rec["error"] = f"json: {e}"
        return rec
    dl_bps = j.get("dl_throughput")
    ul_bps = j.get("ul_throughput")
    rec["interface_name"] = j.get("interface_name")
    rec["download_mbps"] = round(dl_bps / 1_000_000, 2) if dl_bps else None
    rec["upload_mbps"] = round(ul_bps / 1_000_000, 2) if ul_bps else None
    rec["ping_ms"] = round(j.get("base_rtt", 0), 2) or None
    rec["public_ip"] = public_ip()
    rec["ok"] = rec["download_mbps"] is not None
    return rec


def curl_download_mbps(iface: str, url: str, timeout: int = 30) -> tuple[float | None, str | None]:
    cmd = [
        "curl", "-o", "/dev/null", "--silent", "--show-error",
        "--max-time", str(timeout),
        "--interface", iface,
        "-w", "%{speed_download} %{size_download} %{http_code}",
        url,
    ]
    rc, out, err = run(cmd, timeout=timeout + 5)
    if rc != 0:
        return None, (err or out)[:300]
    parts = out.strip().split()
    if len(parts) != 3:
        return None, f"bad output: {out!r}"
    bps = float(parts[0]) * 8
    code = parts[2]
    if code != "200" or bps <= 0:
        return None, f"http={code} bps={bps}"
    return round(bps / 1_000_000, 2), None


def curl_upload_mbps(iface: str, url: str, size_mb: int = 5, timeout: int = 30) -> tuple[float | None, str | None]:
    payload = b"x" * (size_mb * 1024 * 1024)
    cmd = [
        "curl", "-o", "/dev/null", "--silent", "--show-error",
        "--max-time", str(timeout),
        "--interface", iface,
        "-X", "POST",
        "--data-binary", "@-",
        "-H", "Content-Type: application/octet-stream",
        "-w", "%{speed_upload} %{http_code}",
        url,
    ]
    try:
        p = subprocess.run(cmd, input=payload, capture_output=True, timeout=timeout + 5)
    except subprocess.TimeoutExpired:
        return None, "timeout"
    if p.returncode != 0:
        return None, (p.stderr.decode(errors="ignore") or p.stdout.decode(errors="ignore"))[:300]
    out = p.stdout.decode(errors="ignore").strip()
    parts = out.split()
    if len(parts) != 2:
        return None, f"bad output: {out!r}"
    bps = float(parts[0]) * 8
    code = parts[1]
    if code not in ("200", "201", "204") or bps <= 0:
        return None, f"http={code} bps={bps}"
    return round(bps / 1_000_000, 2), None


def ping_ms(source_ip: str, target: str = PING_TARGET, count: int = 5) -> tuple[float | None, str | None]:
    rc, out, err = run(["ping", "-S", source_ip, "-c", str(count), target], timeout=15)
    if rc != 0:
        return None, (err or out)[:300]
    m = re.search(r"min/avg/max/\S+\s*=\s*[\d.]+/([\d.]+)/", out)
    if not m:
        return None, "no rtt"
    return round(float(m.group(1)), 2), None


def sample_modem(vpn_public: str | None) -> dict:
    rec = {
        "ts": time.time(),
        "profile": "modem",
        "interface_name": MODEM_IFACE,
        "ok": False,
    }
    t0 = time.time()
    src = iface_ip(MODEM_IFACE)
    rec["source_ip"] = src
    if not src:
        rec["error"] = f"no IP on {MODEM_IFACE}"
        rec["duration_sec"] = round(time.time() - t0, 2)
        return rec
    pub = public_ip(MODEM_IFACE)
    rec["public_ip"] = pub
    rec["bypass_verified"] = bool(pub and vpn_public and pub != vpn_public)

    dl, dl_err = curl_download_mbps(MODEM_IFACE, CACHEFLY_URL)
    rec["download_mbps"] = dl
    rec["method"] = "curl-bound"

    ul, ul_err = curl_upload_mbps(MODEM_IFACE, CLOUDFLARE_UP)
    rec["upload_mbps"] = ul

    pm, p_err = ping_ms(src)
    rec["ping_ms"] = pm

    errs = [e for e in (dl_err, ul_err, p_err) if e]
    if errs:
        rec["error"] = " | ".join(errs)[:500]
    rec["ok"] = dl is not None and pm is not None
    rec["duration_sec"] = round(time.time() - t0, 2)
    return rec


def append_record(rec: dict) -> None:
    with DATA_FILE.open("a") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")


def cmd_sample(_args) -> int:
    logger.info("sample start")
    vpn = sample_vpn()
    append_record(vpn)
    logger.info("vpn: dl=%s ul=%s ping=%s iface=%s ok=%s",
                vpn.get("download_mbps"), vpn.get("upload_mbps"),
                vpn.get("ping_ms"), vpn.get("interface_name"), vpn["ok"])
    modem = sample_modem(vpn.get("public_ip"))
    append_record(modem)
    logger.info("modem: dl=%s ul=%s ping=%s bypass=%s ok=%s err=%s",
                modem.get("download_mbps"), modem.get("upload_mbps"),
                modem.get("ping_ms"), modem.get("bypass_verified"),
                modem["ok"], modem.get("error"))
    return 0


def cmd_doctor(_args) -> int:
    print("=== doctor ===")
    print(f"MODEM_IFACE: {MODEM_IFACE}")
    src = iface_ip(MODEM_IFACE)
    print(f"  {MODEM_IFACE} ip: {src}")
    print(f"  default route iface: {default_route_iface()}")
    pub_def = public_ip()
    pub_en0 = public_ip(MODEM_IFACE)
    print(f"  public ip (default): {pub_def}")
    print(f"  public ip ({MODEM_IFACE}): {pub_en0}")
    print(f"  bypass differs: {pub_def != pub_en0 and bool(pub_def and pub_en0)}")
    print(f"  tools: networkQuality={shutil.which('networkQuality')} curl={shutil.which('curl')} ping={shutil.which('ping')}")
    rc, out, _ = run(["curl", "-sI", "--max-time", "8", "--interface", MODEM_IFACE, CACHEFLY_URL], timeout=10)
    print(f"  cachefly probe rc={rc} first-line={out.splitlines()[0] if out else ''}")
    rc, out, _ = run(["curl", "-sI", "--max-time", "8", CLOUDFLARE_UP], timeout=10)
    print(f"  cloudflare-up probe rc={rc} first-line={out.splitlines()[0] if out else ''}")
    return 0


# ---------- dashboard ----------

BUCKET_SEC = {"1m": 60, "5m": 300, "30m": 1800, "1h": 3600, "3h": 10800, "6h": 21600, "12h": 43200, "1d": 86400}


def load_records(limit: int | None = None) -> list[dict]:
    if not DATA_FILE.exists():
        return []
    recs = []
    with DATA_FILE.open() as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                recs.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    if limit:
        recs = recs[-limit:]
    return recs


def _trimmed_median(vals: list[float]) -> float | None:
    vals = [v for v in vals if v is not None]
    if not vals:
        return None
    if len(vals) < 3:
        return round(median(vals), 2)
    s = sorted(vals)
    n = len(s)
    lo = max(0, int(n * 0.1))
    hi = max(lo + 1, int(n * 0.9 + 0.5))
    trimmed = s[lo:hi] or s
    return round(median(trimmed), 2)


def aggregate(recs: list[dict], bucket_sec: int, ts_from: float | None = None, ts_to: float | None = None) -> dict:
    buckets: dict[tuple[int, str], list[dict]] = defaultdict(list)
    for r in recs:
        ts = r.get("ts")
        prof = r.get("profile")
        if not ts or not prof:
            continue
        if ts_from is not None and ts < ts_from:
            continue
        if ts_to is not None and ts > ts_to:
            continue
        b = int(ts // bucket_sec) * bucket_sec
        buckets[(b, prof)].append(r)
    out = []
    for (b, prof), bucket_recs in sorted(buckets.items()):
        dls = [r.get("download_mbps") for r in bucket_recs if r.get("download_mbps") is not None]
        uls = [r.get("upload_mbps") for r in bucket_recs if r.get("upload_mbps") is not None]
        pings = [r.get("ping_ms") for r in bucket_recs if r.get("ping_ms") is not None]
        out.append({
            "ts": b,
            "profile": prof,
            "count": len(bucket_recs),
            "download_mbps": _trimmed_median(dls),
            "upload_mbps": _trimmed_median(uls),
            "ping_ms": _trimmed_median(pings),
        })
    return {"bucket_sec": bucket_sec, "points": out}


INDEX_HTML = r"""<!doctype html>
<html lang="ru"><head>
<meta charset="utf-8">
<title>Internet Speed Monitor</title>
<meta http-equiv="Cache-Control" content="no-store">
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chartjs-adapter-date-fns@3.0.0/dist/chartjs-adapter-date-fns.bundle.min.js"></script>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr@4.6.13/dist/flatpickr.min.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr@4.6.13/dist/themes/dark.css">
<script src="https://cdn.jsdelivr.net/npm/flatpickr@4.6.13/dist/flatpickr.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/flatpickr@4.6.13/dist/l10n/ru.js"></script>
<style>
  body{font:14px/1.4 -apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;margin:16px;background:#0f1115;color:#d8dde6}
  h1{font-size:18px;margin:0 0 12px}
  h2{font-size:14px;margin:18px 0 8px;color:#9aa3b2}
  .row{display:flex;gap:10px;align-items:center;margin-bottom:12px;flex-wrap:wrap}
  select,button{background:#1c2030;color:#d8dde6;border:1px solid #2c3142;border-radius:6px;padding:7px 12px;font:inherit;cursor:pointer}
  button:hover{background:#252b3d}
  button:disabled{opacity:.5;cursor:wait}
  button.primary{background:#3a5ce6;border-color:#4a6cff}
  button.primary:hover{background:#4a6cff}
  .badge{font-size:12px;color:#9aa3b2;padding:4px 8px;background:#1c2030;border:1px solid #232838;border-radius:6px}
  .charts{display:grid;grid-template-columns:1fr 1fr;gap:12px}
  @media (max-width:1000px){.charts{grid-template-columns:1fr}}
  .card{background:#161a26;border:1px solid #232838;border-radius:8px;padding:12px}
  .card h3{margin:0 0 8px;font-size:13px;color:#d8dde6}
  .card canvas{max-height:300px}
  pre{background:#0c0f17;border:1px solid #232838;border-radius:8px;padding:10px;max-height:300px;overflow:auto;font-size:12px;white-space:pre-wrap}
  .meta{color:#7a8295;font-size:12px;margin-top:6px}
  #toast{position:fixed;right:16px;bottom:16px;background:#1c2030;border:1px solid #3a5ce6;color:#d8dde6;padding:10px 14px;border-radius:8px;opacity:0;transition:opacity .3s;font-size:13px;pointer-events:none}
  #toast.show{opacity:1}
</style></head><body>
<h1>Internet Speed Monitor</h1>
<div class="row">
  <label>Bucket:
    <select id="bucket">
      <option value="1m">1m</option>
      <option value="5m">5m</option>
      <option value="30m">30m</option>
      <option value="1h" selected>1h</option>
      <option value="3h">3h</option>
      <option value="6h">6h</option>
      <option value="12h">12h</option>
      <option value="1d">1d</option>
    </select>
  </label>
  <label>Auto-sample каждые:
    <select id="interval">
      <option value="5">5 мин</option>
      <option value="10">10 мин</option>
      <option value="15">15 мин</option>
      <option value="30" selected>30 мин</option>
      <option value="60">1 час</option>
      <option value="120">2 часа</option>
      <option value="0">выкл</option>
    </select>
  </label>
  <label>Период:
    <input id="range" type="text" placeholder="выбрать даты" readonly style="min-width:220px">
  </label>
  <button id="all-time">Все время</button>
  <button id="refresh">↻ Refresh</button>
  <button id="sample" class="primary">▶ Sample now</button>
  <span class="badge" id="state">…</span>
</div>

<div class="charts">
  <div class="card">
    <h3>VPN (utun)</h3>
    <canvas id="chart-vpn"></canvas>
  </div>
  <div class="card">
    <h3>Modem (en0, bypass)</h3>
    <canvas id="chart-modem"></canvas>
  </div>
</div>
<div class="meta" id="meta"></div>

<h2>Recent logs</h2>
<pre id="logs">loading…</pre>

<div id="toast"></div>

<script>
const COLORS = {dl:'#4cc9f0', ul:'#90e0ef', ping:'#ffd166', count:'#3a3f55'};
let charts = {};
let rangePicker = null;
let rangeFrom = null, rangeTo = null;

function toast(msg, ms=2000){
  const t=document.getElementById('toast');
  t.textContent=msg; t.classList.add('show');
  clearTimeout(toast._t);
  toast._t=setTimeout(()=>t.classList.remove('show'), ms);
}

function buildChart(canvasId){
  const ctx=document.getElementById(canvasId).getContext('2d');
  return new Chart(ctx, {
    data: {
      datasets: [
        {type:'line', label:'Download Mbps', yAxisID:'speed', borderColor:COLORS.dl, backgroundColor:COLORS.dl, tension:0.25, pointRadius:3, data:[]},
        {type:'line', label:'Upload Mbps', yAxisID:'speed', borderColor:COLORS.ul, backgroundColor:COLORS.ul, tension:0.25, pointRadius:3, data:[]},
        {type:'line', label:'Ping ms', yAxisID:'ping', borderColor:COLORS.ping, backgroundColor:COLORS.ping, tension:0.25, pointRadius:3, data:[], borderDash:[4,3]},
        {type:'bar', label:'Count', yAxisID:'count', backgroundColor:COLORS.count, data:[]}
      ]
    },
    options: {
      responsive:true, maintainAspectRatio:false, animation:false,
      interaction:{mode:'index', intersect:false},
      scales: {
        x: {type:'time', time:{tooltipFormat:'PPpp'}, ticks:{color:'#7a8295'}, grid:{color:'#232838'}},
        speed: {position:'left', title:{display:true,text:'Mbps',color:'#9aa3b2'}, ticks:{color:'#7a8295'}, grid:{color:'#232838'}, beginAtZero:true},
        ping: {position:'right', title:{display:true,text:'ms',color:'#9aa3b2'}, ticks:{color:'#7a8295'}, grid:{drawOnChartArea:false}, beginAtZero:true},
        count: {display:false, beginAtZero:true}
      },
      plugins: {legend:{labels:{color:'#d8dde6'}}, tooltip:{backgroundColor:'#1c2030', borderColor:'#3a5ce6', borderWidth:1}}
    }
  });
}

function pointsFor(series, profile){
  return series.points.filter(p=>p.profile===profile)
    .map(p=>({...p, x: new Date(p.ts*1000)}));
}

function applySeries(chart, pts){
  chart.data.datasets[0].data = pts.map(p=>({x:p.x, y:p.download_mbps}));
  chart.data.datasets[1].data = pts.map(p=>({x:p.x, y:p.upload_mbps}));
  chart.data.datasets[2].data = pts.map(p=>({x:p.x, y:p.ping_ms}));
  chart.data.datasets[3].data = pts.map(p=>({x:p.x, y:p.count}));
  chart.update();
}

function buildSeriesUrl(){
  const bucket=document.getElementById('bucket').value;
  const params=new URLSearchParams({bucket});
  if(rangeFrom) params.set('from', String(Math.floor(rangeFrom/1000)));
  if(rangeTo) params.set('to', String(Math.floor(rangeTo/1000)));
  return '/api/series?'+params.toString();
}

async function refresh(){
  try {
    const s=await fetch(buildSeriesUrl(), {cache:'no-store'}).then(r=>r.json());
    applySeries(charts.vpn, pointsFor(s,'vpn'));
    applySeries(charts.modem, pointsFor(s,'modem'));
    const rng = (rangeFrom && rangeTo)
      ? ' · range='+new Date(rangeFrom).toLocaleDateString('ru-RU')+'…'+new Date(rangeTo).toLocaleDateString('ru-RU')
      : ' · range=все время';
    document.getElementById('meta').textContent =
      'bucket='+s.bucket_sec+'s · points='+s.points.length+'/'+s.total+rng+' · updated='+new Date().toLocaleTimeString('ru-RU');
    const logs=await fetch('/api/logs?limit=300', {cache:'no-store'}).then(r=>r.text());
    document.getElementById('logs').textContent=logs;
    await loadState();
  } catch(e){ toast('refresh error: '+e.message, 4000); }
}

async function loadState(){
  const st=await fetch('/api/state', {cache:'no-store'}).then(r=>r.json());
  const last = st.last_sample_ts ? new Date(st.last_sample_ts*1000).toLocaleTimeString('ru-RU') : '—';
  const running = st.sampling ? ' · ⚡ running' : '';
  document.getElementById('state').textContent =
    'interval: '+(st.interval_min||'off')+'m · last: '+last+running;
  document.getElementById('interval').value=String(st.interval_min||0);
}

async function triggerSample(){
  const btn=document.getElementById('sample');
  btn.disabled=true; btn.textContent='⏳ running…';
  try {
    const r=await fetch('/api/sample', {method:'POST'});
    const j=await r.json();
    if(j.started){ toast('sample started'); }
    else { toast('already running'); }
  } catch(e){ toast('error: '+e.message, 4000); }
  // poll state until done
  const poll=setInterval(async()=>{
    const st=await fetch('/api/state', {cache:'no-store'}).then(r=>r.json());
    if(!st.sampling){ clearInterval(poll); btn.disabled=false; btn.textContent='▶ Sample now'; refresh(); }
  }, 2000);
}

async function setInterval_(){
  const m=parseInt(document.getElementById('interval').value,10);
  const r=await fetch('/api/interval?minutes='+m, {method:'POST'});
  const j=await r.json();
  toast('auto-sample: '+(j.interval_min ? 'every '+j.interval_min+'m' : 'off'));
  loadState();
}

function clearRange(){
  rangeFrom=null; rangeTo=null;
  if(rangePicker) rangePicker.clear();
  refresh();
}

document.getElementById('refresh').onclick=refresh;
document.getElementById('sample').onclick=triggerSample;
document.getElementById('bucket').onchange=refresh;
document.getElementById('interval').onchange=setInterval_;
document.getElementById('all-time').onclick=clearRange;

window.addEventListener('DOMContentLoaded', ()=>{
  charts.vpn=buildChart('chart-vpn');
  charts.modem=buildChart('chart-modem');
  rangePicker = flatpickr('#range', {
    mode: 'range',
    locale: 'ru',
    dateFormat: 'Y-m-d',
    onClose: (dates) => {
      if(dates.length === 2){
        rangeFrom = dates[0].getTime();
        rangeTo = dates[1].getTime() + 24*3600*1000 - 1;
        refresh();
      } else if(dates.length === 0){
        rangeFrom = null; rangeTo = null;
        refresh();
      }
    }
  });
  refresh();
  setInterval(refresh, 30000);
});
</script></body></html>
"""


class Scheduler:
    """In-process background sampler with adjustable interval."""

    def __init__(self, interval_min: int = 30) -> None:
        self._interval = interval_min
        self._lock = threading.Lock()
        self._wake = threading.Event()
        self._stop = threading.Event()
        self._sampling = False
        self._last_sample_ts: float | None = None
        self._thread = threading.Thread(target=self._loop, daemon=True)

    def start(self) -> None:
        self._thread.start()

    def stop(self) -> None:
        self._stop.set()
        self._wake.set()

    @property
    def state(self) -> dict:
        with self._lock:
            return {
                "interval_min": self._interval,
                "last_sample_ts": self._last_sample_ts,
                "sampling": self._sampling,
            }

    def set_interval(self, minutes: int) -> int:
        with self._lock:
            self._interval = max(0, int(minutes))
        self._wake.set()
        return self._interval

    def trigger(self) -> bool:
        """Request immediate sample. Returns True if started, False if busy."""
        with self._lock:
            if self._sampling:
                return False
        self._wake.set()
        return True

    def _run_once(self) -> None:
        with self._lock:
            self._sampling = True
        try:
            vpn = sample_vpn()
            append_record(vpn)
            logger.info("vpn: dl=%s ul=%s ping=%s iface=%s ok=%s",
                        vpn.get("download_mbps"), vpn.get("upload_mbps"),
                        vpn.get("ping_ms"), vpn.get("interface_name"), vpn["ok"])
            modem = sample_modem(vpn.get("public_ip"))
            append_record(modem)
            logger.info("modem: dl=%s ul=%s ping=%s bypass=%s ok=%s err=%s",
                        modem.get("download_mbps"), modem.get("upload_mbps"),
                        modem.get("ping_ms"), modem.get("bypass_verified"),
                        modem["ok"], modem.get("error"))
        except Exception as e:
            logger.exception("sample failed: %s", e)
        finally:
            with self._lock:
                self._sampling = False
                self._last_sample_ts = time.time()

    def _loop(self) -> None:
        # initial sample shortly after start
        self._wake.wait(timeout=5)
        while not self._stop.is_set():
            self._wake.clear()
            self._run_once()
            with self._lock:
                interval = self._interval
            if interval <= 0:
                # disabled — wait for wake (trigger or interval change)
                self._wake.wait()
            else:
                self._wake.wait(timeout=interval * 60)


SCHEDULER: Scheduler | None = None


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        logger.debug("http %s - %s", self.address_string(), fmt % args)

    def _send(self, code: int, ctype: str, body: bytes, *, no_cache: bool = True) -> None:
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        if no_cache:
            self.send_header("Cache-Control", "no-store, must-revalidate")
            self.send_header("Pragma", "no-cache")
        self.end_headers()
        self.wfile.write(body)

    def _json(self, code: int, obj) -> None:
        self._send(code, "application/json", json.dumps(obj).encode("utf-8"))

    def do_GET(self):
        u = urlparse(self.path)
        if u.path == "/":
            self._send(200, "text/html; charset=utf-8", INDEX_HTML.encode("utf-8"))
            return
        if u.path == "/api/series":
            q = parse_qs(u.query)
            bucket = q.get("bucket", ["1h"])[0]
            sec = BUCKET_SEC.get(bucket, 3600)
            ts_from = float(q["from"][0]) if q.get("from") and q["from"][0] else None
            ts_to = float(q["to"][0]) if q.get("to") and q["to"][0] else None
            recs = load_records()
            payload = aggregate(recs, sec, ts_from, ts_to)
            payload["from"] = ts_from
            payload["to"] = ts_to
            payload["total"] = len(recs)
            self._json(200, payload)
            return
        if u.path == "/api/logs":
            q = parse_qs(u.query)
            limit = int(q.get("limit", ["200"])[0])
            if LOG_FILE.exists():
                with LOG_FILE.open() as f:
                    lines = f.readlines()[-limit:]
                self._send(200, "text/plain; charset=utf-8", "".join(lines).encode("utf-8"))
            else:
                self._send(200, "text/plain; charset=utf-8", b"")
            return
        if u.path == "/api/state":
            self._json(200, SCHEDULER.state if SCHEDULER else {"interval_min": 0, "last_sample_ts": None, "sampling": False})
            return
        self._send(404, "text/plain", b"not found")

    def do_POST(self):
        u = urlparse(self.path)
        if u.path == "/api/sample":
            started = SCHEDULER.trigger() if SCHEDULER else False
            self._json(200, {"started": started})
            return
        if u.path == "/api/interval":
            q = parse_qs(u.query)
            m = int(q.get("minutes", ["30"])[0])
            new_int = SCHEDULER.set_interval(m) if SCHEDULER else m
            self._json(200, {"interval_min": new_int})
            return
        self._send(404, "text/plain", b"not found")


def cmd_server(args) -> int:
    global SCHEDULER
    interval = int(os.environ.get("SPEED_INTERVAL_MIN", "30"))
    SCHEDULER = Scheduler(interval_min=interval)
    SCHEDULER.start()
    addr = (args.host, args.port)
    srv = ThreadingHTTPServer(addr, Handler)
    logger.info("server listening http://%s:%s scheduler=%dm", addr[0], addr[1], interval)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        logger.info("server stop")
    finally:
        SCHEDULER.stop()
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("sample").set_defaults(func=cmd_sample)
    sub.add_parser("doctor").set_defaults(func=cmd_doctor)
    srv = sub.add_parser("server")
    srv.add_argument("--host", default="127.0.0.1")
    srv.add_argument("--port", type=int, default=9876)
    srv.set_defaults(func=cmd_server)
    args = parser.parse_args()
    sys.exit(args.func(args))
