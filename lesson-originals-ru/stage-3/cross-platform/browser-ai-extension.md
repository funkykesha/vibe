---
title: Как разработать расширение браузера с AI-помощником — одна кнопка для суммирования любой веб-страницы
description: Полное руководство по разработке Chrome-расширения, которое использует AI для суммирования содержимого веб-страниц
---


<!-- nav -->
**📚 Версии:** [Кратко](../../../lesson-summaries/stage-3/cross-platform/browser-ai-extension.md) · [Расширенно](../../../lesson-summaries-full/stage-3/cross-platform/browser-ai-extension.md) · **Полный перевод** · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/index.md)

# Как разработать расширение браузера с AI-помощником — одна кнопка для суммирования любой веб-страницы

# Глава 1: Что такое расширение браузера и как разрабатывать расширения для Chrome

В этом учебнике мы пройдём полный цикл: с нуля разработаем Chrome-расширение на базе AI, которое умеет читать содержимое любой открытой вами веб-страницы и одним нажатием кнопки генерировать краткое резюме с помощью AI. Вы самостоятельно реализуете расширение, отладите его и научитесь публиковать в Chrome Web Store.

Для прохождения этого учебника вам понадобится как минимум:

- браузер Chrome (рекомендуется версия 138 и выше, если хотите использовать встроенный AI)
- редактор кода (VS Code / Cursor / Trae)
- (опционально) API Key для OpenAI или Claude

## 1.1 Что такое расширение браузера?

Вы наверняка пользовались расширениями браузера (Extension) — блокировщиком рекламы, переводчиком, менеджером паролей... Они похожи на «дополнительное оснащение» для браузера: расширяют его возможности прямо во время просмотра страниц.

Представьте: вы открываете технический блог на 5000 слов, нажимаете кнопку расширения, и через несколько секунд в боковой панели появляется лаконичное резюме на русском языке. Именно это мы и будем строить.

![Предпросмотр результата: слева длинная статья, справа — боковая панель Chrome с AI-резюме](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image1.png)

## 1.2 Базовая архитектура Chrome-расширения

Chrome-расширение (на основе Manifest V3) состоит из нескольких ключевых частей, каждая из которых выполняет свою роль:

* **Файл манифеста (manifest.json)**: «удостоверение личности» расширения — объявляет его название, требуемые разрешения, точки входа и т. д.
* **Service Worker (фоновый скрипт)**: «мозг» расширения — обрабатывает события в фоновом режиме и вызывает API. Работает не постоянно, а запускается по требованию.
* **Content Script (скрипт содержимого)**: «глаза» расширения — внедряется в веб-страницу и может читать DOM-содержимое страницы.
* **Side Panel (боковая панель)**: «лицо» расширения — отображает UI в правой части браузера, где пользователь видит результат суммирования от AI.
* **Options Page (страница настроек)**: позволяет пользователю настроить API Key и другие параметры.

Процесс взаимодействия между этими частями выглядит так:

```
Пользователь нажимает иконку расширения
    → открывается боковая панель
    → пользователь нажимает кнопку «Суммировать»
    → боковая панель отправляет уведомление Service Worker
    → Service Worker просит Content Script прочитать текст страницы
    → Content Script возвращает содержимое страницы
    → Service Worker отправляет содержимое в AI API
    → AI возвращает резюме
    → Service Worker передаёт резюме обратно в боковую панель для отображения
```

![Схема архитектуры: обмен сообщениями между Content Script, Service Worker и Side Panel](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image2.png)

## 1.3 Два подхода к AI: облачный API vs встроенный AI браузера

У нашего расширения есть два способа получить возможности AI:

**Вариант A: облачный AI API (OpenAI / Claude)**

* Плюсы: мощная модель, работает на любом устройстве
* Минусы: нужен API Key, нужен интернет, есть расходы
* Подходит для: качественных резюме и сложного контента

**Вариант B: встроенный AI Chrome (Summarizer API)**

Начиная с Chrome 138, Google встроил в браузер возможности AI на основе **Gemini Nano**, включая **Summarizer API** — полностью локальная работа, без API Key, без интернета, полностью бесплатно.

* Плюсы: бесплатно, приватно, не нужен API Key
* Минусы: требуется Chrome 138+, требуется достаточно мощное железо (видеокарта с 4+ ГБ VRAM или RAM 16+ ГБ), модель уступает облачным
* Подходит для: тех, кто ценит приватность, не хочет тратить деньги и имеет подходящее железо

