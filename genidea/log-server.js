const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const PORT = 3001;
const LOGS_DIR = path.join(__dirname, 'logs');
const LOGS_FILE = path.join(LOGS_DIR, 'requests.jsonl');

if (!fs.existsSync(LOGS_DIR)) fs.mkdirSync(LOGS_DIR, { recursive: true });

const app = express();
app.use(cors({ origin: '*' }));
app.use(express.json({ limit: '1mb' }));

app.post('/log', (req, res) => {
  const entry = { ts: new Date().toISOString(), ...req.body };
  fs.appendFile(LOGS_FILE, JSON.stringify(entry) + '\n', (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ ok: true });
  });
});

app.get('/logs', (req, res) => {
  const limit = Math.min(parseInt(req.query.limit) || 100, 1000);
  if (!fs.existsSync(LOGS_FILE)) return res.json([]);
  const lines = fs.readFileSync(LOGS_FILE, 'utf8')
    .split('\n')
    .filter(Boolean)
    .slice(-limit)
    .map(l => { try { return JSON.parse(l); } catch { return null; } })
    .filter(Boolean);
  res.json(lines);
});

app.get('/', (req, res) => {
  const count = fs.existsSync(LOGS_FILE)
    ? fs.readFileSync(LOGS_FILE, 'utf8').split('\n').filter(Boolean).length
    : 0;
  res.send(`<pre>genidea log server\nentries: ${count}\nGET /logs?limit=100\nPOST /log</pre>`);
});

app.listen(PORT, () => console.log(`Log server: http://localhost:${PORT}`));
