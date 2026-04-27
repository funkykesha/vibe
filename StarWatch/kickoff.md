

# StartWatch — Project Kickoff Document

---

## 1. Обзор проекта

**StartWatch** — нативный macOS-клиент (menu bar + CLI), который следит за тем, чтобы нужные сервисы работали после старта компьютера. Проверяет состояние по расписанию, уведомляет о проблемах, даёт удобный CLI для управления.

**Стек:** Swift, AppKit, UNUserNotificationCenter, Swift Concurrency, SPM

**Целевая платформа:** macOS 13+

**Артефакт:** один бинарник `startwatch`, два режима работы (daemon / CLI)

---

## 2. Роли в команде

### 2.1 Обязательный состав (v1.0)

```
┌─────────────────────────────────────────────────────────────────┐
│  Роль              Кол-во   Когда нужен    Занятость            │
├─────────────────────────────────────────────────────────────────┤
│  Lead / Architect   1       с самого начала  100% первые 2 нед  │
│  Swift Developer    1-2     с самого начала  100%               │
│  QA / Tester        1       с недели 3       50-70%             │
└─────────────────────────────────────────────────────────────────┘
```

#### Lead / Architect

```
Зона ответственности:
  • Финальная архитектура, ревью всех PR
  • Структура проекта, протоколы между модулями
  • Принятие решений по IPC (файл vs socket vs XPC)
  • CI/CD pipeline
  • Код: main.swift, CLIRouter, AppDelegate, IPC-слой

Требования:
  • Опыт с macOS-разработкой (AppKit, LaunchAgent, sandbox)
  • Понимание CLI-инструментов (argument parsing, ANSI, exit codes)
  • Опыт с Swift Concurrency (async/await, TaskGroup)
```

#### Swift Developer(s)

```
Зона ответственности:
  • Реализация модулей по спецификации
  • Unit-тесты на свои модули
  • Документация публичных API

Разделение, если два разработчика:

  Developer A — "Core & CLI":
    • Core/ServiceChecker.swift       (4 типа проверок)
    • Core/ServiceRunner.swift        (запуск/рестарт)
    • Core/Config.swift               (парсинг, валидация)
    • Core/StateManager.swift         (персистенция)
    • Core/HistoryLogger.swift        (логирование)
    • CLI/Commands/*                  (все команды)
    • CLI/Formatting/*                (ANSI, таблицы, отчёты)

  Developer B — "Daemon & Integration":
    • Daemon/MenuBarController.swift  (menu bar UI)
    • Daemon/AppDelegate.swift        (связующий слой)
    • Daemon/CheckScheduler.swift     (таймер)
    • Notifications/NotificationManager.swift
    • Terminal/TerminalLauncher.swift  (роутер терминалов)
    • Terminal/Terminals/*            (Warp, iTerm, Terminal.app, etc.)
    • IPC/IPCServer.swift + IPCClient.swift

Требования:
  • Swift 5.9+, SPM
  • Базовое понимание AppKit (NSStatusItem, NSMenu)
  • Работа с Process/Pipe для shell-команд
  • Желательно: опыт с Network.framework (NWConnection)
```

#### QA / Tester

```
Зона ответственности:
  • Тест-план: ручные сценарии + автотесты
  • Тестирование на разных macOS (Ventura, Sonoma, Sequoia)
  • Тестирование терминалов (Warp, iTerm, Terminal, Alacritty, Kitty)
  • Edge cases: нет конфига, битый JSON, сервис зависает,
    терминал не установлен, нет интернета, Mac проснулся из sleep
  • Тестирование LaunchAgent (выживает ли перезагрузку, логин/логаут)
  • Проверка нотификаций (разрешения, клик, действия)

Требования:
  • macOS power user
  • Умение писать shell-скрипты для тестовых стендов
  • Желательно: опыт с XCTest
```

---

### 2.2 Расширенный состав (v1.1+, по необходимости)

```
┌─────────────────────────────────────────────────────────────────┐
│  Роль              Кол-во   Когда нужен      Занятость          │
├─────────────────────────────────────────────────────────────────┤
│  Designer           1       перед v1.1        20-30%, точечно   │
│  DevOps / Release   1       неделя 4-5        30%               │
│  Tech Writer        1       перед релизом     20%, точечно      │
└─────────────────────────────────────────────────────────────────┘
```