**В этом учебнике мы реализуем оба варианта** — вы сможете выбрать подходящий.

## 1.4 Маршрутная карта учебника

Мы построим Chrome-расширение под названием **«AI Page Summarizer»** и выполним следующие шаги:

1. **Создание скелета расширения**: структура проекта Manifest V3, загрузка в Chrome
2. **Реализация основных функций**: Content Script читает страницу + Service Worker вызывает AI API + боковая панель отображает результат
3. **Подключение встроенного AI Chrome**: Summarizer API для бесплатного локального суммирования
4. **Тестирование и отладка**: приёмы отладки Chrome-расширений
5. **Публикация в Chrome Web Store**: упаковка и отправка на проверку

# Глава 2: Создание скелета расширения

## 2.1 Создание структуры проекта

Откройте AI-ассистент программирования (Cursor / Trae / Claude Code), создайте пустую папку `ai-page-summarizer` и введите в диалоговое окно:

```
Пожалуйста, создай проект Chrome-расширения браузера, используя Manifest V3.
Проект называется ai-page-summarizer, его функция — суммировать содержимое веб-страниц с помощью AI.
Создай следующую структуру файлов:

ai-page-summarizer/
├── manifest.json          # Файл манифеста MV3
├── background.js          # Service Worker (фоновый скрипт)
├── content.js             # Content Script (читает текст страницы)
├── sidepanel.html         # HTML боковой панели
├── sidepanel.js           # Логика боковой панели
├── sidepanel.css          # Стили боковой панели
├── options.html           # Страница настроек
├── options.js             # Логика страницы настроек
└── icons/                 # Папка с иконками

Требования к manifest.json:
1. manifest_version: 3
2. Разрешения: storage, activeTab, scripting, sidePanel
3. Фоновый скрипт: service_worker: "background.js"
4. Настроить side_panel с путём по умолчанию sidepanel.html
5. В action настроить иконку и заголовок по умолчанию
```

AI сгенерирует полный скелет проекта. Давайте разберём назначение каждого файла.

## 2.2 manifest.json — «удостоверение личности» расширения

Это самый важный файл Chrome-расширения: он сообщает браузеру, что представляет собой расширение, какие разрешения ему нужны и какие компоненты в нём есть:

```json
{
  "manifest_version": 3,
  "name": "AI Page Summarizer",
  "version": "1.0",
  "description": "Суммируй любую веб-страницу одним нажатием с помощью AI",
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

**Пояснение разрешений:**

* `storage` — позволяет расширению сохранять данные (например, API Key пользователя)
* `activeTab` — позволяет расширению обращаться к текущей вкладке пользователя (только при нажатии на иконку расширения, что делает его безопасным)
* `scripting` — позволяет расширению внедрять скрипты в страницу для чтения содержимого
* `sidePanel` — позволяет использовать Chrome Side Panel API

![Файл manifest.json в редакторе кода](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image2b.png)

## 2.3 Подготовка иконок

Chrome-расширению нужны иконки трёх размеров: 16×16, 48×48 и 128×128. Можно попросить AI их сгенерировать:

```
Пожалуйста, создай три простые иконки для Chrome-расширения (16x16, 48x48, 128x128).
Стиль: скруглённый прямоугольник, градиентный фиолетовый фон, белый символ AI-молнии по центру.
Сохрани в папку icons/ с именами icon-16.png, icon-48.png, icon-128.png.
```

## 2.4 Загрузка расширения в Chrome

Прежде чем писать код, загрузим этот «пустой» скелет в Chrome — тогда при каждом изменении результат будет виден сразу:

1. Откройте Chrome и введите в адресной строке `chrome://extensions/`
2. Включите переключатель **«Режим разработчика»** в правом верхнем углу
3. Нажмите **«Загрузить распакованное расширение»**
4. Выберите папку `ai-page-summarizer`

Расширение появится в списке, а на панели инструментов браузера появится его иконка.

![Страница управления расширениями Chrome: включение режима разработчика и загрузка расширения](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image3.png)

> **Совет**: после каждого изменения кода вернитесь на страницу `chrome://extensions/` и нажмите **кнопку обновления (🔄)** на карточке расширения.

# Глава 3: Реализация основных функций — чтение страницы и AI-суммирование

## 3.1 Content Script: чтение текста страницы

Content Script — это скрипт, внедрённый в веб-страницу; он может напрямую обращаться к DOM страницы. Используем его для извлечения текстового содержимого.

Попросите AI написать `content.js`:

```
Пожалуйста, напиши content.js со следующей функциональностью:
1. Слушать сообщения от Service Worker
2. При получении сообщения "getPageContent" извлечь текстовое содержимое текущей страницы
3. Логика извлечения: получить document.body.innerText, а также заголовок страницы и URL
4. Вернуть извлечённое содержимое через sendResponse
```

AI сгенерирует код примерно такого вида:

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
  return true // держать канал сообщений открытым
})
```

## 3.2 Service Worker: вызов AI API

Service Worker — «мозг» расширения; он отвечает за координацию взаимодействия между компонентами и вызов внешних AI API.

Попросите AI написать `background.js`:

```
Пожалуйста, напиши background.js со следующей функциональностью:
1. При нажатии пользователем иконки расширения открывать боковую панель
2. Слушать сообщения "summarize" от боковой панели
3. При получении сообщения отправить в content script текущей вкладки сообщение "getPageContent" для получения содержимого страницы
4. Получив содержимое страницы, прочитать из chrome.storage.local настроенные пользователем API Key и выбор модели
5. В зависимости от настроек вызвать соответствующий AI API (поддерживает OpenAI и Claude)
6. Отправить полученное от AI резюме обратно в боковую панель

Для OpenAI: вызывать https://api.openai.com/v1/chat/completions, модель gpt-4o-mini
Для Claude: вызывать https://api.anthropic.com/v1/messages, модель claude-sonnet-4-20250514
Системный промпт: Суммируй следующее содержимое веб-страницы на русском языке, выдели ключевые моменты, уложись в 300 слов.
```

Ключевой фрагмент кода:

```javascript
// background.js

// открывать боковую панель при нажатии на иконку
chrome.sidePanel.setPanelBehavior({ openPanelOnActionClick: true })

// слушать сообщения от боковой панели
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'summarize') {
    handleSummarize(request.tabId).then(sendResponse)
    return true // асинхронный ответ
  }
})

async function handleSummarize(tabId) {
  // 1. получить содержимое страницы
  const [response] = await chrome.tabs.sendMessage(tabId, {
    action: 'getPageContent'
  })

  // 2. прочитать настройки пользователя
  const { apiKey, provider } = await chrome.storage.local.get([
    'apiKey', 'provider'
  ])

  if (!apiKey) {
    return { error: 'Пожалуйста, настройте API Key на странице настроек' }
  }

  // 3. вызвать AI API
  const summary = provider === 'claude'
    ? await callClaude(response.content, apiKey)
    : await callOpenAI(response.content, apiKey)

  return { summary, title: response.title }
}
```

![Код background.js в редакторе](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image4.png)

## 3.3 UI боковой панели: отображение результатов суммирования

Боковая панель — основной интерфейс взаимодействия пользователя с расширением. Попросите AI написать HTML, CSS и JS боковой панели:

```
Пожалуйста, напиши три файла боковой панели:

sidepanel.html:
- вверху название расширения "AI Page Summarizer"
- синяя кнопка "Суммировать текущую страницу"
- область с анимацией загрузки (по умолчанию скрыта)
- область отображения результатов: заголовок страницы и AI-резюме
- внизу кнопка "Скопировать резюме"

sidepanel.css:
- чистый современный стиль, похожий на типографику Notion
- ширина адаптируется под боковую панель
- hover-эффекты для кнопок
- анимация загрузки реализована на CSS

