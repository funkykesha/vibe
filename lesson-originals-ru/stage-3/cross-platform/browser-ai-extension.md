---
title: Как разработать расширение браузера AI помощник — одна кнопка для суммирования любой веб-страницы
description: Полный гайд по разработке Chrome расширения, которое использует AI для суммирования веб-страниц
---

<!-- nav -->
**📚 Версии:** [Кратко](../../../lesson-summaries/stage-3/cross-platform/browser-ai-extension.md) · [Расширенно](../../../lesson-summaries-full/stage-3/cross-platform/browser-ai-extension.md) · **Полный перевод** · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/index.md)

# Как разработать расширение браузера AI помощник — одна кнопка для суммирования любой веб-страницы

# Глава 1: Что такое расширение браузера и разработка Chrome расширения

В этом учебнике мы пройдём полный цикл: с нуля разработать AI управляемое Chrome расширение браузера, это может прочитать содержание любой веб-страницы, которую вы сейчас смотрите, потом использовать AI помочь вам одну кнопку генерирование резюме. Вы собственноручно завершить разработка расширения, отладка, и научиться опубликовать в Chrome Web Store.

Для этого учебника вам понадобится минимум:

- Chrome браузер (рекомендуется версия 138 и выше, если хотите использовать встроенный AI)
- Редактор кода (VS Code / Cursor / Trae)
- (Опционально) OpenAI или Claude API Key

## 1.1 Что такое расширение браузера?

Вы определённо использовали расширение браузера (Extension) — адблокер, инструмент перевода, менеджер пароля… они как браузера "дополнительное оборудование", может предоставить дополнительные суперспособности при просмотре веб-страницы.

Представьте: вы открываете 5000 словное техническое блога, щелкните кнопка расширения, через несколько секунд, один отшлифованный резюме на китайском появляется в боковой панели. Это то, что мы будем построить.

![Предпросмотр эффекта, левая сторона длинная статья веб-страница, правая сторона Chrome боковая панель показывает AI генерирование резюме](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image1.png)

## 1.2 Базовая архитектура Chrome расширения

Chrome расширение (основано на Manifest V3) состоит из нескольких главных частей, они каждый выполняет свою функцию:

* **Файл Manifest (manifest.json)**: расширение "удостоверение личности", объявить расширение имя, разрешение, входной файл и т.д.
* **Service Worker (фоновый скрипт)**: расширение "мозг", в фоне справиться события, вызвать API. Это не всегда работает, это по требованию запускается.
* **Content Script (скрипт содержание)**: расширение "глаза", внедрить в веб-страница, может прочитать страница DOM содержание.
* **Side Panel (боковая панель)**: расширение "лицо", в браузера справа показывать UI, пользователь здесь видят AI резюме результат.
* **Options Page (параметры страница)**: позволить пользователю конфигурировать API Key и другие параметры.

Их между сотрудничество процесс такой:

``` 
Пользователь щелкните расширение иконка
    → боковая панель открыть
    → пользователь щелкните "суммирование" кнопка
    → боковая панель уведомить Service Worker
    → Service Worker позволить Content Script идёте читать страница текст
    → Content Script возвращаемый страница содержание
    → Service Worker преобразовать содержание отправить AI API
    → AI возвращаемый резюме
    → Service Worker вернуть резюме боковой панель показывать
```
![Архитектура диаграмма процесса, показывает Content Script, Service Worker, Side Panel между сообщение передача отношение](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image2.png)

## 1.3 Два типа AI план: облачный API vs встроенный браузер AI

Наше расширение иметь два способа получить AI способность:

**План A: вызвать облачный AI API (OpenAI / Claude)**

* Преимущество: модель способность мощный, поддержка все устройство
* Недостаток: требует API Key, требует интернет, иметь использование стоимость
* Подходящий: ищут качество резюме, требует справиться сложный содержание

**План B: используйте встроенный Chrome AI (Summarizer API)**