#### Designer (v1.1)

```
Зона ответственности:
  • Иконка для menu bar (SF Symbols или кастом)
  • Иконка приложения (.icns)
  • Если будет Settings UI — макет окна настроек

Когда подключать:
  • После того как MVP работает и понятен scope UI
```

#### DevOps / Release Engineer

```
Зона ответственности:
  • GitHub Actions: сборка, тесты, линтер
  • Notarization + signing (если будет распространение)
  • Homebrew formula / tap
  • DMG / pkg installer (опционально)

Когда подключать:
  • Когда код стабилен, перед первым публичным релизом
```

#### Tech Writer

```
Зона ответственности:
  • README.md
  • man page для CLI
  • Страница на GitHub с GIF-демо

Когда подключать:
  • За неделю до релиза, когда CLI-интерфейс заморожен
```

---

## 3. План по шагам

### Фаза 0 — Подготовка (2 дня)

```
Шаг   Что делаем                              Кто           Результат
────────────────────────────────────────────────────────────────────────
0.1   Создать репозиторий, Package.swift,      Lead          Пустой проект собирается
      структуру папок, .gitignore                            swift build проходит

0.2   Определить модели данных:                Lead          Config.swift
      AppConfig, ServiceConfig, CheckConfig,                 CheckResult.swift
      CheckResult, CodableCheckResult                        Компилируется, покрыто тестами

0.3   Написать ConfigManager:                  Lead          Конфиг читается, пишется,
      load / save / createExample / validate                 создаётся пример
                                                             Тест: битый JSON не крашит

0.4   Создать config.example.json              Lead          Лежит в репо, документирован

0.5   Настроить линтер (SwiftLint),            Lead          CI-ready
      .editorconfig, PR-шаблон
```

**Критерий выхода из фазы:** `swift build` проходит, конфиг читается/пишется, есть тесты на Config.

---

### Фаза 1 — Core: проверки (4-5 дней)

```
Шаг   Что делаем                              Кто           Результат
────────────────────────────────────────────────────────────────────────
1.1   ServiceChecker: process check            Dev A         pgrep -x работает
      (через Process + pgrep)                                Тест: находит/не находит процесс

1.2   ServiceChecker: port check               Dev A         TCP connect через NWConnection
      (через Network.framework)                              Тест: открытый/закрытый порт

1.3   ServiceChecker: HTTP check               Dev A         URLSession GET + status code
      (через URLSession)                                     Тест: 200 OK / timeout / refused

1.4   ServiceChecker: command check            Dev A         Произвольная shell-команда
      (через Process + /bin/zsh -c)                          Тест: exit 0 vs exit 1

1.5   ServiceChecker.checkAll()                Dev A         Параллельная проверка всех
      async, TaskGroup                                       сервисов, результат в порядке
                                                             конфига

1.6   ServiceRunner: exec() и run()            Dev A         Запуск shell-команд,
      поддержка cwd                                          поддержка рабочей директории

1.7   StateManager: save/load results          Dev A         JSON на диск, чтение обратно
      + HistoryLogger: append to log                         Аппенд в history.log
```

**Критерий выхода:** можно из кода вызвать `ServiceChecker.checkAll()` с тестовым конфигом и получить массив `CheckResult`. Результаты сохраняются на диск.

---

### Фаза 2 — CLI (4-5 дней)

```
Шаг   Что делаем                              Кто           Результат
────────────────────────────────────────────────────────────────────────
2.1   ANSIColors + ReportBuilder               Dev A         Красивый цветной вывод
                                                             Поддержка --no-color

2.2   CLIRouter: парсинг аргументов,           Dev A         Роутинг работает,
      help, version, unknown command                         help выводится

2.3   StatusCommand                            Dev A         startwatch status
                                                             Читает кэш или проверяет live
                                                             Поддержка --json, --tag
                                                             Exit code = кол-во упавших

2.4   CheckCommand                             Dev A         startwatch check
                                                             Всегда свежая проверка

2.5   StartCommand                             Dev A         startwatch start redis
                                                             Fuzzy match по имени

2.6   RestartCommand                           Dev A         startwatch restart all
                                                             Перезапуск только упавших

2.7   ConfigCommand                            Dev A         startwatch config
                                                             Открывает $EDITOR
                                                             --path, --show флаги

2.8   LogCommand                               Dev A         startwatch log
                                                             tail последних N строк

2.9   DoctorCommand                            Dev A         startwatch doctor
                                                             Проверка конфига, daemon,
                                                             LaunchAgent, терминала,
                                                             нотификаций
```