sidepanel.js:
- при нажатии кнопки "Суммировать" получить ID текущей вкладки
- отправить сообщение summarize в background.js
- показать анимацию загрузки
- после получения результата скрыть анимацию и показать резюме
- кнопка "Скопировать" использует navigator.clipboard.writeText для копирования текста
```

![UI боковой панели: три состояния — кнопка суммирования, загрузка, отображение результата](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image5.png)

## 3.4 Страница настроек: конфигурация API Key

Пользователю нужно место для ввода своего API Key. Попросите AI написать страницу настроек:

```
Пожалуйста, напиши options.html и options.js:
- выпадающий список для выбора AI-провайдера (OpenAI / Claude)
- поле для пароля — ввод API Key (type="password")
- кнопка "Сохранить"
- при сохранении использовать chrome.storage.local.set для хранения настроек
- при загрузке страницы читать сохранённые настройки из storage и заполнять поля
- после успешного сохранения показать уведомление "Настройки сохранены"
```

> **Замечание по безопасности**: API Key хранится в `chrome.storage.local` — только на локальном устройстве. Но если вы планируете публиковать расширение в Chrome Web Store для других пользователей, более безопасный подход — настроить серверный прокси-сервер, чтобы API Key не был доступен на стороне клиента.

![Страница настроек: выбор AI-провайдера и поле ввода API Key (1)](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image6-1.png)
![Страница настроек: выбор AI-провайдера и поле ввода API Key (2)](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image6-2.png)
![Страница настроек: выбор AI-провайдера и поле ввода API Key (3)](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image6-3.png)

# Глава 4: Использование встроенного AI Chrome (без API Key)

Начиная с Chrome 138, Google встроил в браузер возможности AI на основе **Gemini Nano**, и наиболее подходящим для нашего случая является **Summarizer API** — полностью локальная работа, без API Key, без интернета, полностью бесплатно.

## 4.1 Проверка поддержки браузером

Встроенный AI предъявляет аппаратные требования:

* Chrome 138+ для десктопа (Windows 10+, macOS 13+, Linux, ChromeOS)
* 22 ГБ свободного дискового пространства (для загрузки модели)
* Видеокарта с 4+ ГБ VRAM, или CPU RAM 16+ ГБ при наличии 4+ ядер

Введите в адресной строке Chrome `chrome://flags`, найдите флаги, связанные с суммированием, и убедитесь, что они в состоянии **Enabled**.
* В Chrome 131–137: флаг называется Summarization API.
* В Chrome 138–144: флаг переименован в Summarization API for Gemini Nano.
* В Chrome 145+: флаг Summarization API for Gemini Nano удалён, функция суммирования интегрирована в Prompt API for Gemini Nano.

