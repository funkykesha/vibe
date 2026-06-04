---
title: Как разработать плагин VS Code — создай своего AI помощника для проекта
description: Полное руководство по созданию плагина VS Code с поддержкой шаблонов проектов, AI чата и многофайловой аналитики
---

<!-- nav -->
**📚 Версии:** [Кратко](../../../lesson-summaries/stage-3/cross-platform/vscode-extension.md) · [Расширенно](../../../lesson-summaries-full/stage-3/cross-platform/vscode-extension.md) · **Полный перевод** · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-3/cross-platform/vscode-extension/index.md)

# Как разработать плагин VS Code — создай своего AI помощника для проекта

# Глава 1: Что такое разработка плагинов VS Code

В этом уроке мы создадим полный цикл: с нуля разработаем плагин VS Code, который будет твоим AI помощником по проектам — встроенные шаблоны проектов с одним кликом, поддержка диалогов с AI для выбранных файлов или кода, многофайловой вопрос-ответ для уточнения, а также пользовательские горячие клавиши. Ты самостоятельно завершишь разработку, отладку плагина и научишься публиковать его на рынке плагинов VS Code.

Для этого урока тебе нужно:

- Node.js (версия 18.0 и выше)
- VS Code (версия 1.90 и выше)
- Твой AI помощник программирования (Cursor / Trae / Claude Code)
- (опционально) Подписка на GitHub Copilot (для использования Language Model API)

> **Полный процесс на Vibe Coding**: Мы будем использовать AI помощника для генерации большей части кода, тебе нужно только понимать основные концепции и архитектуру, затем описывать требования на естественном языке.

## 1.1 Что может делать плагин VS Code?

Ты каждый день используешь плагины VS Code — Prettier помогает форматировать код, GitLens показывает историю Git, GitHub Copilot помогает писать код. По сути, это всё программы на TypeScript/JavaScript, которые используют API VS Code для расширения функциональности редактора.

Плагины VS Code могут делать гораздо больше, чем ты думаешь:

* **Добавлять новые элементы UI**: панели боковой панели, информация в строке состояния, пользовательские страницы Webview
* **Работать с файлами и кодом**: читать, изменять, создавать файлы, анализировать структуру кода
* **Интегрировать внешние сервисы**: вызывать API, подключаться к базам данных, интегрироваться с CI/CD
* **Расширять возможности редактора**: пользовательская поддержка языков, автодополнение кода, диагностические подсказки
* **Добавлять AI способности**: создавать AI помощников для диалогов через Chat Participant API, вызывать большие языковые модели через Language Model API

![Экосистема плагинов VS Code, показывающая различные области расширения: боковая панель, редактор, строка состояния, палитра команд, панель Chat](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/vscode-extension/images/image1.png)

## 1.2 Основная архитектура плагина VS Code

Плагин VS Code запускается в отдельном процессе **Extension Host (хост плагинов)**, изолированном от главного процесса редактора, так что даже если плагин упадёт, редактор продолжит работать.

Плагин состоит из нескольких основных частей:

* **package.json (манифест плагина)**: "паспорт" плагина, объявляет имя, файл входа, точки контрибуции (commands, menus, keybindings и т.д.)
* **extension.ts (файл входа)**: "мозг" плагина, экспортирует две функции `activate()` и `deactivate()`
* **Contribution Points (точки контрибуции)**: объявляются в package.json, это то, что плагин "вносит" в VS Code — команды, пункты меню, горячие клавиши, виды боковой панели и т.д.
* **VS Code API**: полный набор TypeScript API для работы со всеми аспектами редактора

```
VS Code редактор
    │
    ├── Extension Host (процесс хоста плагинов)
    │   ├── Твой плагин
    │   │   ├── package.json  → объявляет "что я могу делать"
    │   │   ├── extension.ts  → реализует "как это делать"
    │   │   └── другие модули → код конкретной функциональности
    │   ├── другой плагин A
    │   └── другой плагин B
    │
    └── Главный процесс редактора (UI рендеринг)
```

![Архитектура плагина VS Code, показывающая отношение процесса Extension Host к главному процессу редактора](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/vscode-extension/images/image2.png)

## 1.3 Какой плагин мы будем разрабатывать?

Мы разработаем плагин **"AI Project Bot"** — твой AI помощник по проектам со следующими функциями:

