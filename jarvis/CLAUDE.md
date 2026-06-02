# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> Keep `CLAUDE.md` and `AGENTS.md` identical — only the H1 and the line above differ.

## Project

Jarvis — голосовой overlay-диспетчер для Mac, оркестрирующий Codex-агентов.
Текущая стадия — **итерация 1** (базовый прототип). Полный замысел и роадмап:
[`ARCHITECTURE.md`](ARCHITECTURE.md). Публичный контракт запуска:
[`README.md`](README.md).

## Stack

- Python 3.11+, PyObjC (AppKit / Foundation) — overlay.
- macOS only. Codex запускается в iTerm2 через AppleScript (`osascript`).
- Голосовой ввод — внешний (Handy). Никаких ключей в репозитории; секреты — из
  окружения.

## Build & Test

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python -m pytest tests/ -q     # чистое ядро, без AppKit
python jarvis.py               # запуск overlay (только на Mac)
```

## Layout

| Файл | Роль |
|------|------|
| `jarvis.py` | точка входа: NSApplication + проводка overlay → router → Codex |
| `overlay.py` | плавающая микро-кнопка + поле ввода (PyObjC NSPanel) |
| `router.py` | классификация реплики: ответить / делегировать / положить трубку |
| `codex_launcher.py` | запуск интерактивного Codex в новом табе iTerm (async) |
| `voice.py` | абстракция `VoiceProvider` (Handy / stub) |
| `config.py` | конфиг `~/.config/jarvis/config.json` |

## Conventions

- **Чистое ядро отдельно от AppKit.** `router.py`, `codex_launcher.py`,
  `config.py`, `voice.py` импортируются и тестируются без PyObjC. AppKit живёт
  только в `overlay.py` и в `jarvis.py::Jarvis.run` (ленивый импорт).
- **Простота прежде всего.** Минимум кода под задачу итерации. Не строй фичи
  следующих итераций заранее.
- **Швы для будущего:** `router.classify` — место для LLM/tool-use; iTerm-запуск
  меняется на Codex App Server в итерации 4. Не ломай эти границы.
- Чистая логика → unit-тест. UI проверяется руками на Mac.