![Страница chrome://flags: расположение переключателя Summarization API](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image7.png)

## 4.2 Использование Summarizer API

Попросите AI добавить поддержку встроенного AI в `background.js`:

```
Пожалуйста, добавь в background.js поддержку встроенного Chrome Summarizer API:
1. Добавь функцию summarizeWithBuiltinAI
2. Сначала проверить, возвращает ли Summarizer.availability() значение 'readily-available'
3. Если доступен — создать экземпляр summarizer с параметрами: type 'key-points', format 'markdown', length 'medium'
4. Вызвать summarizer.summarize() для суммирования
5. В функции handleSummarize добавить ветку для provider === 'builtin'
```

Ключевой код:

```javascript
async function summarizeWithBuiltinAI(text) {
  // проверить доступность
  const availability = await Summarizer.availability()
  if (availability !== 'readily-available') {
    throw new Error('Встроенный AI Chrome недоступен. Проверьте версию браузера и аппаратные требования.')
  }

  // создать суммаризатор
  const summarizer = await Summarizer.create({
    type: 'key-points',
    format: 'markdown',
    length: 'medium'
  })

  // выполнить суммирование
  const summary = await summarizer.summarize(text, {
    context: 'Это статья из интернета'
  })

  return summary
}
```

## 4.3 Обновление страницы настроек

Добавьте в выпадающий список AI-провайдеров на странице `options.html` опцию **«Встроенный AI Chrome (бесплатно)»**. При выборе этой опции поле ввода API Key должно скрываться (оно не нужно).

```
Пожалуйста, измени options.html и options.js:
1. Добавь в выпадающий список AI-провайдеров опцию "Встроенный AI Chrome (бесплатно, без API Key)", value = "builtin"
2. При выборе builtin скрывать поле ввода API Key
3. При выборе OpenAI или Claude показывать поле ввода API Key
```

![Обновлённая страница настроек: три опции AI-провайдера; при выборе встроенного AI поле API Key скрыто](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image8.png)

# Глава 5: Тестирование и отладка

## 5.1 Процесс локального тестирования

Отладка Chrome-расширений немного отличается от отладки обычных веб-страниц:

**Отладка Service Worker:**
1. Откройте `chrome://extensions/`
2. Найдите ваше расширение и нажмите ссылку **«Service Worker»**
3. Откроется отдельное окно DevTools, где будут видны вывод console.log и сетевые запросы

**Отладка боковой панели:**
1. Откройте боковую панель, щёлкните правой кнопкой мыши по её содержимому
2. Выберите **«Inspect»** (Проверить)
3. Откроется DevTools для боковой панели

**Отладка Content Script:**
1. Откройте DevTools на любой веб-странице (F12)
2. На панели Console нажмите выпадающий список в левом верхнем углу и выберите название вашего расширения
3. Теперь будет виден вывод console.log из Content Script

![Отладка расширения в Chrome DevTools: выбор разных контекстов выполнения для отладки разных компонентов](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image9.png)

## 5.2 Диагностика типичных проблем

| Проблема | Возможная причина | Решение |
|------|---------|---------|
| Нажатие на иконку не даёт результата | Ошибка в Service Worker | Проверить консоль DevTools Service Worker |
| Не удаётся получить содержимое страницы | Content Script не внедрён | Обновить страницу и попробовать снова; проверить настройку matches в манифесте |
| Вызов API завершается ошибкой | Неверный или просроченный API Key | Повторно ввести API Key на странице настроек |
| Боковая панель пустая | Неверный путь в sidepanel.html | Проверить side_panel.default_path в манифесте |

# Глава 6: Публикация в Chrome Web Store (по желанию)

Если хотите поделиться расширением с другими пользователями, можно опубликовать его в Chrome Web Store.

## 6.1 Подготовка к публикации

1. **Зарегистрируйте аккаунт разработчика**: перейдите в [Chrome Web Store Developer Dashboard](https://chrome.google.com/webstore/devconsole) и оплатите единоразовый регистрационный взнос $5
2. **Включите двухэтапную проверку**: аккаунт Google должен иметь включённую двухэтапную проверку для публикации расширений
3. **Подготовьте материалы**:
   * Иконка расширения: PNG 128×128
   * Минимум один скриншот: рекомендуется 1280×800 пикселей
   * Подробное описание функций
   * Политика конфиденциальности (если расширение обрабатывает пользовательские данные)

## 6.2 Упаковка и загрузка

1. Упакуйте папку с расширением в файл `.zip` (не `.crx`)
2. В Developer Dashboard нажмите **«New Item»**
3. Загрузите файл `.zip`
4. Заполните информацию для магазина (название, описание, скриншоты, категория и т. д.)
5. Заполните раздел о конфиденциальности (укажите, какие данные собирает ваше расширение)
6. Нажмите **«Submit for Review»**

Google проведёт проверку отправленного расширения — обычно это занимает несколько рабочих дней. Чем меньше запрошенных разрешений и чем чётче описание, тем быстрее пройдёт проверка.

![Chrome Web Store Developer Dashboard: загрузка расширения и заполнение информации (1)](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image10.png)
![Chrome Web Store Developer Dashboard: загрузка расширения и заполнение информации (2)](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/images/image10-1.png)

# Глава 7: Заключение

Поздравляем! Вы создали AI-расширение браузера с нуля. Давайте вспомним, что мы сделали:

1. Разобрались с архитектурой Manifest V3 для Chrome-расширений
2. Реализовали чтение содержимого веб-страниц с помощью Content Script
3. Настроили вызов AI API через Service Worker для генерации резюме
4. Организовали отображение результатов суммирования в боковой панели (Side Panel)
5. Научились использовать встроенный AI Chrome без API Key

Расширения браузера — это очень интересная область разработки: они позволяют «улучшать» любую страницу в интернете. Помимо суммирования страниц, похожую архитектуру можно использовать для самых разных задач:

**Направления для дальнейшего развития:**

* **Помощник переводчика**: перевод иностранных веб-страниц одним нажатием
* **Читательские аннотации**: выделение и комментирование текста на веб-странице, сохранение в облако
* **Отслеживание цен**: мониторинг изменений цен на страницах интернет-магазинов с уведомлениями
* **Объяснятель кода**: выделите код на GitHub — AI автоматически его объяснит

Появление встроенного AI в Chrome ещё больше снизило порог входа — теперь можно создавать AI-расширения даже без API Key. По мере того как возможности AI в браузерах продолжают расти, горизонты этой области будут расширяться всё дальше.

***Пора оснастить свой браузер суперспособностями!***

# Список источников

* [Официальная документация Chrome Extension — Manifest V3](https://developer.chrome.com/docs/extensions/develop/)
* [Публикация расширений в Chrome Web Store](https://developer.chrome.com/docs/webstore/publish?hl=zh-cn)
* [Chrome Side Panel API](https://developer.chrome.com/docs/extensions/reference/api/sidePanel)
* [Встроенный AI Chrome — Summarizer API](https://developer.chrome.com/docs/ai/summarizer-api)
* [Встроенный AI Chrome — Prompt API](https://developer.chrome.com/docs/ai/prompt-api)
* [Документация OpenAI API](https://platform.openai.com/docs/api-reference)
* [Документация Anthropic Claude API](https://docs.anthropic.com/en/docs/)