Начиная с Chrome 138, Google встроен в браузер основано на Gemini Nano AI способность, в которой включаю **Summarizer API** — полностью локально работать, не требует API Key, не требует интернет, полностью свободно.

* Преимущество: свободно, приватность безопасный, не требует API Key
* Недостаток: требует Chrome 138+, требует хорошо железо (4ГБ+ видеокарта или 16ГБ+ памяти), модель способность не как облачный
* Подходящий: внимание приватность, не хочу потратить деньги, железо условие позволить

**Этот учебник будут одновременно реализовать два типа план**, вы может в соответствии с вашей ситуация выбирать.

## 1.4 Дорожная карта этого учебника

Мы с нуля построить один по имени **"AI Page Summarizer"** Chrome расширение, в соответствии с следующие шаги завершить:

1. **Построить расширение скелет**: создание Manifest V3 проект структура, загрузить в Chrome
2. **Реализовать главная функция**: Content Script прочитать страница + Service Worker вызвать AI API + боковая панель показать результат
3. **подключить встроенный Chrome AI**: используйте Summarizer API реализовать свободное локальный суммирование
4. **Тестирование с отладка**: овладевать Chrome расширение отладка умение
5. **Опубликовать в Chrome Web Store**: упаковка и отправить审核

# Глава 2: Построить расширение скелет

## 2.1 Создание структура проекта

Откройте ваш AI помощник по программированию, новый создание пусто папка `ai-page-summarizer`, потом в диалоговое окно введите:

```
Пожалуйста помогите мне создание Chrome расширение браузера проект, используйте Manifest V3.
Проект имя ai-page-summarizer, функция это используйте AI суммирование веб-страница содержание.
Пожалуйста создание следующие файл структура:

ai-page-summarizer/
├── manifest.json          # MV3 манифест файл
├── background.js          # Service Worker фоновый скрипт
├── content.js             # Содержание скрипт (прочитать страница текст)
├── sidepanel.html         # Боковая панель HTML
├── sidepanel.js           # Боковая панель логика
├── sidepanel.css          # Боковая панель стиль
├── options.html           # Параметры страница
├── options.js             # Параметры страница логика
└── icons/                 # Иконка файл папка

manifest.json требует:
1. manifest_version: 3
2. разрешение: storage, activeTab, scripting, sidePanel
3. фоновый используйте service_worker: "background.js"
4. конфигурировать side_panel, стандартное путь sidepanel.html
5. action конфигурировать стандартное иконка и заголовок
```

AI поможет вам генерирование завершение расширение скелет проект. Давайте посмотрим каждый файл функция.

## 2.2 manifest.json — расширение "удостоверение личности"

Это самый важный файл Chrome расширение, это скажет браузеру это расширение что, требует что разрешение, имеет какие компоненты:

```json
{
  "manifest_version": 3,
  "name": "AI Page Summarizer",
  "version": "1.0",
  "description": "一键总结任意网页内容",
  "permissions": ["storage", "activeTab", "scripting", "sidePanel"],
  "background": {
    "service_worker": "background.js"
  },
  "action": {
    "default_title": "AI Page Summarizer",
    "default_icon": {
      "16": "icons/icon-16.png",
      "48": "icons/icon-48.png",
      "128": "icons/icon-128.png"
    }
  },
  "side_panel": {
    "default_path": "sidepanel.html"
  },
  "options_page": "options.html",
  "icons": {
    "16": "icons/icon-16.png",
    "48": "icons/icon-48.png",
    "128": "icons/icon-128.png"
  }
}
```

**Разрешение объяснение:**

* `storage`: позволить расширение сохраняет данные (например пользователь API Key)
* `activeTab`: позволить расширение получает доступ пользователь сейчас смотрит вкладка (только когда пользователь щелкните расширение имеет эффект, очень безопасный)
* `scripting`: позволить расширение внедрить скрипт в страница прочитать содержание
* `sidePanel`: позволить использовать Chrome боковая панель API

