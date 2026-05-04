# Warp Terminal Integration

> **Статус: ЗАКРЫТО.** Авто-выполнение команд в Warp нереализуемо. Не чинить.

## Проблема

`warp://action/new_tab?command=...` — официальный URL scheme Warp — **НЕ выполняет команду автоматически**.
Команда вставляется в input buffer, но требует ручного подтверждения (Enter). `\n` в конце не помогает.
Это намеренное решение безопасности Warp (источник: specs/GH703/product.md).

## Решение

AppleScript через System Events: активировать Warp, затем `keystroke` + `key code 36` (Enter).

```swift
let script = """
tell application "Warp" to activate
delay 0.8
tell application "System Events"
    tell process "Warp"
        keystroke "\(escaped)"
        key code 36
    end tell
end tell
"""
```

## Критическая ловушка: молчаливый провал osascript

Без Accessibility permission поведение такое:
- `tell application "Warp" to activate` — **успешно** (Warp получает фокус)
- `keystroke` — **молча падает**, но exit code = **0**

Нельзя обнаружить ошибку по exit code. Нужна проверка ДО запуска AppleScript:

```swift
guard AXIsProcessTrusted() else {
    // показать NSAlert + открыть Warp без команды
    return
}
```

## Требование для пользователя

System Settings → Privacy & Security → Accessibility → добавить `StartWatchMenu.app`

После выдачи permission — перезапуск меню-агента не нужен, `AXIsProcessTrusted()` вернёт true сразу.

## Fallback

Если нет Accessibility permission:
1. Показать `NSAlert` с инструкцией
2. Открыть Warp через `warp://action/new_tab` (без команды)
