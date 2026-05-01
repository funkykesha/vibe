## Context

The current dashboard is a single-file React app in `index.html` with three tabs: salary distribution, capital, and settings. It uses a dark mono visual language and compact table-like controls. Existing product specs frame the future app as a ritual-first personal finance assistant, not a generic finance tracker.

This design fixes the product UI direction before implementation. The primary user opens the dashboard to complete a recurring salary-day routine, while still needing a quick read on current capital.

## Goals / Non-Goals

**Goals:**

- Make salary day the primary MVP ritual.
- Keep the first screen ritual-first while showing a compact capital summary.
- Define Swiss Finance as the primary theme and Dark Finance as a secondary theme.
- Keep desktop efficient and mobile linear.
- Preserve the existing salary and capital concepts while changing information hierarchy.
- Provide approximate wireframes that can guide implementation.

**Non-Goals:**

- Implement the redesign in this change.
- Produce high-fidelity pixel-perfect visual comps.
- Add charts to the first ritual screen.
- Redesign Telegram interactions.
- Change financial formulas, category defaults, or persistence.

## Decisions

### D1: Use a ritual workspace as the first screen

The dashboard opens on `Ритуалы`, with `Зарплатный день` as the active MVP ritual. The screen answers two questions first: what needs to be done now, and whether the current capital context looks sane.

Alternative considered: open directly on the current salary table. That keeps the MVP close to the existing UI but makes the product feel like a spreadsheet rather than an assistant.

### D2: Use one workspace with visible steps, not a wizard

Salary day uses visible steps in one workspace:

`ЗП -> Вычеты -> Распределение -> Капитал -> Снапшот`

The user can inspect and adjust the relevant sections without moving through `Next` and `Back` screens.

Alternative considered: step-by-step wizard. That would reduce local complexity but adds friction for a repeated expert workflow.

### D3: Show capital as a compact strip

The first screen includes a compact capital strip with key values:

`Капитал факт`, `С долгами`, `Быстрые`, `Семейные`, `Сын`, `Ипотека`

Charts and deeper account details belong in `Капитал` and `История`, not in the primary salary-day workspace.

Alternative considered: large KPI cards. They would visually compete with the ritual and make the first screen feel like a generic analytics dashboard.

### D4: Use Swiss Finance primary theme and Dark Finance secondary theme

Primary theme:

- Background: light neutral or slightly warm paper tone.
- Text: near-black graphite.
- Structure: strict grid, hairline borders, clear typographic hierarchy.
- Accent: one restrained finance accent for primary actions and selected state.

Secondary theme:

- Background: deep neutral dark, not terminal black.
- Text: high-contrast off-white.
- Structure: same layout and spacing as primary.
- Accent: same semantic role, adapted for dark contrast.

Both themes must share the same layout and interaction model. Theme changes should be token changes, not separate UI branches.

Alternative considered: keep the current dark mono theme. That is familiar but over-indexes on terminal aesthetics and weakens the calmer product direction.

### D5: Use compact top navigation

Top navigation is:

`Финансы    Ритуалы    Капитал    История    Настройки    [System/Light/Dark]`

`Ритуалы` is the default section. Future rituals can be added inside this section without changing the global navigation.

Alternative considered: keep three current tabs. That is simple but does not leave enough room for history and future rituals.

### D6: Use sections with hairline borders instead of heavy cards

The UI uses sections, dividers, and tables with restrained spacing. Cards are allowed only for repeated items or isolated status modules. Avoid nested cards, heavy shadows, decorative gradients, and oversized marketing composition.

Alternative considered: card-heavy dashboard. That would be familiar but less minimal and less efficient for repeated finance work.

## Approximate Wireframes

### Desktop ritual screen