| Функция | Описание |
|---------|---------|
| Шаблоны проектов | Боковая панель показывает список шаблонов проектов, создаёт новые скелеты проектов в один клик |
| AI диалог | Создаёт участника `@project-bot` в панели Chat VS Code, поддерживает вопросы по проектам |
| Chat выбранного файла/отрывка | Правый клик на выбранном коде или файле, сразу отправить AI для анализа, объяснения, рефакторинга |
| Вопрос-ответ с несколькими файлами | Мультиселект файлов в проводнике, одна кнопка — AI разберёт отношения между файлами и логику |
| Горячие клавиши | Пользовательские комбинации клавиш для быстрого запуска часто используемых операций |

![Предпросмотр эффекта плагина AI Project Bot, показывающий список шаблонов на боковой панели, диалог @project-bot в панели Chat, правое контекстное меню](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/vscode-extension/images/image3.png)

## 1.4 Дорожная карта этого урока

Мы завершим процесс в следующих шагах:

1. **Создать проект плагина** (3 минуты): используя скрипт, сгенерировать скелет проекта, понять основные файлы
2. **Реализовать функцию шаблонов проектов** (5 минут): использовать TreeView для показа шаблонов на боковой панели, создать проект одной кнопкой
3. **Реализовать AI Chat участника** (5 минут): использовать Chat Participant API для создания `@project-bot`
4. **Реализовать Chat выбранного файла/отрывка и многофайловый вопрос-ответ** (5 минут): контекстное меню + мультиселект файлов + AI анализ
5. **Добавить горячие клавиши и UX оптимизацию** (3 минуты): пользовательские горячие клавиши, подсказки в строке состояния
6. **Опубликовать на рынке плагинов** (опционально): упаковать и отправить на рецензию

# Глава 2: Создание проекта плагина (3 минуты)

## 2.1 Генерирование проекта с помощью скрипта

VS Code официально предоставляет инструмент Yeoman для быстрого создания проекта плагина. Попроси AI помочь с выполнением:

```
Помоги мне установить скрипт для разработки плагинов VS Code и создать проект:
1. Установить Yeoman и генератор для VS Code плагинов: npm install -g yo generator-code
2. Запустить yo code для генерирования проекта, выбери следующие параметры:
   - Тип: New Extension (TypeScript)
   - Имя: ai-project-bot
   - Идентификатор: ai-project-bot
   - Описание: AI помощник по проектам — генерирование шаблонов, интеллектуальный диалог, многофайловый вопрос-ответ
   - Менеджер пакетов: npm
3. Перейти в директорию проекта и установить зависимости
```

Структура сгенерированного проекта:

```
ai-project-bot/
├── .vscode/
│   ├── launch.json          # конфигурация отладки (F5 для запуска отладки)
│   └── tasks.json           # задачи компиляции
├── src/
│   └── extension.ts         # файл входа плагина
├── package.json             # манифест плагина (самый важный файл)
├── tsconfig.json            # конфигурация TypeScript
└── vsc-extension-quickstart.md  # справка по быстрому старту (можно удалить)
```

## 2.2 Понимание package.json — "паспорт" плагина

`package.json` — самый важный файл плагина VS Code. Кроме стандартной информации npm пакета, в нём есть поле `contributes`, объявляющее всё, что плагин "вносит" в VS Code:

```json
{
  "name": "ai-project-bot",
  "displayName": "AI Project Bot",
  "description": "AI помощник по проектам — генерирование шаблонов, интеллектуальный диалог, многофайловый вопрос-ответ",
  "version": "0.0.1",
  "engines": { "vscode": "^1.90.0" },
  "activationEvents": [],
  "main": "./out/extension.js",
  "contributes": {
    "commands": [],
    "menus": {},
    "keybindings": [],
    "viewsContainers": {},
    "views": {},
    "chatParticipants": []
  }
}
```

**Объяснение ключевых полей:**

| Поле | Функция |
|------|---------|
| `engines.vscode` | Минимальная версия VS Code для плагина |
| `activationEvents` | Когда активировать плагин (пусто означает активацию по требованию) |
| `main` | Путь к скомпилированному файлу входа |
| `contributes` | Все функции, вносимые плагином (команды, меню, горячие клавиши, виды и т.д.) |

![Скриншот файла package.json в редакторе с подсвеченным полем contributes](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/vscode-extension/images/image4.png)

## 2.3 Понимание extension.ts — "мозг" плагина

Открой `src/extension.ts`, ты увидишь две основные функции:

