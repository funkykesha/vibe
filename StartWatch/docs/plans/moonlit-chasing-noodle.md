# Plan: Open Config in Default Editor

## Context

Сейчас «Open Config…» (Cmd+,) открывает встроенный NSPanel-редактор (`ConfigEditorWindow`).
Нужно добавить возможность открыть тот же файл (`~/.config/startwatch/config.json`) в системном редакторе по умолчанию (VSCode, Sublime, TextEdit — что угодно, macOS сам решит по UTI).

Это нужно, чтобы пользователь мог редактировать конфиг в привычном инструменте без использования встроенного минималистичного редактора.

---

## Approach

Добавить новый пункт меню **"Open Config in Default Editor"** под существующим "Open Config…".

Реализация — один вызов `NSWorkspace.shared.open(ConfigManager.configURL)`. macOS откроет файл в приложении, назначенном по умолчанию для `.json`.

Встроенный редактор (`ConfigEditorWindow`) **не трогать** — оба пункта остаются.

---

## Files to Modify

### 1. `Sources/StartWatch/Daemon/MenuBarController.swift`

**a) Добавить callback-свойство** (после строки 16, рядом с `onOpenConfig`):
```swift
var onOpenConfigInEditor: (() -> Void)?
```

**b) Добавить menu item** (после строки 140, после "Open Config…"):
```swift
let openInEditor = NSMenuItem(
    title: "Open Config in Default Editor",
    action: #selector(openConfigInEditorClicked),
    keyEquivalent: ""
)
openInEditor.target = self
menu.addItem(openInEditor)
```

**c) Добавить action-метод** (после строки 157):
```swift
@objc private func openConfigInEditorClicked() { onOpenConfigInEditor?() }
```

### 2. `Sources/StartWatch/MenuAgent/MenuAgentDelegate.swift`

**Добавить wire-up** (после строки 35, после `menuBar.onOpenConfig`):
```swift
menuBar.onOpenConfigInEditor = {
    NSWorkspace.shared.open(ConfigManager.configURL)
}
```

---

## Verification

```bash
cd /Users/agaibadulin/Desktop/projects/vibe/StartWatch
swift build 2>&1 | tail -5   # must compile clean
```

Ручная проверка:
1. Запустить `StartWatchMenu.app`
2. Кликнуть иконку в menu bar
3. Убедиться: пункт "Open Config in Default Editor" есть под "Open Config…"
4. Кликнуть → `~/.config/startwatch/config.json` открывается в дефолтном редакторе
5. "Open Config…" (Cmd+,) по-прежнему открывает встроенную панель