**Критерий выхода:** все CLI-команды работают standalone (без daemon). `startwatch status` выводит красивый отчёт. `startwatch restart all` реально запускает сервисы.

---

### Фаза 3 — Daemon: menu bar agent (4-5 дней)

```
Шаг   Что делаем                              Кто           Результат
────────────────────────────────────────────────────────────────────────
3.1   DaemonCommand + AppDelegate              Dev B         startwatch daemon
      NSApplication.accessory mode                           запускается как agent
                                                             без иконки в dock

3.2   MenuBarController: иконка,               Dev B         Иконка в menu bar
      базовое меню (Quit)                                    ● или ◐

3.3   MenuBarController: список сервисов       Dev B         Меню показывает
      в меню с иконками ✅/❌                                статус каждого сервиса

3.4   CheckScheduler: таймер                   Dev B         Проверка каждые N минут
      RunLoop.main.common mode                               Работает даже когда
                                                             меню открыто

3.5   Связать: AppDelegate координирует        Dev B         Проверка → обновление меню
      checker → menubar → state                              → сохранение на диск

3.6   MenuBarController: кнопки                Dev B         Check Now ⌘R
      Check Now, Open Config                                 Open Config ⌘,

3.7   MenuBarController:                       Dev B         ★ Open CLI in {Terminal} ⌘T
      кнопка "Open CLI"                                      Открывает настроенный
                                                             терминал с `startwatch status`
```

**Критерий выхода:** `startwatch daemon` показывает иконку в menu bar, проверяет сервисы по таймеру, меню отражает текущий статус, кнопка "Open CLI" открывает терминал.

---

### Фаза 4 — Терминалы (3 дня)

```
Шаг   Что делаем                              Кто           Результат
────────────────────────────────────────────────────────────────────────
4.1   TerminalProtocol + TerminalLauncher      Dev B         Протокол, роутер

4.2   AppleTerminal (самый простой,            Dev B         do script через osascript
      всегда доступен — baseline)

4.3   WarpTerminal                             Dev B         Открытие через
                                                             open -a Warp + скрипт

4.4   ITermTerminal                            Dev B         AppleScript: create window
                                                             with default profile

4.5   AlacrittyTerminal                        Dev B         CLI: alacritty -e zsh -c ...

4.6   KittyTerminal                            Dev B         CLI: kitty zsh -c ...

4.7   Чтение поля "terminal" из конфига        Dev B         Конфиг определяет
      + fallback на Terminal.app                             какой терминал открывать

4.8   TerminalLauncher.isAvailable()           Dev B         Doctor проверяет
      для DoctorCommand                                      доступность терминала
```

**Критерий выхода:** "Open CLI" в menu bar открывает правильный терминал. Работает Warp, iTerm, Terminal. Остальные — best effort.

---

### Фаза 5 — Нотификации (2-3 дня)

```
Шаг   Что делаем                              Кто           Результат
────────────────────────────────────────────────────────────────────────
5.1   NotificationManager: setup,              Dev B         Запрос разрешений,
      requestAuthorization                                   категории, действия

5.2   sendAlert() при обнаружении              Dev B         Уведомление появляется
      упавших сервисов                                       "Не работает: Redis, API..."

5.3   Действие "Открыть в терминале"           Dev B         Клик по уведомлению →
      через UNNotificationAction                             открывается терминал
                                                             с startwatch status

5.4   Действие "Перезапустить всё"             Dev B         Кнопка в уведомлении →
      через UNNotificationAction                             startwatch restart all
                                                             в терминале

5.5   Поддержка config.notifications:          Dev B         enabled, onlyOnFailure,
      enabled / onlyOnFailure / sound                        sound — читаются из конфига

5.6   Показ уведомлений в foreground           Dev B         willPresent delegate
      (banner + sound)                                       Видно даже когда app активен
```