```typescript
import * as vscode from 'vscode'

// Вызывается при активации плагина (первый запуск команды, открытие определённого файла и т.д.)
export function activate(context: vscode.ExtensionContext) {
  console.log('AI Project Bot активирован!')

  // Зарегистрируй команды, виды, Chat участников и т.д. здесь
  const disposable = vscode.commands.registerCommand(
    'ai-project-bot.helloWorld',
    () => {
      vscode.window.showInformationMessage('Hello from AI Project Bot!')
    }
  )

  context.subscriptions.push(disposable)
}

// Вызывается при деактивации плагина (когда VS Code закрывается)
export function deactivate() {}
```

**Основные концепции:**

* `activate(context)`: функция инициализации плагина, все функции регистрируются здесь
* `context.subscriptions`: массив "сборщика мусора", помещаем туда зарегистрированные вещи, VS Code автоматически их очищает при деактивации плагина
* `vscode.commands.registerCommand`: регистрирует команду, пользователь может её вызвать через палитру команд (Ctrl+Shift+P)

## 2.4 Запуск отладки

Нажми **F5**, VS Code откроет новое окно **Extension Development Host** — это новый экземпляр VS Code с загруженным плагином.

В новом окне нажми **Ctrl+Shift+P**, введи "Hello World", ты увидишь сообщение в правом нижнем углу. Это значит, что плагин работает.

![Скриншот отладки плагина VS Code, показывающий окно Extension Development Host и сообщение Hello World](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/vscode-extension/images/image5.png)

> **Советы отладки**: После изменения кода в окне Extension Development Host нажми **Ctrl+Shift+P** → **"Developer: Reload Window"**, плагин перезагрузится без перезагрузки отладки.

# Глава 3: Реализация функции шаблонов проектов (5 минут)

## 3.1 Проектирование системы шаблонов

Нам нужно добавить панель "Шаблоны проектов" на боковую панель VS Code, где пользователи могут просматривать список шаблонов и создавать новые скелеты проектов одним кликом. Это требует **TreeView API** VS Code.

Попроси AI помочь с реализацией:

```
Помоги мне реализовать функцию шаблонов проектов в плагине ai-project-bot:

1. В package.json добавь следующие точки контрибуции:
   - Новый viewsContainers.activitybar элемент с id "project-bot", title "AI Project Bot"
   - Во время в этом контейнере добавь view с id "projectTemplates", name "Шаблоны проектов"
   - Добавь команду "ai-project-bot.createFromTemplate", title "Создать проект из шаблона"

2. Создай src/templates/templateProvider.ts:
   - Реализуй TreeDataProvider с следующими шаблонами категорий:
     - Фронтенд: React + TypeScript, Vue 3 + TypeScript, Next.js App
     - Бэкенд: Express API, FastAPI Python
     - Полнофункциональный: T3 Stack (Next.js + tRPC + Prisma)
   - Каждый элемент шаблона показывает имя, описание и иконку

3. Создай src/templates/scaffolder.ts:
   - Реализуй функцию createProjectFromTemplate
   - Позволи пользователю выбрать целевую папку
   - Сгенерируй структуру файлов соответствующего проекта по типу шаблона
```

[Остальной контент продолжится инкрементально из-за размера файла]

## 3.2 Объявление видов в package.json

Сначала добавь вид боковой панели в раздел `contributes` в `package.json`:

```json
{
  "contributes": {
    "viewsContainers": {
      "activitybar": [
        {
          "id": "project-bot",
          "title": "AI Project Bot",
          "icon": "resources/bot-icon.svg"
        }
      ]
    },
    "views": {
      "project-bot": [
        {
          "id": "projectTemplates",
          "name": "Шаблоны проектов"
        }
      ]
    },
    "commands": [
      {
        "command": "ai-project-bot.createFromTemplate",
        "title": "Создать проект из шаблона",
        "icon": "$(add)"
      }
    ],
    "menus": {
      "view/title": [
        {
          "command": "ai-project-bot.createFromTemplate",
          "when": "view == projectTemplates",
          "group": "navigation"
        }
      ]
    }
  }
}
```

Эта конфигурация делает три вещи:

1. Добавляет иконку "AI Project Bot" на левую панель активности
2. Создаёт вид "Шаблоны проектов" под этой иконкой
3. Добавляет кнопку "+" на заголовок вида для создания проекта

![Скриншот боковой панели VS Code, показывающий иконку AI Project Bot и список шаблонов проектов](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/vscode-extension/images/image6.png)

## 3.3 Реализация TreeDataProvider

