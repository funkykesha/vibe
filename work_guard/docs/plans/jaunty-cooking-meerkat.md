# Block quit during overtime

## Context

Хотим ужесточить откладывание завершения рабочего дня. Первое требование: пока идёт
переработка (overtime), пользователь не может выйти из приложения — пункт «Выйти»
не активен («кнопка не горит»). Сейчас «Выйти» всегда активен в обоих меню, поэтому
переработку легко обойти, просто закрыв WorkGuard.

Признак активной переработки уже есть: `self._overtime_started_at is not None`
(`work_guard.py:605`, сбрасывается в `None` при ресете периода — `work_guard.py:816`).
Меню рисуется двумя путями, оба надо закрыть:
- Python `rumps` меню — `_build_menu` (`work_guard.py:561`), пункт «Выйти» `work_guard.py:575`.
- Swift menu agent — `rebuildMenu` (`WorkGuardMenu/main.swift:107`), «Выйти» захардкожен `main.swift:126`.

## Approach

Единый предикат «можно ли выйти»: выходить нельзя, когда `_overtime_started_at is not None`.
Транслируем его в оба меню и страхуемся guard-ом в самом `quit_app`.

### 1. Python core (`work_guard.py`)

- Добавить хелпер рядом с `_contextual_button_state`:
  ```python
  def _quit_enabled(self) -> bool:
      return self._overtime_started_at is None
  ```
- В `_build_menu` сохранить ссылку на пункт выхода (по образцу `self._defer_item`):
  `self._quit_item = rumps.MenuItem("Выйти", callback=self.quit_app)` и положить его в меню вместо инлайн-MenuItem (`work_guard.py:575`).
- Добавить `_refresh_quit_item` по образцу `_refresh_defer_item` (`work_guard.py:579`):
  через `self._quit_item._menuitem.setEnabled_(self._quit_enabled())` с тем же `try/except`.
- Вызвать `_refresh_quit_item()` там же, где уже зовётся `_refresh_defer_item()` — в `_tick` (`work_guard.py:753`) и в периодик-рефреше (`work_guard.py:669`).
- Guard в `quit_app` (`work_guard.py:682`): в начале, если `not self._quit_enabled()`, залогировать и `return` — защита от устаревшего `command.json` и Cmd+Q.

### 2. Swift IPC payload (`work_guard.py`)

- В `_status_json_payload` (`work_guard.py:307`) добавить ключ `"quit_enabled": self._quit_enabled()`.

### 3. Swift menu agent (`WorkGuardMenu/main.swift`)

- `StatusModel`: добавить поле `var quitEnabled: Bool = true` (`main.swift:23`).
- В `refresh` распарсить `json["quit_enabled"] as? Bool ?? true` и прокинуть в `StatusModel` (`main.swift:70-95`).
- В `rebuildMenu` (`main.swift:126`) сделать «Выйти» зависимым от флага по образцу остальных пунктов:
  `action: currentStatus.quitEnabled ? #selector(quitClicked(_:)) : nil`, `quit.isEnabled = currentStatus.quitEnabled`.
  При выключенном флаге `keyEquivalent` тоже не сработает (disabled item).

## Verification

1. Пересборка: `bash rebuild.sh` (перекомпилит Swift, переустановит `/Applications/WorkGuard.app`).
2. Поставить расписание так, чтобы быстро наступила переработка (или дождаться `_overtime_started_at` set).
3. Проверить в обоих меню: до переработки «Выйти» активен; после старта переработки — серый/неактивный, клик и Cmd+Q ничего не делают.
4. Проверить лог `~/.config/work_guard/work_guard.log`: при попытке выхода в переработке появляется запись guard-а.
5. Проверить `~/.config/work_guard/status.json`: поле `quit_enabled` переключается `true`→`false`.
6. После ресета периода (новый день / сброс) `_overtime_started_at` снова `None` — «Выйти» опять активен.
