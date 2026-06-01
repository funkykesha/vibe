## Purpose

Define the overtime overlay deferral ladder: a single contextual menu control that lets the user postpone the next overlay through a fixed, forced-order `[20, 10, 5]` minute sequence, with step unlock delays, a pre-overlay cutoff, and state that survives restarts within the same deferral period.

## Requirements

### Requirement: Contextual deferral control

The system SHALL render a single menu item whose title and enabled flag are driven by overtime, ladder, and cutoff state. The control SHALL be the only menu surface for deferring overlays — the overlay window itself MUST NOT expose a defer action.

#### Scenario: Outside overtime

- **WHEN** the user is not in overtime
- **THEN** the contextual control shows the title `Работаем!` and is disabled

#### Scenario: Overtime with fresh ladder

- **WHEN** the user is in overtime, no ladder step has been consumed, and `now` is more than 2 minutes before the scheduled next overlay
- **THEN** the contextual control shows the title `Отложить на 20 мин` and is enabled

#### Scenario: Ladder advanced after first step

- **WHEN** the user has consumed `+20` and `now` is more than 2 minutes before the scheduled next overlay
- **THEN** the contextual control shows the title `Отложить на 10 мин` and is enabled

#### Scenario: Ladder advanced after second step

- **WHEN** the user has consumed `+20` and `+10` and `now` is more than 2 minutes before the scheduled next overlay
- **THEN** the contextual control shows the title `Отложить на 5 мин` and is enabled

#### Scenario: Ladder exhausted

- **WHEN** the user is in overtime and has consumed all three steps `+20`, `+10`, `+5`
- **THEN** the contextual control shows the title `пора отдыхать` and is disabled

#### Scenario: Within 2-minute cutoff

- **WHEN** the user is in overtime, ladder is not exhausted, and `now` is within 2 minutes of the scheduled next overlay
- **THEN** the contextual control shows the title `пора отдыхать` and is disabled

### Requirement: Forced-order deferral ladder

The system SHALL offer overlay deferral in a fixed `[20, 10, 5]` minute sequence consumed in order. The user MUST NOT be able to skip a step or repeat a step. The ladder MUST advance only on an explicit user click; showing an overlay MUST NOT advance the ladder.

#### Scenario: User clicks `Отложить на 20 мин`

- **WHEN** the user clicks the contextual control while it shows `Отложить на 20 мин`
- **THEN** `deferral.steps_consumed` becomes `["+20"]` and the next control title becomes `Отложить на 10 мин`

#### Scenario: Overlay fires without user defer click

- **WHEN** the scheduled next overlay fires and the user has not clicked any defer step
- **THEN** `deferral.steps_consumed` remains unchanged and the next control title remains `Отложить на 20 мин` (or the current ladder position)

### Requirement: Deferral adds to scheduled overlay time

The system SHALL add the chosen step duration to the currently scheduled next overlay time, not to the moment of the click.

#### Scenario: Defer 12 minutes before overlay

- **WHEN** the scheduled next overlay is 12 minutes away and the user clicks `Отложить на 30 мин` (or any active step `X`)
- **THEN** the scheduled next overlay becomes `12 + X` minutes away from `now`

#### Scenario: Defer right after previous defer — time arithmetic

- **WHEN** the user clicks `Отложить на 20 мин` and later (after unlock delay) clicks `Отложить на 10 мин`
- **THEN** the scheduled next overlay time gains exactly 10 minutes relative to its value after the first defer

### Requirement: Step unlock delay

After a deferral click, the system SHALL prevent the next ladder step from being available for `step * 3 // 4` minutes (integer division). The delay is measured from the moment of the click, not from the scheduled overlay time.

Unlock delays by step: `+20` → 15 min, `+10` → 7 min. After `+5` the ladder is exhausted so no unlock delay applies.

During the unlock period the contextual control SHALL show the next step title (`Отложить на N мин`) but remain **disabled** — preventing rapid ladder sprint without hiding what is coming.

#### Scenario: Immediate re-click after +20 is blocked

- **WHEN** the user clicks `Отложить на 20 мин` and immediately clicks the control again
- **THEN** the second click is ignored; `steps_consumed` remains `["+20"]`; the contextual control shows `Отложить на 10 мин` but is **disabled**

#### Scenario: Step unlocks after delay elapses

- **WHEN** 15 minutes have elapsed since the user clicked `Отложить на 20 мин`
- **THEN** the contextual control for `Отложить на 10 мин` becomes **enabled** (provided more than 2 minutes remain before the scheduled overlay)

### Requirement: Pre-overlay cutoff

The system SHALL prevent the user from deferring within 2 minutes of the currently scheduled next overlay. The cutoff window SHALL move together with prior defers.

#### Scenario: Cutoff measured against deferred time

- **WHEN** the user defers `+20` so the next overlay is 18 minutes away, and 16 minutes later the next overlay is 2 minutes away
- **THEN** the contextual control becomes disabled with title `пора отдыхать`

#### Scenario: Cutoff lifts after overlay fires

- **WHEN** an overlay fires and a new next-overlay time is scheduled
- **THEN** the contextual control re-enables according to current ladder position and the new pre-overlay distance

### Requirement: Ladder state persists across restarts within the same deferral period

The system SHALL persist `deferral` state (`period_id`, `steps_consumed`, `next_overlay_at`) to `~/.config/work_guard/config.json` and restore it on launch. While `period_id` matches the current period as defined in the period-settings-freeze capability, the ladder MUST NOT be reset.

#### Scenario: App restart during overtime keeps ladder

- **WHEN** the app restarts during an active deferral period after `+20` has been consumed
- **THEN** on launch the contextual control shows `Отложить на 10 мин` and the previously scheduled next overlay time is honoured
