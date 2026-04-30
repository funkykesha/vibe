# Plan: Open Config in Default Editor

## Context

`Open Config…` (⌘,) сейчас открывает встроенный NSPanel (`ConfigEditorWindow`) с примитивным NSTextView — нет подсветки синтаксиса, нет удобного undo. Пользователь хочет открывать конфиг-файл во внешнем редакторе по умолчанию (TextEdit, VSCode, etc.) через `NSWorkspace`. Встроенный редактор убирается.

## Изменения

### 1. `MenuAgentDelegate.swift`

Убрать свойство `configEditor` и изменить `onOpenConfig`:

```swift
// Удалить:
private var configEditor = ConfigEditorWindow()

// Изменить с:
menuBar.onOpenConfig = { [weak self] in
    self?.configEditor.show()
}

// На:
menuBar.onOpenConfig = {
    NSWorkspace.shared.open(ConfigManager.configURL)
}
```

### 2. `ConfigEditorWindow.swift`

Удалить файл — больше не используется.

## Затронутые файлы

- `Sources/StartWatch/MenuAgent/MenuAgentDelegate.swift` — 2 изменения (удалить свойство, изменить closure)
- `Sources/StartWatch/MenuAgent/ConfigEditorWindow.swift` — удалить

## Что НЕ меняется

- `MenuBarController.swift` — `onOpenConfig` callback и пункт меню "Open Config…" (⌘,) остаются
- `ConfigManager.configURL` — переиспользуется как есть

## Верификация

1. `swift build` — без ошибок
2. Запустить MenuAgent: кликнуть "Open Config…" → открывается `~/.config/startwatch/config.json` в приложении по умолчанию для JSON
3. `swift test` — 19/19 зелёные