TreeDataProvider — это интерфейс VS Code для заполнения данных дерева. Нужно реализовать два метода: `getTreeItem` (информация отображения одного узла) и `getChildren` (список дочерних узлов).

Основной код:

```typescript
// src/templates/templateProvider.ts
import * as vscode from 'vscode'

interface Template {
  name: string
  description: string
  category: string
  command: string // команда для генерирования проекта, например "npx create-react-app"
}

const TEMPLATES: Template[] = [
  { name: 'React + TypeScript', description: 'React проект построенный с Vite', category: 'Фронтенд', command: 'npm create vite@latest {{name}} -- --template react-ts' },
  { name: 'Vue 3 + TypeScript', description: 'Vue 3 проект построенный с Vite', category: 'Фронтенд', command: 'npm create vite@latest {{name}} -- --template vue-ts' },
  { name: 'Next.js App', description: 'Next.js App Router полнофункциональный проект', category: 'Фронтенд', command: 'npx create-next-app@latest {{name}} --typescript --app' },
  { name: 'Express API', description: 'Express + TypeScript REST API', category: 'Бэкенд', command: 'npx create-express-api {{name}}' },
  { name: 'FastAPI Python', description: 'Python FastAPI бэкенд проект', category: 'Бэкенд', command: 'pip install fastapi uvicorn' },
]

// Узел дерева: категория или шаблон
class TemplateItem extends vscode.TreeItem {
  constructor(
    public readonly label: string,
    public readonly collapsibleState: vscode.TreeItemCollapsibleState,
    public readonly template?: Template
  ) {
    super(label, collapsibleState)
    if (template) {
      this.description = template.description
      this.tooltip = `${template.name}\n${template.description}\nКоманда: ${template.command}`
      this.contextValue = 'template'
      this.command = {
        command: 'ai-project-bot.createFromTemplate',
        title: 'Создать проект',
        arguments: [template]
      }
    }
  }
}

export class TemplateProvider implements vscode.TreeDataProvider<TemplateItem> {
  getTreeItem(element: TemplateItem): vscode.TreeItem {
    return element
  }

  getChildren(element?: TemplateItem): TemplateItem[] {
    if (!element) {
      // Корневые узлы: верни список категорий
      const categories = [...new Set(TEMPLATES.map(t => t.category))]
      return categories.map(
        cat => new TemplateItem(cat, vscode.TreeItemCollapsibleState.Expanded)
      )
    }
    // Дочерние узлы: верни шаблоны этой категории
    return TEMPLATES
      .filter(t => t.category === element.label)
      .map(t => new TemplateItem(t.name, vscode.TreeItemCollapsibleState.None, t))
  }
}
```

## 3.4 Регистрация вида и команды создания

В `extension.ts` зарегистрируй TreeView и команду создания проекта:

```typescript
// src/extension.ts
import { TemplateProvider } from './templates/templateProvider'

export function activate(context: vscode.ExtensionContext) {
  // Зарегистрируй вид шаблонов
  const templateProvider = new TemplateProvider()
  vscode.window.registerTreeDataProvider('projectTemplates', templateProvider)

  // Зарегистрируй команду создания проекта
  const createCmd = vscode.commands.registerCommand(
    'ai-project-bot.createFromTemplate',
    async (template) => {
      if (!template) {
        // Если нет шаблона (вызов из палитры команд), позволь пользователю выбрать
        const pick = await vscode.window.showQuickPick(
          TEMPLATES.map(t => ({ label: t.name, description: t.description, template: t })),
          { placeHolder: 'Выбери шаблон проекта' }
        )
        if (!pick) return
        template = pick.template
      }

      // Позволь пользователю ввести имя проекта
      const name = await vscode.window.showInputBox({
        prompt: 'Введи имя проекта',
        placeHolder: 'my-awesome-project'
      })
      if (!name) return

      // Позволь пользователю выбрать целевую папку
      const folder = await vscode.window.showOpenDialog({
        canSelectFolders: true,
        openLabel: 'Выбери место для проекта'
      })
      if (!folder) return

      // Выполни команду создания
      const terminal = vscode.window.createTerminal('AI Project Bot')
      terminal.show()
      const cmd = template.command.replace('{{name}}', name)
      terminal.sendText(`cd "${folder[0].fsPath}" && ${cmd}`)

      vscode.window.showInformationMessage(`Создаю ${template.name} проект: ${name}`)
    }
  )

  context.subscriptions.push(createCmd)
}
```

