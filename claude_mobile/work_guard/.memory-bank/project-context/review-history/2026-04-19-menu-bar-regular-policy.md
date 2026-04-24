# 2026-04-19 — Строка меню: Regular policy и Info.plist у интерпретатора

## Проблема

При запуске через `WorkGuard.app` и `conda run` не отображался/не кликался статус-айтем; пропали уведомления. Логи ранее показывали успешный цикл rumps (`title: WG`), но в UI поведение регрессировало.

## Решение

1. **Политика активации по умолчанию**: `NSApplicationActivationPolicyRegular` вместо accessory-only. У части связок conda + `exec python3` policy Accessory давала нестабильное отображение строки меню. Режим только строки меню без Dock: переменная окружения `WORKGUARD_MENU_BAR_ONLY=1` → `NSApplicationActivationPolicyAccessory`.
2. `**Info.plist` рядом с `sys.executable`**: при отсутствии файла создаётся автоматически при старте (`_ensure_interpreter_info_plist`) — нужно для `rumps.notification` / NSUserNotificationCenter.
3. **Уведомления osascript**: общая функция `_notify_osascript` с экранированием кавычек и логированием stderr при ошибке.
4. `**WorkGuard.app` `Info.plist`**: убран `LSUIElement`, чтобы не скрывать приложение там, где bundle всё же учитывается системой.

## Файлы

- `work_guard.py`: `_ensure_interpreter_info_plist`, `_notify_osascript`, правка `run()`
- `WorkGuard.app/Contents/Info.plist`: без `LSUIElement`

## Дополнение — пустой слот в строке меню

Уведомление «WorkGuard запущен» приходило, но **«WG» не было видно**: слот создаётся, но без иконки/текста. Добавлен `@rumps.timer` `_pin_status_item`: квадратный слот `NSSquareStatusItemLength` (-2) + SF Symbol, широкий режим `WORKGUARD_STATUS_WIDE=1`; диагностика `frame`/`isVisible`; `requestUserAttention` для Dock.

**Гонка:** фоновый `_tick` сразу вызывал `_update_icon` → `self.title = …`, rumps перезаписывал NSStatusItem и сбрасывала иконку после pin. Присвоение `self.title` убрано из `_update_icon`, статус только в пункте меню «Статус».