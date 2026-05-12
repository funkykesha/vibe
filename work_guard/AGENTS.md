# Agent Instructions

Финальный ответ агентa всегда на русском.

## First Read

1. `AGENTS.md` — правила сессии, карта источников правды, doc scope.
2. `bd prime` — workflow beads.
3. `.memory-bank/active-context/current-status.md` — оперативный статус.
4. `.memory-bank/progress.md` — недавние изменения.
5. `README.md` — human-facing current workflow.
6. `CONTEXT.md` — glossary/domain context. Не agent instructions. Не runbook.
7. `docs/architecture/README.md` — индекс C4 с метками `Current` / `Planned` / `Archive`.

## Source Of Truth Map

- **Agent workflow / session rules:** `AGENTS.md`
- **Task tracking:** `bd` / beads. Не использовать markdown TODO вместо beads.
- **Current public run/install contract:** `README.md`
- **Domain glossary and terminology:** `CONTEXT.md`
- **Architecture views and intent boundaries:** `docs/architecture/`
- **Operational memory for agents:** `.memory-bank/`
- **Historical decisions and reviews:** `.memory-bank/project-context/review-history/`
- **OpenSpec intent:** `openspec/changes/*`, `openspec/specs/*`

## Current Product Contract

- Единственный публичный entrypoint: `bash rebuild.sh`.
- Единственный supported GUI target: `/Applications/WorkGuard.app`.
- Project-local `.app` не является supported launch target.
- Legacy setup script path obsolete. Не wrapper. Не fallback.
- LaunchAgent path: `~/Library/LaunchAgents/com.agaibadulin.workguard.plist`.
- LaunchAgent contract: `/usr/bin/open /Applications/WorkGuard.app`, `RunAtLoad=true`, `KeepAlive=false`.
- Stable bundle id: `com.agaibadulin.workguard`.
- Direct Python launch — только debug/diagnostics.
- ActivitySignals — future boundary only; local/coarse-only; collectors сейчас отсутствуют.
- Privacy: наружу ничего без явного запроса; secrets машину не покидают никогда.

## Documentation Roles

- `README.md` — для человека: как rebuild/install/run/stop/debug работает сейчас.
- `CONTEXT.md` — словарь терминов и границ домена.
- `docs/architecture/*.md` — C4 views; каждый файл должен быть явно помечен как `Current`, `Planned`, или `Archive`.
- `.memory-bank/*` — рабочая память агентов; полезна для continuity, но не заменяет canonical product docs.
- `CLAUDE.md` — короткий redirect на этот файл. Не место для дубля правил.

## OpenSpec And Beads

Включать OpenSpec workflow только когда есть `openspec/` и `.beads/` или пользователь явно просит OpenSpec.

Порядок:

1. OpenSpec фиксирует intent.
2. Beads фиксирует task graph и execution state.
3. Код и docs приводятся в соответствие intent.

Правила:

- Не начинать implementation до ясного intent.
- Держать OpenSpec, Beads, code/docs синхронными.
- Если есть `openspec/AGENTS.md`, он главный для схемы и команд внутри `openspec/`.
- Не переписывать чужие изменения без явного запроса.

## Beads

Run `bd prime` at session start.

Quick reference:

```bash
bd ready
bd show <id>
bd update <id> --claim
bd close <id>
bd dolt push
```

## Non-Interactive Shell

Всегда использовать non-interactive flags для файловых команд:

```bash
cp -f source dest
mv -f source dest
rm -f file
rm -rf directory
cp -rf source dest
```

Также:

- `scp -o BatchMode=yes`
- `ssh -o BatchMode=yes`
- `apt-get -y`
- `HOMEBREW_NO_AUTO_UPDATE=1 brew ...`
