# Plan: Migrate genidea → eliza-proxy

## Context
`eliza-proxy` (port 3100) выделен из `groovy_agent` в отдельный сервис.  
`genidea/index.html` обращается на `localhost:3000` — нужно переключить на `3100` с новыми путями `/v1/*`.

## File
`genidea/index.html` — единственный файл изменений.

## Changes

| # | Line | Old | New |
|---|------|-----|-----|
| 1 | 106 | `'http://localhost:3000'` | `'http://localhost:3100'` |
| 2 | 165 | `/api/chat` | `/v1/chat` |
| 3 | 172–173 | `currentCode: '',` + `inputData: '{}',` | удалить обе строки |
| 4 | 966 | `/api/models` | `/v1/models` (или само — base URL уже изменён) |
| 5 | 969 | `!data.pending` | `data.validated` |

Опционально (строка ~196): добавить `if (msg.usage) { /* console.log cost */ }` перед `if (msg.text)`.

## Verification
```bash
# eliza-proxy запущен
curl http://localhost:3100/v1/health
curl http://localhost:3100/v1/models | head -5
curl -N -X POST http://localhost:3100/v1/chat \
  -H 'Content-Type: application/json' \
  -d '{"model":"claude-haiku-4-5","messages":[{"role":"user","content":"1+1=?"}]}'

# Открыть genidea в браузере → DevTools → Network → запрос идёт на localhost:3100/v1/chat
```