Теперь нажми F5 для отладки, ты увидишь иконку AI Project Bot на левой панели, кликнув откроет список шаблонов, кликнув на шаблон создаст проект.

![Скриншот появления диалога ввода имени проекта и диалога выбора папки после клика на шаблон](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/vscode-extension/images/image7.png)

# Глава 4: Реализация AI Chat участника (5 минут)

## 4.1 Что такое Chat Participant API?

С версии VS Code 1.90 плагины могут создавать своих AI помощников в панели Chat через **Chat Participant API**. Когда пользователь введёт `@project-bot помоги разобраться в архитектуре проекта`, плагин получит это сообщение и вернёт ответ, сгенерированный AI.

Основные концепции Chat Participant API:

* **Participant (участник)**: идентификация твоего AI помощника в панели Chat, вызывается как `@имя`
* **Slash Commands (команды с косой чертой)**: быстрые команды, поддерживаемые участником, такие как `/explain`, `/refactor`
* **Language Model API**: вызов встроенной большой языковой модели VS Code (например, GPT-4o от Copilot) для генерирования ответов
* **Stream (потоковая передача)**: пошаговый вывод содержимого ответа через `stream.markdown()`

## 4.2 Объявление Chat участника в package.json

В раздел `contributes` добавь:

```json
{
  "contributes": {
    "chatParticipants": [
      {
        "id": "ai-project-bot.projectBot",
        "name": "project-bot",
        "fullName": "AI Project Bot",
        "description": "Твой AI помощник по проектам, помогает разбираться в коде, объяснять архитектуру, генерировать решения",
        "isSticky": true
      }
    ]
  }
}
```

`isSticky: true` означает, что после выбора этого участника последующие сообщения будут отправляться ему по умолчанию, без необходимости каждый раз вводить `@project-bot`.

## 4.3 Реализация функции обработки Chat участника

Основной код:

```typescript
// src/chat/chatParticipant.ts
import * as vscode from 'vscode'

export function registerChatParticipant(context: vscode.ExtensionContext) {
  const participant = vscode.chat.createChatParticipant(
    'ai-project-bot.projectBot',
    async (request, chatContext, stream, token) => {
      // Получи доступные языковые модели
      const models = await vscode.lm.selectChatModels({ family: 'gpt-4o' })
      const model = models[0]

      if (!model) {
        stream.markdown('Не найдена доступная языковая модель. Убедись, что установлен GitHub Copilot.')
        return
      }

      // Построй разные системные подсказки для разных команд
      let systemPrompt = 'Ты профессиональный помощник по разработке проектов.'

      if (request.command === 'explain') {
        systemPrompt = 'Ты эксперт по объяснению кода. Объясни предоставленный пользователем код простым и понятным русским языком, включая функциональность, логику потока и ключевые решения в дизайне.'
      } else if (request.command === 'refactor') {
        systemPrompt = 'Ты эксперт по рефакторингу кода. Проанализируй предоставленный код, дай конкретные рекомендации по рефакторингу и примеры улучшенного кода.'
      } else if (request.command === 'template') {
        systemPrompt = 'Ты эксперт по выбору технологии. На основе описания требований проекта пользователя рекомендуй лучший технологический стек и шаблон проекта.'
      }

      // Построй сообщения
      const messages = [
        vscode.LanguageModelChatMessage.User(systemPrompt),
        vscode.LanguageModelChatMessage.User(request.prompt)
      ]

      // Потоковый вывод ответа
      const response = await model.sendRequest(messages, {}, token)
      for await (const chunk of response.stream) {
        stream.markdown(chunk)
      }

      return { metadata: { command: request.command || '' } }
    }
  )

  // Зарегистрируй команды с косой чертой
  participant.slashCommandProvider = {
    provideSlashCommands: () => [
      { name: 'explain', description: 'Объясни функциональность и логику кода' },
      { name: 'refactor', description: 'Дай рекомендации по рефакторингу и улучшению' },
      { name: 'template', description: 'Рекомендуй подходящий шаблон и технологический стек' }
    ]
  }

  // Зарегистрируй последующие предложения
  participant.followupProvider = {
    provideFollowups: (result) => {
      if (result.metadata?.command === 'explain') {
        return [
          { prompt: 'Можешь нарисовать диаграмму потока?', label: 'Сгенерируй диаграмму' },
          { prompt: 'Есть ли потенциальные баги?', label: 'Проверь потенциальные проблемы' }
        ]
      }
      return []
    }
  }

  context.subscriptions.push(participant)
}
```