![manifest.json файл редакторе скриншот](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image2b.png)

## 2.3 подготовить иконка

Chrome расширение требует три размер иконка: 16x16, 48x48, 128x128. Вы может позволить AI помочь вам генерирование:

```
Пожалуйста помогите мне генерирование три простой Chrome расширение иконка (16x16, 48x48, 128x128),
дизайн стиль: круглый угол прямоугольник, градиент фиолетовой фон, середина белое AI молния символ.
Сохраняйте в icons/ каталог, соответственно имя icon-16.png, icon-48.png, icon-128.png.
```

## 2.4 загрузить расширение в Chrome

Перед начало кодирование, мы сначала "пусто оболочка" расширение загрузить в Chrome, это样 потом каждый раз изменение может реальном времени видеть эффект:

1. Открыть Chrome, адресная строка введите `chrome://extensions/`
2. Открыть правая вверху **"разработчик режим"** переключение
3. Щелкните **"загрузить раскупить расширение"**
4. Выбирать ваш `ai-page-summarizer` папка

Вы будете видеть расширение появляется в списке, правая вверху инструмент полоса также будет больше один иконка.

![Chrome расширение управление страница скриншот, показывает как открыть разработчик режим и загрузить расширение](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image3.png)

> **Подсказка**: каждый раз модифицировать код после, вернуться к `chrome://extensions/` страница, щелкните расширение карточка на **обновить кнопка (🔄)** может быть обновить.

# Глава 3: реализовать главная функция — прочитать страница + AI суммирование

## 3.1 Content Script: прочитать страница текст

Content Script это внедренный в веб-страница скрипт, это может прямо получает доступ страница DOM. Мы используйте это извлечение страница текст содержание.

Позволить AI помочь вам кодирование `content.js`:

```
Пожалуйста помогите мне кодирование content.js, функция это:
1. Слушать из Service Worker отправить сообщение
2. Когда получить "getPageContent" сообщение, извлечение текущий страница текст содержание
3. Извлечение логика: получить document.body.innerText, одновременно получить страница заголовок и URL
4. Извлечение содержание через sendResponse возвращаемый
```

AI будут генерирование похожее этот код:

```javascript
// content.js
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'getPageContent') {
    const content = document.body.innerText || document.body.textContent
    sendResponse({
      content: content.trim(),
      title: document.title,
      url: window.location.href
    })
  }
  return true // 保持消息通道开放
})
```

## 3.2 Service Worker: вызвать AI API

Service Worker это расширение "мозг", отвечать за协调 каждый компонент между общение, и вызвать внешний AI API.

Позволить AI помочь вам кодирование `background.js`:

```
Пожалуйста помогите мне кодирование background.js, функция это:
1. Когда пользователь щелкните расширение иконка, открыть боковая панель
2. Слушать из боковой панель "summarize" сообщение
3. Получить сообщение после, в текущий вкладка content script отправить "getPageContent" сообщение получить страница содержание
4. Пустить страница содержание после, из chrome.storage.local читать пользователь конфигурировать API Key и модель выбор
5. В соответствии конфигурировать вызвать соответствующий AI API (поддержка OpenAI и Claude)
6. Будет AI возвращаемый резюме отправить возвращать боковой панель

OpenAI, вызовите https://api.openai.com/v1/chat/completions, модель используйте gpt-4o-mini
Claude, вызовите https://api.anthropic.com/v1/messages, модель используйте claude-sonnet-4-20250514
Системное приказ: пожалуйста используйте китайский суммирование следующие веб-страница содержание, извлечение ядро пункты, управлять в 300 слово или менее.
```

Основной фрагмент кода похож на это:

