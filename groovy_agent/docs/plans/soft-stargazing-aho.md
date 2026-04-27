# Plan: Request Analytics

## Context

В groovy_agent нет аналитики запросов. Пользователь не видит, сколько токенов потрачено, какие модели и кубики используются, насколько успешны запросы. Нужна минимальная система: лог на диск + эндпоинт + простая UI-панель.

---

## Scope

Логировать два типа событий:
- `chat` — каждый `/api/chat` запрос (модель, тип кубика, токены, длительность)
- `execute` — каждый `/api/execute` запрос (успех, длительность)

---

## Data Model

Файл `analytics.jsonl` в корне проекта — JSON Lines, один объект на строку.

**Chat entry:**
```json
{
  "ts": "2024-01-15T10:30:00.000Z",
  "type": "chat",
  "model": "anthropic/claude-3-5-sonnet",
  "cubeType": "json-filter",
  "messagesCount": 3,
  "promptTokens": 1500,
  "completionTokens": 300,
  "totalTokens": 1800,
  "durationMs": 2340,
  "success": true
}
```

**Execute entry:**
```json
{
  "ts": "2024-01-15T10:30:05.000Z",
  "type": "execute",
  "durationMs": 450,
  "success": true
}
```

Токены берутся из `usage` объекта, который уже приходит от Eliza API (строка 44 server.js: `if (obj.usage) yield { delta: '', done: false, usage: obj.usage }`) — нужно только захватить его в streaming loop.

---

## Backend Changes (`server.js`)

### 1. Константа и функция логирования

После строки с `RULES_FILE` добавить:
```js
const ANALYTICS_FILE = path.join(__dirname, 'analytics.jsonl');

function logEvent(entry) {
  try {
    fs.appendFileSync(ANALYTICS_FILE, JSON.stringify(entry) + '\n');
  } catch {}
}
```

### 2. Захват usage в `/api/chat` (строки 134–139)

Текущий loop игнорирует `usage`. Изменить:
```js
let usage = null;
const startTs = Date.now();
for await (const { delta, done, error, usage: u } of eliza.chat(...)) {
  if (u) usage = u;
  if (!clientConnected) break;
  if (error) { safeWrite(...); break; }
  if (done)  { safeWrite('data: [DONE]\n\n'); break; }
  if (delta) safeWrite(...);
}
// После loop:
logEvent({
  ts: new Date().toISOString(),
  type: 'chat',
  model,
  cubeType: cubeType || null,
  messagesCount: messages?.length ?? 0,
  promptTokens: usage?.prompt_tokens ?? null,
  completionTokens: usage?.completion_tokens ?? null,
  totalTokens: usage?.total_tokens ?? null,
  durationMs: Date.now() - startTs,
  success: !clientDisconnected,
});
```

### 3. Логирование в `/api/execute` (строки 148–186)

```js
const startTs = Date.now();
const result = await runProcess(groovyCmd, [scriptFile], inputData || '{}', 30000);
logEvent({
  ts: new Date().toISOString(),
  type: 'execute',
  durationMs: Date.now() - startTs,
  success: !result.error,
});
res.json(result);
```

### 4. Эндпоинт `/api/analytics`

```js
app.get('/api/analytics', (req, res) => {
  try {
    const raw = fs.existsSync(ANALYTICS_FILE)
      ? fs.readFileSync(ANALYTICS_FILE, 'utf8').trim()
      : '';
    const entries = raw ? raw.split('\n').map(l => JSON.parse(l)) : [];
    const limit = Math.min(parseInt(req.query.limit) || 200, 1000);
    res.json(entries.slice(-limit).reverse()); // новые первыми
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});
```

---

## Frontend Changes (`public/index.html`)

### 1. Кнопка в toolbar

В шапку (рядом с другими кнопками) добавить:
```html
<button id="btn-analytics" onclick="openAnalytics()">Аналитика</button>
```

### 2. Модальное окно

```html
<div id="analytics-modal" class="modal" style="display:none">
  <div class="modal-content" style="max-width:800px">
    <div class="modal-header">
      <h3>Аналитика запросов</h3>
      <button onclick="closeAnalytics()">✕</button>
    </div>
    <div id="analytics-summary" style="margin-bottom:16px"></div>
    <table id="analytics-table" style="width:100%;font-size:13px;border-collapse:collapse"></table>
  </div>
</div>
```

### 3. JS функции

```js
async function openAnalytics() {
  document.getElementById('analytics-modal').style.display = 'flex';
  const data = await fetch('/api/analytics?limit=100').then(r => r.json());
  renderAnalytics(data);
}

function closeAnalytics() {
  document.getElementById('analytics-modal').style.display = 'none';
}

function renderAnalytics(entries) {
  // Summary stats
  const chats = entries.filter(e => e.type === 'chat');
  const execs = entries.filter(e => e.type === 'execute');
  const totalTokens = chats.reduce((s, e) => s + (e.totalTokens || 0), 0);
  document.getElementById('analytics-summary').innerHTML = `
    <b>Чатов:</b> ${chats.length} &nbsp;
    <b>Выполнений:</b> ${execs.length} &nbsp;
    <b>Токенов всего:</b> ${totalTokens.toLocaleString()}
  `;

  // Table
  const headers = ['Время', 'Тип', 'Модель', 'Кубик', 'Токены', 'Мс', 'Успех'];
  const rows = entries.map(e => [
    new Date(e.ts).toLocaleString('ru'),
    e.type,
    e.model || '—',
    e.cubeType || '—',
    e.totalTokens?.toLocaleString() || '—',
    e.durationMs,
    e.success ? '✓' : '✗',
  ]);
  const table = document.getElementById('analytics-table');
  table.innerHTML = `
    <tr>${headers.map(h => `<th style="text-align:left;padding:4px 8px;border-bottom:1px solid #444">${h}</th>`).join('')}</tr>
    ${rows.map(r => `<tr>${r.map(c => `<td style="padding:4px 8px;border-bottom:1px solid #333">${c}</td>`).join('')}</tr>`).join('')}
  `;
}
```

---

## Files to Modify

| Файл | Изменения |
|------|-----------|
| `server.js` | `logEvent()`, захват `usage` в chat loop, лог execute, `/api/analytics` endpoint |
| `public/index.html` | кнопка, модальное окно, 3 JS функции |

Новый файл `analytics.jsonl` создаётся автоматически при первом запросе.

---

## Verification

1. `npm run dev`
2. Отправить чат-запрос → проверить `analytics.jsonl` появился, запись содержит `promptTokens`
3. Выполнить код (F5) → вторая запись с `type: execute`
4. Открыть «Аналитика» в UI → таблица показывает оба события
5. `GET /api/analytics` напрямую → JSON массив, новые записи первыми