**Критерий выхода:** при падении сервиса появляется нативное уведомление. Клик открывает терминал. Кнопка "Перезапустить" запускает рестарт.

---

### Фаза 6 — IPC: CLI ↔ Daemon (2-3 дня)

```
Шаг   Что делаем                              Кто           Результат
────────────────────────────────────────────────────────────────────────
6.1   IPCMessage: enum с Codable               Lead/Dev A    Протокол сообщений

6.2   IPCClient: чтение last_check.json        Dev A         CLI читает кэш daemon
      (файловый IPC — v1.0)                                  Не делает лишних проверок

6.3   IPCClient.isConnected():                 Dev A         Doctor может проверить
      pgrep startwatch daemon                                что daemon жив

6.4   StatusCommand: сначала кэш,              Dev A         Быстрый отклик если
      потом live проверка                                    daemon работает

6.5   (v1.1) IPCServer: Unix Domain Socket     Lead          Daemon слушает на сокете
      в daemon                                               ~/.local/state/startwatch/sock

6.6   (v1.1) IPCClient: отправка команд        Lead          CLI может попросить daemon
      через сокет                                            сделать check / restart
```

**Критерий выхода v1.0:** CLI читает кэшированные результаты daemon. Не нужно ждать проверку если daemon уже проверил.

---

### Фаза 7 — Интеграция и LaunchAgent (2 дня)

```
Шаг   Что делаем                              Кто           Результат
────────────────────────────────────────────────────────────────────────
7.1   main.swift: роутинг daemon vs CLI        Lead          Один бинарник, два режима

7.2   com.user.startwatch.plist                Lead          LaunchAgent:
      RunAtLoad + KeepAlive                                  автозапуск + автоперезапуск

7.3   Установочный скрипт:                     Lead          install.sh: копирует
      install.sh                                             бинарник, plist, создаёт
                                                             конфиг-директории

7.4   startwatch doctor:                       Dev A         Проверяет всю цепочку:
      финальная интеграция                                   конфиг → daemon → терминал
                                                             → нотификации → LaunchAgent
```

**Критерий выхода:** после `./install.sh` и перезагрузки Mac всё работает автоматически.

---

### Фаза 8 — QA и полировка (3-5 дней)

```
Шаг   Что делаем                              Кто           Результат
────────────────────────────────────────────────────────────────────────
8.1   Тест-план: написать сценарии             QA            Документ с тест-кейсами

8.2   Ручное тестирование на Ventura           QA            Баг-репорты

8.3   Ручное тестирование на Sonoma            QA            Баг-репорты

8.4   Ручное тестирование на Sequoia           QA            Баг-репорты

8.5   Тест: каждый терминал                    QA            Warp ✓ iTerm ✓ Terminal ✓
                                                             Alacritty ✓ Kitty ✓

8.6   Тест: edge cases                        QA            Нет конфига, битый JSON,
                                                             нет терминала, sleep/wake,
                                                             deny notifications

8.7   Фикс багов                               Dev A+B       Все critical/high пофикшены

8.8   Unit-тесты: ≥70% покрытие Core/          Dev A         ConfigTests,
                                                             ServiceCheckerTests

8.9   README.md + install instructions         Lead          Готов к релизу
```

---

### Фаза 9 — Релиз v1.0 (1-2 дня)

```
Шаг   Что делаем                              Кто           Результат
────────────────────────────────────────────────────────────────────────
9.1   Финальный code freeze                    Lead          Только баг-фиксы

9.2   Тег v1.0.0, GitHub Release               Lead          Бинарник в release assets

9.3   (опц.) Homebrew formula                  DevOps        brew install startwatch

9.4   (опц.) Notarization                     DevOps        Можно запускать без
                                                             Gatekeeper warnings
```

---

## 4. Roadmap