В `extension.ts` вызови функцию регистрации:

```typescript
import { registerChatParticipant } from './chat/chatParticipant'

export function activate(context: vscode.ExtensionContext) {
  // ... предыдущий код регистрации шаблонов ...
  registerChatParticipant(context)
}
```

Теперь введи в панели Chat `@project-bot /explain что делает этот код?` и плагин будет вызывать большую модель для генерирования объяснения.

![Скриншот диалога @project-bot в панели Chat VS Code, показывающий использование команды /explain и потоковый ответ](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/vscode-extension/images/image8.png)

# Глава 5: Chat выбранного файла/отрывка и многофайловый вопрос-ответ (5 минут)

## 5.1 Контекстное меню: отправь выбранный код AI

Мы хотим, чтобы пользователи выбрали код в редакторе, кликнули правой кнопкой и отправили его AI для анализа. Это требует использования **Context Menu (контекстное меню)** VS Code.

Добавь в `package.json`:

```json
{
  "contributes": {
    "commands": [
      {
        "command": "ai-project-bot.explainSelection",
        "title": "AI: Объясни выбранный код"
      },
      {
        "command": "ai-project-bot.refactorSelection",
        "title": "AI: Рефакторь выбранный код"
      }
    ],
    "menus": {
      "editor/context": [
        {
          "command": "ai-project-bot.explainSelection",
          "when": "editorHasSelection",
          "group": "ai-project-bot@1"
        },
        {
          "command": "ai-project-bot.refactorSelection",
          "when": "editorHasSelection",
          "group": "ai-project-bot@2"
        }
      ]
    }
  }
}
```

**Объяснение ключевых настроек:**

* `when: "editorHasSelection"`: показывай эти пункты меню только если выбран код
* `group: "ai-project-bot@1"`: группировка пунктов меню, `@1` и `@2` контролируют порядок сортировки

## 5.2 Реализация анализа выбранного кода

```typescript
// src/commands/selectionCommands.ts
import * as vscode from 'vscode'

export function registerSelectionCommands(context: vscode.ExtensionContext) {
  // Объясни выбранный код
  const explainCmd = vscode.commands.registerCommand(
    'ai-project-bot.explainSelection',
    async () => {
      const editor = vscode.window.activeTextEditor
      if (!editor) return

      const selection = editor.selection
      const selectedText = editor.document.getText(selection)
      const fileName = editor.document.fileName.split('/').pop()
      const startLine = selection.start.line + 1
      const endLine = selection.end.line + 1

      // Построй подсказку с контекстом
      const prompt = [
        `Объясни следующий код (из ${fileName}, строки ${startLine}-${endLine}):`,
        '```',
        selectedText,
        '```',
        'Объясни: 1. Функциональность этого кода 2. Основная логика 3. Возможные улучшения'
      ].join('\n')

      // Вызови Language Model API
      const models = await vscode.lm.selectChatModels({ family: 'gpt-4o' })
      if (!models.length) {
        vscode.window.showErrorMessage('Не найдена доступная языковая модель')
        return
      }

      // Покажи результат в панели вывода
      const outputChannel = vscode.window.createOutputChannel('AI Project Bot')
      outputChannel.show()
      outputChannel.appendLine(`\n--- Объяснение кода (${fileName}:${startLine}-${endLine}) ---\n`)

      const messages = [
        vscode.LanguageModelChatMessage.User(prompt)
      ]
      const response = await models[0].sendRequest(messages, {})
      for await (const chunk of response.stream) {
        outputChannel.append(chunk)
      }
    }
  )

  context.subscriptions.push(explainCmd)
}
```

![Скриншот контекстного меню редактора VS Code после правого клика на выбранный код, показывающий пункты AI меню](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/vscode-extension/images/image9.png)

## 5.3 Многофайловый вопрос-ответ: групповой анализ отношений файлов

Это одна из самых мощных функций нашего плагина — мультиселект файлов в проводнике, одна кнопка — AI разберёт отношения между ними и логику.

Добавь контекстное меню проводника в `package.json`:

```json
{
  "contributes": {
    "commands": [
      {
        "command": "ai-project-bot.analyzeFiles",
        "title": "AI: Анализируй отношения выбранных файлов"
      }
    ],
    "menus": {
      "explorer/context": [
        {
          "command": "ai-project-bot.analyzeFiles",
          "when": "explorerResourceIsFile",
          "group": "ai-project-bot"
        }
      ]
    }
  }
}
```

Реализуй команду анализа нескольких файлов:

```typescript
// src/commands/multiFileAnalysis.ts
import * as vscode from 'vscode'

