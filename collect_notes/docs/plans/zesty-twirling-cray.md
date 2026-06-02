# Фикс: загрузка клиппингов из Obsidian

## Контекст

**Проблема:** Клиппинги в `Clippings/` не попадают в pipeline.

**Причина:** Коллектор (`collectors/obsidian.js`) ищет тег `#research/inbox` только как инлайн `#tag` через regex. Клиппинги Obsidian Web Clipper создают теги в YAML frontmatter:
```yaml
tags:
  - "clippings"
```
— такой формат regex НЕ находит. В vault нет ни одного файла с тегом `research/inbox`.

**Состояние системы:**
- `.env` → `VAULT_ROOT` настроен правильно
- `config.js:6` → `inboxScanDir: "Clippings"` — папка правильная, существует
- Клиппингов в папке много (20+ файлов), но ни один не проходит фильтр

## Решение

Если задан `inboxScanDir` — папка уже является маркером "inbox". Тег не нужен.

Изменить `collectors/obsidian.js:54`: если `inboxScanDir` задан, пропускать проверку тега.

### Изменение в `collectors/obsidian.js`

**Было:**
```javascript
const tags = extractTags(content);
if (!tags.includes(config.vault.sourceTag)) continue;
```

**Станет:**
```javascript
const tags = extractTags(content);
// When scanning a dedicated dir (inboxScanDir), tag filter is implicit by folder location
if (!config.vault.inboxScanDir && !tags.includes(config.vault.sourceTag)) continue;
```

Один if, одна строка изменена. Логика: `inboxScanDir` задан → все `.md` в этой папке попадают в pipeline. Не задан → нужен тег `#research/inbox`.

## Критические файлы

- [`research-pipeline/collectors/obsidian.js`](../research-pipeline/collectors/obsidian.js) — строки 49-54, логика фильтрации
- [`research-pipeline/config.js`](../research-pipeline/config.js) — `vault.inboxScanDir` (строка 6)

## Проверка

```bash
cd /Users/agaibadulin/Desktop/projects/vibe/files/research-pipeline
node index.js collect
# должен вывести список клиппингов из Clippings/
```

Ожидаемый результат: `[obsidian] collected N` где N > 0.
