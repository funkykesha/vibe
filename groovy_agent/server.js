require('dotenv').config();

const express = require('express');
const fs = require('fs');
const path = require('path');
const { spawn, execSync } = require('child_process');
const os = require('os');
const cors = require('cors');
const ELIZA_PROXY_URL = process.env.ELIZA_PROXY_URL;

function createProxyClient(baseUrl) {
  return {
    async getModels() {
      const r = await fetch(`${baseUrl}/v1/models`);
      if (!r.ok) throw new Error(`proxy models error: ${r.status}`);
      return r.json();
    },
    async* chat(model, messages, { system } = {}) {
      const r = await fetch(`${baseUrl}/v1/chat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model, messages, system }),
      });
      if (!r.ok) throw new Error(`proxy chat error: ${r.status}`);
      const reader  = r.body.getReader();
      const decoder = new TextDecoder();
      let buf = '';
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        buf += decoder.decode(value, { stream: true });
        const lines = buf.split('\n');
        buf = lines.pop();
        for (const line of lines) {
          if (!line.startsWith('data: ')) continue;
          const raw = line.slice(6).trim();
          if (raw === '[DONE]') { yield { delta: '', done: true }; return; }
          const obj = JSON.parse(raw);
          if (obj.error) yield { delta: '', done: true, error: obj.error };
          if (obj.text)  yield { delta: obj.text, done: false };
          if (obj.usage) yield { delta: '', done: false, usage: obj.usage };
        }
      }
    },
    async probe(model) {
      const r = await fetch(`${baseUrl}/v1/probe`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model }),
      });
      if (!r.ok) return false;
      const { available } = await r.json();
      return available;
    },
  };
}

const eliza = ELIZA_PROXY_URL ? createProxyClient(ELIZA_PROXY_URL) : null;

const app = express();
app.use(cors({ origin: '*' }));   // dev — для прода сузить до нужного origin
app.use(express.json({ limit: '10mb' }));
app.use(express.static(path.join(__dirname, 'public')));

const KNOWLEDGE_DIR = path.join(__dirname, 'knowledge');
const RULES_FILE = path.join(__dirname, 'rules.json');

// Ensure dirs exist
if (!fs.existsSync(KNOWLEDGE_DIR)) fs.mkdirSync(KNOWLEDGE_DIR, { recursive: true });
if (!fs.existsSync(RULES_FILE)) fs.writeFileSync(RULES_FILE, JSON.stringify({ rules: [] }, null, 2));

// ── Models ───────────────────────────────────────────────────────────────────

app.get('/api/models', async (req, res) => {
  if (!eliza) {
    res.status(500).json({ error: 'ELIZA_TOKEN не задан в .env' });
    return;
  }
  try {
    const { models, validated } = await eliza.getModels();
    res.json({ models, validated, updatedAt: new Date().toISOString() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Chat — streaming proxy to Eliza ─────────────────────────────────────────
app.post('/api/chat', async (req, res) => {
  const { messages, currentCode, inputData, model, system: systemOverride, cubeType } = req.body;

  if (!eliza) {
    res.status(500).json({ error: 'ELIZA_TOKEN не задан в .env' });
    return;
  }

  const systemPrompt = systemOverride
    ? systemOverride
    : buildSystemPrompt(loadKnowledge(), loadRules(), currentCode, inputData, cubeType);

  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();

  let clientConnected = true;
  res.on('close', () => { clientConnected = false; });
  res.on('error', () => { clientConnected = false; });

  function safeWrite(data) {
    if (!clientConnected || res.destroyed || res.writableEnded) return false;
    try { res.write(data); return true; } catch { clientConnected = false; return false; }
  }

  try {
    for await (const { delta, done, error } of eliza.chat(model, messages, { system: systemPrompt })) {
      if (!clientConnected) break;
      if (error) { safeWrite(`data: ${JSON.stringify({ error })}\n\n`); break; }
      if (done)  { safeWrite('data: [DONE]\n\n'); break; }
      if (delta) safeWrite(`data: ${JSON.stringify({ text: delta })}\n\n`);
    }
  } catch (err) {
    if (clientConnected) safeWrite(`data: ${JSON.stringify({ error: err.message })}\n\n`);
  } finally {
    if (!res.writableEnded) try { res.end(); } catch { /* already closed */ }
  }
});

// ── Execute Groovy script ────────────────────────────────────────────────────
app.post('/api/execute', async (req, res) => {
  const { code, inputData } = req.body;

  // Check groovy is available
  let groovyCmd = 'groovy';
  try {
    execSync('which groovy || groovy --version', { stdio: 'ignore' });
  } catch {
    // Try common installation paths
    const candidates = [
      '/usr/local/bin/groovy',
      '/opt/homebrew/bin/groovy',
      `${os.homedir()}/.sdkman/candidates/groovy/current/bin/groovy`,
    ];
    const found = candidates.find((p) => fs.existsSync(p));
    if (found) {
      groovyCmd = found;
    } else {
      res.json({
        output: null,
        error:
          'Groovy не установлен.\n\nУстановите через Homebrew:\n  brew install groovy\n\nИли через SDKMAN:\n  sdk install groovy',
      });
      return;
    }
  }

  const tmpDir = os.tmpdir();
  const scriptFile = path.join(tmpDir, `groovy_agent_${Date.now()}.groovy`);

  fs.writeFileSync(scriptFile, code);

  try {
    const result = await runProcess(groovyCmd, [scriptFile], inputData || '{}', 30000);
    res.json(result);
  } finally {
    try { fs.unlinkSync(scriptFile); } catch { /* ignore */ }
  }
});

function runProcess(cmd, args, stdin, timeout) {
  return new Promise((resolve) => {
    const proc = spawn(cmd, args);
    let stdout = '';
    let stderr = '';

    proc.stdout.on('data', (d) => { stdout += d; });
    proc.stderr.on('data', (d) => { stderr += d; });

    // Suppress EPIPE if child process exits before stdin is fully written
    proc.stdin.on('error', () => {});
    proc.stdin.write(stdin);
    proc.stdin.end();

    const timer = setTimeout(() => {
      proc.kill();
      resolve({ output: null, error: 'Timeout: выполнение превысило 30 секунд' });
    }, timeout);

    proc.on('close', (code) => {
      clearTimeout(timer);
      if (code === 0) {
        resolve({ output: stdout, error: stderr || null });
      } else {
        resolve({ output: stdout || null, error: stderr || `Exit code: ${code}` });
      }
    });

    proc.on('error', (err) => {
      clearTimeout(timer);
      resolve({ output: null, error: err.message });
    });
  });
}

// ── Knowledge base ───────────────────────────────────────────────────────────
app.get('/api/knowledge', (req, res) => {
  res.json(loadKnowledge());
});

app.post('/api/knowledge', (req, res) => {
  const { name, content } = req.body;
  if (!name || !content) { res.status(400).json({ error: 'name and content required' }); return; }
  const safe = name.replace(/[^a-zA-Z0-9_-]/g, '_');
  fs.writeFileSync(path.join(KNOWLEDGE_DIR, `${safe}.md`), content);
  res.json({ success: true, name: safe });
});

app.delete('/api/knowledge/:name', (req, res) => {
  const filePath = path.join(KNOWLEDGE_DIR, `${req.params.name}.md`);
  if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
  res.json({ success: true });
});

// ── Rules ────────────────────────────────────────────────────────────────────
app.get('/api/rules', (req, res) => {
  res.json({ rules: loadRules() });
});

app.post('/api/rules', (req, res) => {
  const { rules } = req.body;
  fs.writeFileSync(RULES_FILE, JSON.stringify({ rules: rules || [] }, null, 2));
  res.json({ success: true });
});

// ── Helpers ──────────────────────────────────────────────────────────────────
function loadKnowledge() {
  if (!fs.existsSync(KNOWLEDGE_DIR)) return [];
  return fs
    .readdirSync(KNOWLEDGE_DIR)
    .filter((f) => f.endsWith('.md'))
    .map((file) => ({
      name: file.replace('.md', ''),
      content: fs.readFileSync(path.join(KNOWLEDGE_DIR, file), 'utf8'),
    }));
}

function loadRules() {
  try {
    return JSON.parse(fs.readFileSync(RULES_FILE, 'utf8')).rules || [];
  } catch {
    return [];
  }
}

function trimInputForPrompt(inputData) {
  const raw = (inputData || '').trim();
  if (!raw || raw === '{}') return raw;

  try {
    const parsed = JSON.parse(raw);
    if (Array.isArray(parsed)) {
      return JSON.stringify(parsed.slice(0, 5), null, 2);
    }

    if (parsed && typeof parsed === 'object') {
      const trimmed = {};
      for (const [key, value] of Object.entries(parsed)) {
        trimmed[key] = Array.isArray(value) ? value.slice(0, 5) : value;
      }
      return JSON.stringify(trimmed, null, 2);
    }
  } catch {
    return raw;
  }

  return raw;
}

function buildSystemPrompt(knowledge, rules, currentCode, inputData, cubeType) {
  let prompt = `Ты эксперт по Groovy, специализирующийся на трансформации JSON-данных.
Твоя задача — писать и изменять Groovy-скрипты для преобразования JSON.

## Требования к скриптам

- Импортируй JsonSlurper и JsonOutput в начале
- Читай входные данные через System.in:
  \`def input = new JsonSlurper().parseText(System.in.text ?: '{}')\`
- Выводи результат через:
  \`println JsonOutput.prettyPrint(JsonOutput.toJson(result))\`
- Всегда предоставляй ПОЛНЫЙ, рабочий скрипт — не фрагменты

## Формат ответа

Когда пишешь или изменяешь код:
1. Кратко объясни что делаешь (1–3 предложения)
2. Дай полный код в блоке \`\`\`groovy

Если пользователь задаёт вопрос без запроса кода — отвечай обычным текстом без блока кода.

## Ключевые паттерны Groovy

\`\`\`groovy
// Трансформация массива
input.items.collect { item -> [newField: item.oldField] }

// Фильтрация
.findAll { it.active }

// Группировка
.groupBy { it.category }

// Безопасная навигация и дефолт
record?.field?.nested ?: 'default'

// Добавление поля в map
record + [newKey: value]

// Сортировка
.sort { a, b -> a.name <=> b.name }

// Уникальные значения
.unique { it.id }
\`\`\`
`;

  const cubeInstructions = {
    'json-filter': `\n\n## Тип кубика: Json Filter
Пользователь пишет код для кубика Json Filter.
Этот кубик принимает только Groovy-предикат с переменной _:
- _ = каждый объект массива
- Возвращает boolean (true → левый выход, false → правый)
- НЕТ import, def input, println — только выражение-предикат

Пример: \`_.country == "RU"\`

В ответе предоставь ДВА блока кода:
1. \`\`\`groovy — полный тестовый скрипт (с import/readline/println) для запуска в редакторе
2. \`\`\`groovy-cube — только предикат для вставки в кубик`,

    'json-map': `\n\n## Тип кубика: Json Map
Пользователь пишет код для кубика Json Map.
Этот кубик принимает только трансформацию объекта _:
- _ = входной объект
- В конце всегда возвращать _
- НЕТ import, println — только изменения _

В ответе предоставь ДВА блока кода:
1. \`\`\`groovy — полный тестовый скрипт для запуска в редакторе
2. \`\`\`groovy-cube — только трансформация _ для вставки в кубик`,

    'json-process': `\n\n## Тип кубика: Json Process — СТРОГИЕ ПРАВИЛА

Ты пишешь код ИСКЛЮЧИТЕЛЬНО для кубика Json Process. Это НЕ обычный Groovy-скрипт.

ЗАПРЕЩЕНО (никогда не используй):
- ❌ \`import groovy.json.JsonSlurper\`
- ❌ \`import groovy.json.JsonOutput\`
- ❌ \`System.in\`, \`System.in.text\`, \`readLine\`
- ❌ \`println\`, \`print\`
- ❌ \`def input = ...parseText(...)\`
- ❌ \`JsonOutput.toJson(...)\`, \`prettyPrint\`

ОБЯЗАТЕЛЬНО используй:
- ✅ \`in0\` — уже готовый массив входных объектов (НЕ нужно парсить)
- ✅ \`out.write(map)\` — записывает объект в выход (НЕ println)

Шаблон кода кубика:
\`\`\`groovy
in0.groupBy { it.someField }.each { key, items ->
    out.write([field: key, count: items.size()])
}
\`\`\`

Или:
\`\`\`groovy
in0.each { item ->
    out.write([id: item.id, value: item.x * 2])
}
\`\`\`

ФОРМАТ ОТВЕТА: ровно ОДИН блок кода с тегом \`\`\`groovy. Внутри — только код кубика (in0/out.write). Никаких import, System.in, println. Если сгенерируешь println или JsonSlurper — это ОШИБКА, код не запустится в кубике.`,

    'json-process-multi': `\n\n## Тип кубика: Json Process (multi-input) — СТРОГИЕ ПРАВИЛА

Ты пишешь код ИСКЛЮЧИТЕЛЬНО для кубика Json Process с несколькими входами.

ЗАПРЕЩЕНО:
- ❌ \`import\` любых JSON-библиотек
- ❌ \`System.in\`, \`println\`, \`readLine\`
- ❌ парсинг JSON через JsonSlurper

ОБЯЗАТЕЛЬНО:
- ✅ \`in0\`, \`in1\`, \`in2\`, ... — готовые массивы по числу входов
- ✅ \`out.write(map)\` — записывает объект в выход

Шаблон:
\`\`\`groovy
in0.each { task ->
    def extra = in1.find { it.id == task.id }
    out.write([id: task.id, name: extra?.name])
}
\`\`\`

ФОРМАТ ОТВЕТА: ровно ОДИН блок \`\`\`groovy с кодом кубика. Никаких import/System.in/println.`,
  };

  if (cubeType && cubeInstructions[cubeType]) {
    prompt += cubeInstructions[cubeType];
  }

  if (knowledge.length > 0) {
    prompt += '\n\n## База знаний Groovy\n';
    knowledge.forEach((k) => {
      prompt += `\n### ${k.name}\n${k.content}\n`;
    });
  }

  if (rules.length > 0) {
    prompt += '\n\n## Правила пользователя (выполняй строго)\n';
    rules.forEach((r, i) => { prompt += `${i + 1}. ${r}\n`; });
  }

  if (currentCode && currentCode.trim()) {
    prompt += `\n\n## Текущий код в редакторе\n\`\`\`groovy\n${currentCode}\n\`\`\``;
  }

  const promptInputData = trimInputForPrompt(inputData);
  if (promptInputData && promptInputData !== '{}' && promptInputData !== '') {
    prompt += `\n\n## Входные данные\n\`\`\`json\n${promptInputData}\n\`\`\``;
  }

  return prompt;
}

// ── Start ────────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`\nGroovy AI Agent запущен: http://localhost:${PORT}\n`);
  if (!eliza) {
    console.warn('  ⚠ ELIZA_PROXY_URL не задан в .env');
  } else {
    console.log(`  ✓ Режим прокси: ${ELIZA_PROXY_URL}`);
  }
  console.log('  - Groovy (brew install groovy) — для выполнения скриптов\n');
});
