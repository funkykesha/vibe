# Plan: Backlog — cube selector, export CSV/XLSX

## Context

Backlog содержит 4 пункта. Пункты 1–2 связаны с выбором типа «кубика» (интеграционного блока в pipeline). Пункты 3–4 — экспорт результата. Google Sheets (п.4) заменён на XLSX.

Кубики: **Json Filter** (предикат `_`), **Json Map** (трансформация `_`), **Json Process** (полный скрипт), **Json Process multi-input** (массив входов).

---

## Feature 1: Cube Type Selector + system prompt

### UI (`public/index.html`)

Добавить `<select id="cube-type">` в toolbar рядом с кнопкой "Groovy Code":

```html
<select id="cube-type" title="Тип кубика">
  <option value="">— кубик не выбран —</option>
  <option value="json-filter">Json Filter</option>
  <option value="json-map">Json Map</option>
  <option value="json-process">Json Process</option>
  <option value="json-process-multi">Json Process (multi-input)</option>
</select>
```

- Сохранять/восстанавливать из `localStorage['groovy-cube-type']`
- Добавить `cubeType: document.getElementById('cube-type').value` в тело fetch `/api/chat` внутри `sendMessage()`
- Если `cubeType` пустой при нажатии «Отправить» — показать `confirm('Тип кубика не выбран. Отправить без привязки к типу?')`. Если нет — прервать отправку.

### Backend (`server.js`)

Изменить сигнатуру: `buildSystemPrompt(knowledge, rules, currentCode, inputData, cubeType)`

Извлечь `cubeType` из `req.body` в `/api/chat` (строка 567):
```js
const { messages, currentCode, inputData, model, system: systemOverride, cubeType } = req.body;
```

Передать в `buildSystemPrompt(loadKnowledge(), loadRules(), currentCode, inputData, cubeType)`.

Добавить в `buildSystemPrompt()` секцию после базового промпта:

```js
const cubeInstructions = {
  'json-filter': `
## Тип кубика: Json Filter
Пользователь пишет код для кубика Json Filter.
Этот кубик принимает только Groovy-предикат с переменной _:
- _ = каждый объект массива
- Возвращает boolean (true → левый выход, false → правый)
- НЕТ import, def input, println — только выражение-предикат

Пример: \`_.country == "RU"\`

В ответе предоставь ДВА блока кода:
1. \`\`\`groovy — полный тестовый скрипт (с import/readline/println) для запуска в редакторе
2. \`\`\`groovy-cube — только предикат для вставки в кубик`,

  'json-map': `
## Тип кубика: Json Map
Пользователь пишет код для кубика Json Map.
Этот кубик принимает только трансформацию объекта _:
- _ = входной объект
- В конце всегда возвращать _
- НЕТ import, println — только изменения _

В ответе предоставь ДВА блока кода:
1. \`\`\`groovy — полный тестовый скрипт для запуска в редакторе
2. \`\`\`groovy-cube — только трансформация _ для вставки в кубик`,

  'json-process': `
## Тип кубика: Json Process
Пользователь пишет код для кубика Json Process.
Полный Groovy-скрипт — совместим с редактором напрямую.
Один блок кода \`\`\`groovy достаточен.`,

  'json-process-multi': `
## Тип кубика: Json Process (multi-input)
Пользователь пишет код для кубика Json Process с несколькими входами.
Входные данные приходят как JSON-массив: [input1, input2, ...].
Читать через: \`def inputs = new JsonSlurper().parseText(System.in.text ?: '[]')\`
Один блок кода \`\`\`groovy достаточен.`,
};

if (cubeType && cubeInstructions[cubeType]) {
  prompt += cubeInstructions[cubeType];
}
```

### Frontend: отображение groovy-cube блока

Добавить в Output область второй панель «Код для кубика» (скрытую по умолчанию).

В `sendMessage()` после получения полного стримового ответа — искать блок `\`\`\`groovy-cube` в `fullText` (аккумулируется уже сейчас в `accum`). Если найден — показать панель и подставить код.

```js
// после сборки ответа:
const cubeMatch = fullText.match(/```groovy-cube\n([\s\S]*?)```/);
const cubePanel = document.getElementById('cube-code-panel');
if (cubeMatch && cubeMatch[1]) {
  document.getElementById('cube-code-out').textContent = cubeMatch[1].trim();
  cubePanel.style.display = '';
} else {
  cubePanel.style.display = 'none';
}
```

HTML для cube panel (добавить после `.data-panels` блока):
```html
<div id="cube-code-panel" style="display:none">
  <div class="toolbar">
    <span class="toolbar-label">Код для кубика</span>
    <div class="toolbar-actions">
      <button onclick="copyCubeCode()">Copy</button>
    </div>
  </div>
  <pre id="cube-code-out" class="output-scroll"></pre>
</div>
```

---

## Feature 2: Export CSV / XLSX

### UI (`public/index.html`)

Добавить SheetJS в `<head>`:
```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js"></script>
```

Добавить кнопки в Output toolbar:
```html
<button id="btn-csv" onclick="exportCSV()" style="display:none">CSV ↓</button>
<button id="btn-xlsx" onclick="exportXLSX()" style="display:none">XLSX ↓</button>
```

В `executeCode()` после парсинга вывода — показывать/скрывать кнопки:
```js
let parsedData = null;
try {
  parsedData = JSON.parse(rawOut);
} catch {}
const showExport = parsedData !== null;
document.getElementById('btn-csv').style.display = showExport ? '' : 'none';
document.getElementById('btn-xlsx').style.display = showExport ? '' : 'none';
```

Функции экспорта:
```js
function getOutputData() {
  const text = document.getElementById('output').textContent;
  let data = JSON.parse(text);
  if (!Array.isArray(data)) data = [data];
  return data;
}

function exportCSV() {
  const data = getOutputData();
  if (!data.length) return;
  const keys = Object.keys(data[0]);
  const rows = [keys.join(','), ...data.map(r =>
    keys.map(k => JSON.stringify(r[k] ?? '')).join(',')
  )];
  const blob = new Blob([rows.join('\n')], { type: 'text/csv' });
  const a = Object.assign(document.createElement('a'), {
    href: URL.createObjectURL(blob),
    download: 'output.csv'
  });
  a.click();
}

function exportXLSX() {
  const data = getOutputData();
  const ws = XLSX.utils.json_to_sheet(data);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, 'Output');
  XLSX.writeFile(wb, 'output.xlsx');
}
```

---

## Files to modify

| Файл | Изменения |
|------|-----------|
| `public/index.html` | cube-type select, cube-code panel, export buttons, 4 JS функции, SheetJS CDN |
| `server.js` | `buildSystemPrompt()` + 5-параметр + cubeType из req.body |

---

## Verification

1. Запустить `npm run dev`
2. Выбрать "Json Filter", отправить "напиши фильтр по полю country == RU"
   - Ожидать: два блока кода в ответе; панель "Код для кубика" появляется
3. Отправить без выбора кубика — появляется confirm dialog
4. Запустить код (F5), получить JSON-массив → кнопки CSV/XLSX появляются
5. Скачать CSV — открыть в Numbers/Excel, проверить заголовки и данные
6. Скачать XLSX — то же самое