export function registerMultiFileCommands(context: vscode.ExtensionContext) {
  const analyzeCmd = vscode.commands.registerCommand(
    'ai-project-bot.analyzeFiles',
    async (clickedFile: vscode.Uri, selectedFiles: vscode.Uri[]) => {
      // selectedFiles содержит все выбранные файлы
      const files = selectedFiles || [clickedFile]

      if (files.length < 2) {
        vscode.window.showWarningMessage('Выбери минимум 2 файла для анализа')
        return
      }

      // Прочитай содержимое всех выбранных файлов
      const fileContents: string[] = []
      for (const file of files) {
        const content = await vscode.workspace.fs.readFile(file)
        const fileName = vscode.workspace.asRelativePath(file)
        fileContents.push(
          `--- ${fileName} ---\n${Buffer.from(content).toString('utf8')}`
        )
      }

      const prompt = [
        `Проанализируй отношения между следующими ${files.length} файлами:`,
        '',
        ...fileContents,
        '',
        'Объясни:',
        '1. Ответственность каждого файла',
        '2. Зависимости и отношения вызовов между ними',
        '3. Поток данных (если есть)',
        '4. Рекомендации по архитектуре или потенциальные проблемы'
      ].join('\n')

      // Вызови модель и покажи результат
      const models = await vscode.lm.selectChatModels({ family: 'gpt-4o' })
      if (!models.length) {
        vscode.window.showErrorMessage('Не найдена доступная языковая модель')
        return
      }

      const outputChannel = vscode.window.createOutputChannel('AI Project Bot')
      outputChannel.show()
      outputChannel.appendLine(
        `\n--- Анализ нескольких файлов (${files.length} файлов) ---\n`
      )

      const messages = [
        vscode.LanguageModelChatMessage.User(prompt)
      ]
      const response = await models[0].sendRequest(messages, {})
      for await (const chunk of response.stream) {
        outputChannel.append(chunk)
      }
    }
  )

  context.subscriptions.push(analyzeCmd)
}
```

Используется так: в проводнике удерживая Ctrl (на Mac — Cmd) выбери несколько файлов, кликни правой кнопкой и выбери "AI: Анализируй отношения выбранных файлов", AI прочитает все файлы и даст подробный анализ.

![Скриншот контекстного меню проводника после мультиселекта файлов, показывающего опцию AI анализа](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/vscode-extension/images/image10.png)

# Глава 6: Горячие клавиши и UX оптимизация (3 минуты)

## 6.1 Пользовательские горячие клавиши

Горячие клавиши — ключ к повышению производительности. Добавь в `package.json`:

```json
{
  "contributes": {
    "keybindings": [
      {
        "command": "ai-project-bot.explainSelection",
        "key": "ctrl+shift+e",
        "mac": "cmd+shift+e",
        "when": "editorTextFocus && editorHasSelection"
      },
      {
        "command": "ai-project-bot.refactorSelection",
        "key": "ctrl+shift+r",
        "mac": "cmd+shift+r",
        "when": "editorTextFocus && editorHasSelection"
      },
      {
        "command": "ai-project-bot.createFromTemplate",
        "key": "ctrl+shift+n",
        "mac": "cmd+shift+n",
        "when": ""
      }
    ]
  }
}
```

**Объяснение условий when:**

| Условие | Значение |
|---------|----------|
| `editorTextFocus` | Курсор в редакторе |
| `editorHasSelection` | Есть выбранный текст |
| `explorerViewletVisible` | Панель проводника видна |
| `!editorReadonly` | Файл не только для чтения |

Несколько условий соединяются с `&&` что означает "одновременно выполнено".

## 6.2 Подсказка в строке состояния

Добавь быстрый ввод в строку состояния, чтобы пользователи всегда знали, что плагин работает:

```typescript
// src/statusBar.ts
import * as vscode from 'vscode'

