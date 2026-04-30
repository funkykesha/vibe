# Plan: Menu bar emoji icons

## Context

Текущие иконки в menu bar — текстовые `"SW"` / `"SW!"`. Нужно заменить на emoji:
- ♻️ — все сервисы работают
- ⚠️ — есть упавшие сервисы

## Файл для изменения

`Sources/StartWatch/Daemon/MenuBarController.swift`, метод `updateIcon` (строка ~41)

## Изменение

```swift
// Было:
button.title = allOk ? "SW" : "SW!"

// Станет:
button.title = allOk ? "♻️" : "⚠️"
```

Удалить устаревший комментарий `// Text icon is more robust...` — он про SF Symbols, не про emoji.

## Verification

1. Пользователь запускает `! ./install.sh`
2. Иконка в menu bar показывает ♻️ (все ок) или ⚠️ (есть проблемы)
3. `swift test` — 19/19 pass