```javascript
// background.js

// Щелкните иконка время открыть боковая панель
chrome.sidePanel.setPanelBehavior({ openPanelOnActionClick: true })

// Слушать из боковой панель сообщение
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'summarize') {
    handleSummarize(request.tabId).then(sendResponse)
    return true // 异步响应
  }
})

async function handleSummarize(tabId) {
  // 1. Получить страница содержание
  const [response] = await chrome.tabs.sendMessage(tabId, {
    action: 'getPageContent'
  })

  // 2. Читать пользователь конфигурировать
  const { apiKey, provider } = await chrome.storage.local.get([
    'apiKey', 'provider'
  ])

  if (!apiKey) {
    return { error: 'пожалуйста сначала в параметры страница конфигурировать API Key' }
  }

  // 3. Вызовите AI API
  const summary = provider === 'claude'
    ? await callClaude(response.content, apiKey)
    : await callOpenAI(response.content, apiKey)

  return { summary, title: response.title }
}
```

![background.js код редакторе скриншот](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image4.png)

## 3.3 боковая панель UI: показать резюме результат

Боковая панель это пользователь с расширение взаимодействие главная интерфейс. Позволить AI помочь вам кодирование боковой панели три файл:

```
Пожалуйста помогите мне кодирование боковой панели три файл:

sidepanel.html:
- Вверху показывать расширение имя "AI Page Summarizer"
- Один синий "суммирование текущий страница" кнопка
- Один загрузить анимация область (стандартно скрыто)
- Один результат показать область, показывать страница заголовок и AI резюме
- Низ имеется один "копировать резюме" кнопка

sidepanel.css:
- Простой современный дизайн стиль, похожий Notion выкладка
- Широкий стиль адаптировать боковая панель
- Кнопка имеет hover эффект
- Загрузить анимация используйте CSS реализовать

sidepanel.js:
- Щелкните "суммирование" кнопка, получить текущий вкладка ID
- В background.js отправить summarize сообщение
- Показать загрузить анимация
- Получить результат после скрыть загрузить анимация, показать резюме
- "копировать" кнопка используйте navigator.clipboard.writeText копировать текст
```
![боковая панель UI эффект скриншот, показывать суммирование кнопка, загрузить состояние и резюме результат три состояние](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image5.png)

## 3.4 параметры страница: конфигурировать API Key

пользователь требует один место для ввод свой API Key. Позволить AI помочь вам кодирование параметры страница:

```
Пожалуйста помогите мне кодирование options.html и options.js:
- Один выпадение выбор коробка, выбирать AI поставка (OpenAI / Claude)
- Один пароль ввод коробка, ввод API Key (type="password")
- Один "сохраняет" кнопка
- Сохраняет время используйте chrome.storage.local.set хранить конфигурировать
- Страница загрузить когда из storage читать уже сохраняет конфигурировать и обратное заполнение
- Сохраняет успех после показать "конфигурировать уже сохраняет" подсказка
```

> **Безопасность напоминание**: API Key хранить в `chrome.storage.local` в, только в локальной устройство сохраняет. Но если ты хочу опубликовать в Chrome Web Store供他人使用, безопаснее做法 это построить один фоновый прокси сервер, избежать API Key прямой выпускается в клиент.

![параметры страница скриншот, показывать AI поставка выбор и API Key ввод коробка](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image6-1.png)
![параметры страница скриншот 2](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image6-2.png)
![параметры страница скриншот 3](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image6-3.png)

# Глава 4: используйте встроенный Chrome AI (не требует API Key)

Начиная с Chrome 138, Google встроен в браузер основано на **Gemini Nano** AI способность, в которой наиболее подходящий наше场景是 **Summarizer API** — полностью локально работать, не требует API Key, не требует интернет, полностью свободно.

## 4.1 проверить браузер если поддержать

встроенный AI иметь железо требует:

*桌面 Chrome 138+ (Windows 10+、macOS 13+、Linux、ChromeOS)
* 22 ГБ доступно хранилище пространство (требует загрузить модель)
* GPU видеокарта 4ГБ или выше память, или CPU памяти 16ГБ или выше и 4 ядро или выше