```
Неделя    Фаза              Кто задействован
──────────────────────────────────────────────────────────────

  1       Фаза 0: Setup     Lead
          Фаза 1: Core      Lead + Dev A
                             ────────────────────────────
  2       Фаза 2: CLI       Dev A
          Фаза 3: Daemon    Dev B (подключается)
                             ────────────────────────────
  3       Фаза 4: Terminal  Dev B
          Фаза 5: Notify    Dev B
          Фаза 6: IPC       Dev A + Lead
                             ────────────────────────────
  4       Фаза 7: Интегр.   Lead + Dev A + Dev B
          Фаза 8: QA        QA (подключается)
                             ────────────────────────────
  5       Фаза 8: Фиксы     Dev A + Dev B + QA
          Фаза 9: Релиз     Lead + DevOps (подключается)

──────────────────────────────────────────────────────────────
          v1.0 RELEASE       ~ 5 недель
──────────────────────────────────────────────────────────────

  6-7     v1.1 Planning      Lead
          • Unix socket IPC (полноценный)
          • Settings window (SwiftUI)
          • Кастомная иконка (Designer подключается)
          • TOML/YAML конфиг
          • Группировка по тегам в меню

  8-10    v1.2 Planning
          • Auto-start сервисов при запуске Mac
          • Dashboard: мини-окно со статусами
          • Webhooks (Slack/Telegram при падении)
          • brew services интеграция
          • Сбор метрик (uptime каждого сервиса)

  11+     v2.0 Planning
          • GUI Settings (SwiftUI)
          • Drag & drop конфигурация
          • Несколько профилей (work / personal)
          • Распространение через App Store (sandbox)
```

---

## 5. Визуализация подключения людей

```
        Неделя 1    Неделя 2    Неделя 3    Неделя 4    Неделя 5
        ─────────   ─────────   ─────────   ─────────   ─────────

Lead    ████████████████████████████████████████████████████████████
        setup       review      IPC         integration  release
        core arch   PR review   architect   coordinator  tag+ship

Dev A   ████████████████████████████████████████████████████░░░░░░░
        core        CLI         IPC         fix bugs     done
        checker     commands    client      polish

Dev B               ████████████████████████████████████░░░░░░░░░░░
                    daemon      terminal    fix bugs     done
                    menu bar    notify      polish

QA                                          ████████████████████████
                                            test plan    regression
                                            manual QA    sign off

DevOps                                                   ██████████
                                                         CI/CD
                                                         homebrew

Designer                                                 ░░░░░░░░░░
        (v1.1)                                           icons
                                                         concepts
```

Легенда: `█` — активная работа, `░` — частичная/по запросу

---

## 6. Риски

```
Риск                                    Вероятность   Импакт   Митигация
──────────────────────────────────────────────────────────────────────────
Warp не поддерживает open + script      Средняя       Высокий  Fallback на AppleScript,
                                                               тестировать рано

Нотификации требуют .app bundle         Высокая       Высокий  Обернуть бинарник в
для UNUserNotificationCenter                                   .app bundle (Info.plist)

Apple ужесточит sandbox /               Низкая        Средний  Не зависеть от одного
Gatekeeper в следующей macOS                                   способа запуска терминала

LaunchAgent не стартует                 Средняя       Средний  Doctor command проверяет,
после обновления macOS                                         install.sh пересоздаёт

Один разработчик вместо двух            Высокая       Средний  Приоритет: Core → CLI →
                                                               Daemon. Терминалы —
                                                               только Warp + Terminal
```

---

## 7. Definition of Done (v1.0)

```
Функциональность:
  ☐ Конфиг читается из ~/.config/startwatch/config.json
  ☐ 4 типа проверок работают (process, port, http, command)
  ☐ CLI: status, check, start, restart, config, log, doctor
  ☐ Menu bar: иконка статуса, список сервисов, Open CLI, Check Now
  ☐ Нотификации при падении сервисов
  ☐ Клик по нотификации открывает терминал
  ☐ Поддержка минимум 3 терминалов (Terminal, Warp, iTerm)
  ☐ Настройка терминала через конфиг
  ☐ LaunchAgent для автозапуска
  ☐ Проверка каждые N минут (настраивается)

Качество:
  ☐ Нет крашей на пустом/битом конфиге
  ☐ Graceful degradation если терминал не найден
  ☐ Unit-тесты на Core (≥70%)
  ☐ Тестирование на macOS Ventura + Sonoma
  ☐ README с инструкцией установки
  ☐ startwatch doctor проходит все проверки
```