```text
┌────────────────────────────────────────────────────────────────────────────┐
│ Финансы             Ритуалы   Капитал   История   Настройки      [System] │
├────────────────────────────────────────────────────────────────────────────┤
│ Зарплатный день · 5 мая                                                    │
│ Нужно: ввести ЗП -> проверить -> разложить -> зафиксировать                │
├────────────────────────────────────────────────────────────────────────────┤
│ Капитал факт 12.4M │ С долгами 12.2M │ Быстрые 1.8M │ Семейные 2.1M │ ... │
├──────────────────────────────────────┬─────────────────────────────────────┤
│ 1. Входные данные                    │ Статус ритуала                     │
│ Месяц: Май        День: 5            │ ● ЗП введена                       │
│ Gross: [                    ]        │ ● Вычеты проверены                 │
│                                      │ ● Распределение: 100%              │
│ Вычеты                               │ ○ Капитал обновлен                 │
│ Бейдж                 [       ]      │ ○ Снапшот создан                   │
│ НДФЛ                  [       ]      │                                     │
│ ДМС                   [       ]      │ Главные числа                      │
│                                      │ Чистыми:       000 000 ₽           │
│ Чистыми: 000 000 ₽                   │ Вычеты:        000 000 ₽           │
├──────────────────────────────────────┤ Осталось:             0 ₽           │
│ 2. Распределение                     │                                     │
│ НЗ                       15%  00 ₽   │ 3. Финиш                           │
│ Ипотека                32.4%  00 ₽   │ [Скопировать раскладку]            │
│ Семья                    4%  00 ₽    │ [Перейти к капиталу]               │
│ ...                                  │ [Создать снапшот]                  │
└──────────────────────────────────────┴─────────────────────────────────────┘
```

### Mobile ritual screen

```text
┌────────────────────────────┐
│ Финансы              [☰]   │
├────────────────────────────┤
│ Зарплатный день             │
│ 5 мая · [System]            │
├────────────────────────────┤
│ Капитал факт 12.4M          │
│ С долгами 12.2M             │
│ Быстрые 1.8M · Семейные ... │
├────────────────────────────┤
│ Статус                      │
│ ● ЗП -> ● вычеты -> ○ ...   │
├────────────────────────────┤
│ 1. Входные данные           │
│ Gross [              ]      │
│ Вычеты ...                  │
│ Чистыми 000 000 ₽           │
├────────────────────────────┤
│ 2. Распределение            │
│ НЗ             15%   00 ₽   │
│ Ипотека      32.4%   00 ₽   │
│ ...                         │
├────────────────────────────┤
│ 3. Финиш                    │
│ [Скопировать]               │
│ [К капиталу]                │
│ [Снапшот]                   │
└────────────────────────────┘
```

### Capital section direction

```text
┌────────────────────────────────────────────────────────────────────┐
│ Капитал                                      Последнее обновление  │
├────────────────────────────────────────────────────────────────────┤
│ Капитал факт │ С долгами │ Быстрые │ Семейные │ Сын │ С ипотекой │
├──────────────────────────────┬─────────────────────────────────────┤
│ Счета по банкам              │ Итоги и действия                    │
│ Тинькоф                      │ [Скопировать]                       │
│ ДОМ РФ                       │ [Создать снапшот]                   │
│ Финуслуги                    │ Источник данных / свежесть          │
└──────────────────────────────┴─────────────────────────────────────┘
```

### History section direction

```text
┌────────────────────────────────────────────────────────────────────┐
│ История и прогресс                         Период: 6м / 12м / Все │
├────────────────────────────────────────────────────────────────────┤
│ Линия капитала / ипотечной позиции                                 │
├────────────────────────────────────┬───────────────────────────────┤
│ Снапшоты                           │ Дельты                        │
│ 05.05  после зарплаты              │ + капитал                     │
│ 20.05  аванс                       │ - ипотека                     │
└────────────────────────────────────┴───────────────────────────────┘
```

## Risks / Trade-offs

- Current implementation is mobile-narrow (`max-w-lg`) → redesign must introduce responsive desktop layout without breaking current single-file simplicity.
- Two themes can duplicate CSS if implemented ad hoc → define tokens first and keep component structure shared.
- Capital strip can become too crowded → keep only headline metrics on the ritual screen and move detail to `Капитал`.
- Future rituals can overload the first screen → represent rituals as a list/status model, with salary day active by default.
- Charts can become decorative before snapshots are reliable → keep charts out of the first screen until history data exists.

## Migration Plan

1. Introduce theme tokens for Swiss Finance and Dark Finance.
2. Replace current tab header with compact top navigation.
3. Convert `Раскидать ЗП` into the ritual workspace while preserving existing calculations.
4. Add compact capital strip using current derived capital totals.
5. Move detailed account editing behind `Капитал`.
6. Add `История` shell only when snapshot data exists.

Rollback is visual: keep existing calculation state and restore the current tab structure if the new hierarchy proves slower in daily use.