В Chrome адресная строка введите `chrome://flags`, поиск относительно Summarization флаг, гарантировать это это **Enabled** состояние.
* В Chrome 131–137 версия, это переключение это Summarization API.
* В Chrome 138–144 версия, это переключение переименовать Summarization API for Gemini Nano.
* В Chrome 145+ версия, Summarization API for Gemini Nano уже удаляется, его суммирование функция уже整合 在 Prompt API for Gemini Nano

![chrome://flags страница скриншот, показывает Summarization API переключение место](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image7.png)

## 4.2 используйте Summarizer API

Позволить AI помочь вам в `background.js` добавить встроенный AI поддержка:

```
Пожалуйста помогите мне в background.js добавить Chrome встроенный Summarizer API поддержка:
1. Добавить один summarizeWithBuiltinAI функция
2. Сначала проверить Summarizer.availability() если возвращает 'readily-available'
3. Если можно, создание summarizer экземпляр, конфигурировать type это 'key-points', format это 'markdown', length это 'medium'
4. Вызовите summarizer.summarize() справиться суммирование
5. В handleSummarize функция, добавить один provider === 'builtin' ветка
```

Основной код:

```javascript
async function summarizeWithBuiltinAI(text) {
  // 检查是否可用
  const availability = await Summarizer.availability()
  if (availability !== 'readily-available') {
    throw new Error('Chrome встроенный AI недоступный, пожалуйста проверить браузер версия и железо требует')
  }

  // Создание суммировщик
  const summarizer = await Summarizer.create({
    type: 'key-points',
    format: 'markdown',
    length: 'medium'
  })

  // Выполняет суммирование
  const summary = await summarizer.summarize(text, {
    context: 'это веб-страница статья'
  })

  return summary
}
```

## 4.3 обновить параметры страница

В `options.html` AI поставка выпадение выбор коробка, добавить один **"Chrome встроенный AI (свободно)"** опция. Когда пользователь выбирать это опция, скрыть API Key ввод коробка (потому что не требует).

```
Пожалуйста помогите мне изменить options.html и options.js:
1. В AI поставка выпадение выбор коробка добавить опция "Chrome встроенный AI (свободно, не требует API Key)", value это "builtin"
2. Когда выбирать builtin, скрыть API Key ввод коробка
3. Когда выбирать OpenAI или Claude, показать API Key ввод коробка
```

![обновить параметры страница скриншот, показывать три AI поставка опция, выбирать Chrome встроенный AI когда API Key ввод коробка скрыто](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image8.png)

# Глава 5: тестирование с отладка

## 5.1 локальный тестирование процесс

Разработка Chrome расширение отладка способ и обычный веб-страница немного отличается:

**отладка Service Worker:**
1. Открыть `chrome://extensions/`
2. Найти ваше расширение, щелкните **"Service Worker"** ссылка
3. будет открыть специальное DevTools окно, может видеть console.log вывод и сетевой запрос

**отладка боковая панель:**
1. Открыть боковая панель после, прав щелкните боковой панель содержание
2. Выбирать **"проверить"** (Inspect)
3. будет открыть боковой панель DevTools

**отладка Content Script:**
1. На любой веб-страница щелкните F12 открыть DevTools
2. В Console панель, щелкните слева вверху выпадение коробка, выбирать ваше расширение имя
3. можешь видеть Content Script console вывод

![Chrome DevTools отладка расширение скриншот, показывает как выбирать разных выполнение контекст отладка разных компонент](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image9.png)

## 5.2 общий проблема поиск

| Проблема | Возможное причина | Решение |
|------|---------|---------|
| Щелкните иконка без ответ | Service Worker ошибка | Проверить Service Worker DevTools Console |
| Получить не到页面内容 | Content Script не внедрён | Обновить страница потом повторить, проверить manifest в matches конфигурировать |
| API вызовите ошибка | API Key ошибка или过期 | В параметры страница переввести API Key |
| боковая панель пусто | sidepanel.html путь ошибка | Проверить manifest в side_panel.default_path |

# Глава 6: опубликовать в Chrome Web Store (опционально)

Если ты хочу расширение поделиться даешь другой пользователь использовать, может опубликовать в Chrome Web Store.

## 6.1 опубликовать подготовка

1. **регистрировать разработчик аккаунт**: посетите [Chrome Web Store Developer Dashboard](https://chrome.google.com/webstore/devconsole), заплатить один раз $5 доллар регистрировать налог
2. **открыть двухэтапное проверка**: Google аккаунт обязанно открыть двухэтапное проверка才能 опубликовать расширение
3. **подготовить материал**:
   * расширение иконка: 128x128 PNG
   * минимум один скриншот: рекомендуется 1280x800 пиксель
   * детальное функция описание
   * приватность политика объяснение (если ваше расширение справиться пользователь данные)

## 6.2 упаковка с загрузить

1. упаковать расширение папка в `.zip` файл (不是 `.crx`)
2. В Developer Dashboard щелкните **"New Item"**
3. загрузить `.zip` файл
4. заполнить магазин информация (имя, описание, скриншот, категория и т.д.)
5. заполнить приватность практика (объявить ваше расширение收集 какие данные)
6. щелкните **"Submit for Review"**

Google будет на отправить расширение審核, 通常需要几个工作日. Разрешение меньше, описание яснее,審核更快通过.

![Chrome Web Store Developer Dashboard скриншот, показывает расширение загрузить и информация заполнить интерфейс](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image10.png)
![Chrome Web Store Developer Dashboard скриншот 2](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image10-1.png)

# Глава 7: заключение

Поздравляем! Вы уже с нуля построить один AI управляемое расширение браузера. Давайте вспомним, что мы сделали:

1. Понимание Chrome расширение Manifest V3 архитектура
2. Используйте Content Script прочитать веб-страница содержание
3. Используйте Service Worker вызвать AI API генерирование резюме
4. Используйте Side Panel показать суммирование результат
5. Также научиться используйте встроенный Chrome AI (не требует API Key)

расширение браузера это один очень интересный разработка область — это позволяет вам "улучшать" интернет на любой веб-страница. Кроме суммирование страница, ты также может используйте похожий архитектура сделать много вещи:

**Направления развития:**

* **перевод помощник**: один кнопка переводить иностранный веб-страница в китайский
* **чтение аннотация**: в веб-страница на подсветить и аннотация, сохраняет в облако
* **цена отслеживание**: мониторить электронная коммерция веб-страница цена изменение и提醒
* **код интерпретировать**: в GitHub выбирать код, AI автоматическое объяснить

встроенный Chrome AI появление 更是降低了门槛 — ты даже не требует API Key может построить AI управляемое расширение. 随着浏览器 AI 能力的不断增强, это область想象空间 будет越来越大.

***去给你的浏览器装上超能力吧！***

# справочные материалы

* [Chrome Extension官方文档 - Manifest V3](https://developer.chrome.com/docs/extensions/develop/)
* [Chrome Extension在Chrome应用商店中发布](https://developer.chrome.com/docs/webstore/publish?hl=zh-cn)
* [Chrome Side Panel API](https://developer.chrome.com/docs/extensions/reference/api/sidePanel)
* [Chrome встроенный AI - Summarizer API](https://developer.chrome.com/docs/ai/summarizer-api)
* [Chrome встроенный AI - Prompt API](https://developer.chrome.com/docs/ai/prompt-api)
* [OpenAI API документирование](https://platform.openai.com/docs/api-reference)
* [Anthropic Claude API документирование](https://docs.anthropic.com/en/docs/)
* [Anthropic Claude API документирование](https://developer.chrome.com/docs/webstore/publish?hl=zh-cn)
