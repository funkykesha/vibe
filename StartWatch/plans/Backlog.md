Backlog

1. Когда запускаются серверы - тем что нужно время, повисают - выхода никакого нет
startwatch restart all
Checking services...
🔄 Restarting Eliza Proxy
$ cd /Users/agaibadulin/Desktop/projects/vibe/eliza-proxy && node server.js
eliza-proxy: http://localhost:3100
ELIZA_TOKEN: OK
^C

2. Какая то чертовщина с отображением запущенных конфигов. В конфиге 4 - показывает 2. Потом спустя время - уже 4. Потом опять может стать 2 (не понятно что влияет и как)

3. То выводится то скрывается в меню бар значок, переустановка не помогает

4. До сих пор однозначно не понятно как управлять через CLI

5. При старте логов - зачем то спрашивается разрешение на уведомления

6. После команды рестарт all - старые процессы не убиваются? Должны. Потому что как будто бы не все убиваются

7. ИИ Агент пытается запустить и виснет ./.build/debug/startwatch daemon &

8. запускаешь startwatch restart ai_roovy, он показывает запущенные процессы, из которых нельзя выйти. Что делать? Это проблема ai_roovy и eliza-proxy?
Почему такой проблемы нет для cd /Users/agaibadulin/Desktop/projects/vibe/genidea && node log-server.js?
Нужен большой ресеч причин, в том числе рисеч самих сервисов


```
startwatch restart ai_roovy
Starting ai_roovy...
$ cd /Users/agaibadulin/Desktop/projects/vibe/groovy_agent && node server.js

◇ injected env (2) from .env // tip: ⌘ suppress logs { quiet: true }

Groovy AI Agent запущен: http://localhost:3000

  ✓ Режим прокси: http://localhost:3100
  - Groovy (brew install groovy) — для выполнения скриптов
```

```
startwatch restart eliza_proxy
Starting eliza_proxy...
$ cd /Users/agaibadulin/Desktop/projects/vibe/eliza-proxy && node server.js

eliza-proxy: http://localhost:3100
ELIZA_TOKEN: OK

anthropic [░░░░░░░░░░░░░░░░░░░░] 0/3
  ⏳ claude-haiku-4-5, ⏳ claude-opus-4-7, ⏳ claude-sonnet-4-5

deepseek [░░░░░░░░░░░░░░░░░░░░] 0/6
  ⏳ deepseek-ai/deepseek-r1, ⏳ deepseek-chat, ⏳ deepseek-reasoner, ⏳ deepseek-v3-1-terminus
  ⏳ deepseek-v3-2, ⏳ openrouter/deepseek/deepseek-v3.1-terminus

google [░░░░░░░░░░░░░░░░░░░░] 0/3
  ⏳ gemini-2.0-flash, ⏳ gemini-2.5-flash, ⏳ gemini-2.5-pro

zhipu [░░░░░░░░░░░░░░░░░░░░] 0/2
  ⏳ glm-4-7, ⏳ z-ai/glm-4.5

openai [░░░░░░░░░░░░░░░░░░░░] 0/26
  ⏳ gpt-4.1, ⏳ gpt-4.1-mini, ⏳ gpt-4.1-nano, ⏳ gpt-4o, ⏳ gpt-4o-mini, ⏳ gpt-5, ⏳ gpt-5-mini
  ⏳ gpt-5-nano, ⏳ gpt-5-pro, ⏳ gpt-5.1, ⏳ gpt-5.2, ⏳ gpt-5.2-codex, ⏳ gpt-5.2-pro
  ⏳ gpt-5.3-codex, ⏳ gpt-5.4, ⏳ gpt-5.4-mini, ⏳ gpt-5.4-nano, ⏳ gpt-5.4-pro, ⏳ gpt-5.5, ⏳ o1
  ⏳ o1-pro, ⏳ o3, ⏳ o3-mini, ⏳ o3-pro, ⏳ o4-mini, ⏳ openai/o1-mini

xai [░░░░░░░░░░░░░░░░░░░░] 0/3
  ⏳ grok-3, ⏳ grok-3-mini, ⏳ grok-4

moonshotai [░░░░░░░░░░░░░░░░░░░░] 0/2
  ⏳ kimi-k2-5, ⏳ moonshotai/kimi-k2.5

mistral [░░░░░░░░░░░░░░░░░░░░] 0/3
  ⏳ mistral-large-latest, ⏳ mistral-medium-latest, ⏳ mistral-small-latest

alibaba [░░░░░░░░░░░░░░░░░░░░] 0/10
  ⏳ qwen-max, ⏳ qwen-mt-plus, ⏳ qwen-mt-turbo, ⏳ qwen/qwq-32b, ⏳ qwen3-5-397b-a17b-fp8
  ⏳ qwen3-Coder-480b, ⏳ qwen3.5-397b-a17b, ⏳ qwen3.5-plus, ⏳ qwen3.6-plus
  ⏳ together/qwen/qwen3-235b-a22b-fp8-tput

anthropic [████████████████████] 3/3
  ❌ claude-haiku-4-5, ❌ claude-opus-4-7, ❌ claude-sonnet-4-5

google [████████████████████] 3/3
  ❌ gemini-2.0-flash, ❌ gemini-2.5-flash, ❌ gemini-2.5-pro

xai [████████████████████] 3/3
  ❌ grok-3, ❌ grok-3-mini, ❌ grok-4

mistral [████████████████████] 3/3
  ❌ mistral-large-latest, ❌ mistral-medium-latest
  ❌ mistral-small-latest

moonshotai [████████████████████] 2/2
  ❌ kimi-k2-5, ❌ moonshotai/kimi-k2.5

openai [████████████████████] 26/26
  ❌ gpt-4.1, ❌ gpt-4.1-mini, ❌ gpt-4.1-nano, ❌ gpt-4o
  ❌ gpt-4o-mini, ❌ gpt-5, ❌ gpt-5-mini, ❌ gpt-5-nano
  ❌ gpt-5-pro, ❌ gpt-5.1, ❌ gpt-5.2, ❌ gpt-5.2-codex
  ❌ gpt-5.2-pro, ❌ gpt-5.3-codex, ❌ gpt-5.4
  ❌ gpt-5.4-mini, ❌ gpt-5.4-nano, ❌ gpt-5.4-pro
  ❌ gpt-5.5, ❌ o1, ❌ o1-pro, ❌ o3, ❌ o3-mini
  ❌ o3-pro, ❌ o4-mini, ❌ openai/o1-mini

deepseek [████████████████████] 6/6
  ❌ deepseek-ai/deepseek-r1, ❌ deepseek-chat, ❌ deepseek-reasoner
  ✅ deepseek-v3-1-terminus, ❌ deepseek-v3-2
  ✅ openrouter/deepseek/deepseek-v3.1-terminus

alibaba [████████████████████] 10/10
  ✅ qwen-max, ❌ qwen-mt-plus, ❌ qwen-mt-turbo
  ❌ qwen/qwq-32b, ❌ qwen3-5-397b-a17b-fp8, ❌ qwen3-Coder-480b
  ❌ qwen3.5-397b-a17b, ❌ qwen3.5-plus, ❌ qwen3.6-plus
  ❌ together/qwen/qwen3-235b-a22b-fp8-tput

zhipu [████████████████████] 2/2
  ✅ glm-4-7, ✅ z-ai/glm-4.5

```