export function createStatusBarItem(context: vscode.ExtensionContext) {
  const statusBar = vscode.window.createStatusBarItem(
    vscode.StatusBarAlignment.Right,
    100
  )
  statusBar.text = '$(hubot) AI Bot'
  statusBar.tooltip = 'Кликни чтобы открыть AI Project Bot'
  statusBar.command = 'ai-project-bot.createFromTemplate'
  statusBar.show()

  context.subscriptions.push(statusBar)
}
```

`$(hubot)` — это синтаксис встроенной иконки VS Code, ты можешь найти все доступные иконки в [библиотеке Codicon](https://microsoft.github.io/vscode-codicons/dist/codicon.html).

![Скриншот строки состояния VS Code с показанием иконки AI Bot](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/vscode-extension/images/image11.png)

# Глава 7: Публикация на рынке плагинов (опционально)

## 7.1 Подготовка к публикации

Плагины VS Code упаковываются и публикуются через инструмент **vsce** (Visual Studio Code Extensions).

До публикации нужна подготовка:

1. **Учётная запись Azure DevOps**: посетите [dev.azure.com](https://dev.azure.com/), зарегистрируйтесь и создайте организацию
2. **Personal Access Token (PAT)**: создайте PAT в Azure DevOps с правами **Marketplace → Manage**
3. **Идентификатор издателя**: создайте идентификацию издателя на [VS Code Marketplace](https://marketplace.visualstudio.com/manage)

## 7.2 Завершение package.json

Перед публикацией добавь метаинформацию:

```json
{
  "publisher": "your-publisher-id",
  "repository": {
    "type": "git",
    "url": "https://github.com/yourname/ai-project-bot"
  },
  "categories": ["AI", "Other"],
  "keywords": ["ai", "project", "template", "chat"],
  "icon": "resources/icon.png",
  "galleryBanner": {
    "color": "#1e1e2e",
    "theme": "dark"
  }
}
```

Создай `README.md` как страницу описания плагина на рынке и `CHANGELOG.md` для записи изменений версии.

## 7.3 Упаковка и публикация

```bash
# Упаковка в .vsix файл (можно устанавливать вручную)
vsce package

# Публикация на рынке
vsce publish
```

После упаковки будет создан файл `ai-project-bot-0.0.1.vsix`. Ты можешь отправить его друзьям, они установят через "Install from VSIX" в VS Code.

Если хочешь официально опубликовать на рынке, выполни `vsce publish` и плагин появится на рынке VS Code за несколько минут.

> **Совет**: первая публикация может требовать рецензии. Убедись, что README чистый, скриншоты полные, рецензия пройдёт быстрее.

# Глава 8: На этом всё

Поздравляю! Ты построил полнофункциональный плагин VS Code с нуля. Вспомни что мы сделали:

1. Создал проект плагина через Yeoman, понял основную роль package.json и extension.ts
2. Использовал TreeView API для показа списка шаблонов на боковой панели, создания проекта в один клик
3. Использовал Chat Participant API для создания AI помощника `@project-bot` со слэш-командами и потоковыми ответами
4. Использовал контекстное меню для отправки выбранного кода AI для анализа
5. Использовал мультиселект файлов для группового анализа отношений между файлами
6. Добавил пользовательские горячие клавиши и подсказки в строке состояния

Пространство для воображения в разработке плагинов VS Code очень большое — все хорошие плагины, которые ты используешь каждый день, используют ту же технологию и архитектуру.

**Направления развития:**

* **Webview пользовательские панели**: используя HTML/CSS/JS для построения полностью пользовательских UI панелей, таких как визуализированные диаграммы архитектуры проектов, интерактивные интерфейсы кодовой рецензии
* **Language Model Tools**: зарегистрируй пользовательские инструменты чтобы AI мог вызывать твои функции, например запросы к базе данных, API запросы
* **Диагностика кода и CodeLens**: встроить AI предложения, подсказки по производительности, предупреждения по безопасности прямо в коде
* **Пользовательская поддержка языков**: предоставить синтаксис подсветки, автодополнение, проверку ошибок для определённых DSL или конфиг файлов
* **Удалённая разработка интеграция**: позволить плагину работать в SSH удалённой среде, контейнерах, WSL

***Твой редактор, твои правила.***

# Справочные материалы

* [VS Code Extension API официальная документация](https://code.visualstudio.com/api)
* [Chat Participant API руководство](https://code.visualstudio.com/api/extension-guides/chat)
* [Language Model API руководство](https://code.visualstudio.com/api/extension-guides/language-model)
* [TreeView API руководство](https://code.visualstudio.com/api/extension-guides/tree-view)
* [Webview API руководство](https://code.visualstudio.com/api/extension-guides/webview)
* [VS Code расширений руководство по публикации](https://code.visualstudio.com/api/working-with-extensions/publishing-extension)
* [Библиотека иконок Codicon](https://microsoft.github.io/vscode-codicons/dist/codicon.html)
