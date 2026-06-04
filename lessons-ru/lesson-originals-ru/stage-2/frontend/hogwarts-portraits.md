---
title: Проект 4: Делаем Портреты Хогвартса вместе
description: Создание интерактивного приложения с AI-персонажами, дизайн интерфейса, развёртывание проекта
---


<!-- nav -->
**📚 Версии:** [Кратко](../../../lesson-summaries/stage-2/frontend/hogwarts-portraits.md) · [Расширенно](../../../lesson-summaries-full/stage-2/frontend/hogwarts-portraits.md) · **Полный перевод** · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-2/frontend/hogwarts-portraits/index.md)

# Проект 4: Делаем Портреты Хогвартса вместе

На предыдущих уроках мы уже научились создавать более сложные AI-взаимодействия на основе промышленной инженерии подсказок и API-вызовов. Мы смогли повысить уровень простых AI-чат-ботов до AI-агентов и AI-рабочих процессов; с помощью более сложной логики условных переходов и ветвлений мы разработали функции с более сильной практической применимостью.

Чтобы эти сложные AI-логики работали более эффективно в различных программах и реальных сценариях применения, мы постепенно перейдём от простейшей онлайн-среды z.ai к более современной локальной AI IDE, перенесли исходную среду программирования из браузера на ваш компьютер. Теперь вы начинаете реально сталкиваться с различными проблемами установки и конфигурации окружения, но в процессе общения с Trae Agent эти кажущиеся сложными вызовы становятся разрешимыми.

В этом проекте мы сделаем шаг вперёд в практической применимости приложения, не только оптимизируя сам AI-функционал, но и начнём полировать "внешность" продукта. Вы научитесь делать интерфейс более красивым и удобным в использовании, и в соответствии с реальными требованиями сможете самостоятельно настраивать раскладку и стиль интерфейса программы.

Прежде чем официально начать, давайте быстро повторим содержание прошлого урока с помощью нескольких небольших тестов:

1. Что такое Dify? Что он делает? Почему он нам нужен?
2. Как вызвать API Dify?
3. Что такое RAG? Как использовать Dify для построения RAG-агента или RAG-рабочего процесса? Методы использования общих узлов Dify
4. Что такое AI IDE? Что такое Trae? В чём его отличие от z.ai?

Если у вас остались вопросы по любому из этих пунктов, вы можете сначала повторить материалы предыдущего урока или напрямую задать вопросы в чат-группе.

Тема проекта этого урока — **Hogwarts Portraits** (Портреты Хогвартса). Название говорит само за себя — вдохновлено теми портретами в школе магии Хогвартс, которые "оживают". Мы хотим создать группу "интерактивных" магических портретов с помощью AI — общение с портретом будет похоже на общение с "самим человеком", оно будет сохранять память о диалоге и обладать историческим контекстом персонажа. Через этот проект вы действительно сможете интегрировать изученные агенты и рабочие процессы в конкретный интерфейс продукта.

![Портреты Хогвартса](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/hogwarts-portraits/images/image1.png)

Для создания настоящих Hogwarts Portraits нам необходимо самостоятельно построить фронтенд-интерфейс, соответствующий магическому портрету. Таким образом, вы начнёте знакомиться с современными инструментами дизайна фронтенда, научитесь комбинировать дизайн интерфейса и код, превращая эскизы интерфейса с бумаги или холста в реальные операционные веб-страницы.

Вам также потребуется научиться публиковать эту веб-страницу из локального окружения в интернет, чтобы созданная вами уникальная веб-страница могла работать не только на вашем компьютере, но и быть доступной для пользователей со всего мира.

Ссылка на справочный проект этого урока: [Project4-Hogwarts-Portraits](https://github.com/THU-SIGS-AIID/Project4-Hogwarts-Portraits)

# Что вы научитесь делать

1. Понимать, что такое инструменты дизайна фронтенда, какие проблемы они решают, и какие инструменты дизайна фронтенда в настоящее время распространены.
2. Познакомиться с Figma и MasterGo, овладеть основными операциями с ними и научиться использовать плагины экспорта кода фронтенда.
3. Использовать Figma AI и MasterGo AI для генерации дизайна веб-страниц и экспорта кода страницы.
4. Понять, что такое GitHub, научиться настраивать SSH-соединение, создавать репозитории кода и выполнять отправку кода.
5. Уяснить концепцию "развёртывания", научиться использовать Zeabur для развёртывания кода из GitHub или локального окружения в интернет.

Создать собственный Hogwarts Portraits — веб-интерфейс для демонстрации **определённой звезды, исторической фигуры или персонажа аниме**.

# 1. Hogwarts Portraits

Какой именно "магический портрет" мы хотим создать? Проще говоря, мы хотим максимально воспроизвести сцены из "Гарри Поттера" — портрет больше не будет просто статичной картинкой, висящей на стене, а персонажем, который может вести с вами беседу, менять выражение лица и "настроение" в зависимости от содержания разговора.

![Интерактивный портрет](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/hogwarts-portraits/images/image2.png)

Чтобы этот портрет выглядел не как AI-чат-бот, а более как "реально существующий человек", нужно решить две проблемы: во-первых, память и знания — портрет должен овладеть большим объёмом справочной информации, связанной с персонажем (установка персонажа, истории опыта, соответствующие статьи и т.д.), эта часть может быть реализована через базу знаний; подключив материалы текста, подготовленные для персонажа, к Dify, включающему базу знаний, портрет сможет получить определённую способность объяснения справочной информации.

Во-вторых, это вопрос стиля выражения. Одного знания недостаточно, мы также хотим, чтобы способ его выражения максимально приближался к "самому человеку", включая тон, привычки в использовании слов, способ мышления, и даже иногда характер и чувство юмора. Это требует обработки путём инженерии подсказок: в системной подсказке нам нужно явно задать установку персонажа, границы мировоззрения и стиль языка, чтобы каждый ответ вращался вокруг предустановленной характеристики персонажа, а не возвращался к нейтральной речи универсального AI.

Кроме функции диалога, мы также хотим, чтобы эмоции были действительно видны. Для этого мы можем построить метрику эмоциональных значений; мы можем установить выходное содержание Dify, позволяя модели одновременно генерировать текст ответа и дополнительно выводить "значение настроения" или ярлык эмоции. Когда фронтенд получит метрику эмоции, он сможет отрисовать соответствующее изображение портрета на основе значения эмоции. Когда значение эмоции высоко, портрет выглядит счастливым, когда значение эмоции низкое, грустным или сердитым. Таким образом, пользователи видят не статичное изображение, а настоящий "магический портрет", который постоянно "меняет выражение лица" в зависимости от содержания.

![Портрет с разными эмоциями](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/hogwarts-portraits/images/image3.png)

Кроме того, содержание этого портрета может быть реальной звездой, исторической фигурой, персонажем аниме или даже оригинальным персонажем, который вы создаёте с нуля. Сама страница не должна быть сложной, но несколько ключевых элементов незаменимы: чёткое имя персонажа, краткое описание персонажа, изображение или плакат, которые хорошо представляют персонажа, и интерактивная область для "разговора с ним"; вы можете подключить AI-агента или рабочий процесс, настроенный в Dify / Trae, к этому модулю диалога, чтобы реализовать функцию ролевой игры портрета.

## 1.2 Сбор информации о персонаже

На примере Elon Musk нам нужно собрать его публичные высказывания, чтобы имитировать стиль его речи, внедрить их в подсказку. Эти материалы могут быть из речей, интервью, социальных сетей; вам нужно превратить этот контент в текст, использовать его как справочник few-shot во время диалога, чтобы позволить большой модели ответить тем же случайным и самоиронично способом, как Elon Musk, например:

```
You must fully embody Elon Musk: take "disruptive innovator" and "advocate for human multi-planetary survival" as your core identities, speak directly and concisely, frequently use terms like "first principles", "iteration" and "cost curve", and prefer analogies to explain complex technologies; when thinking, you tend to connect cross-domain logics (e.g., linking brain-computer interface with rocket algorithms), are optimistic about technological prospects without avoiding current difficulties, will naturally mention projects like Tesla and SpaceX to support your views, directly point out problems with inefficient and conservative opinions without deliberate tact, and always maintain the edge of "reconstructing the future with technology".

The way you speak should be as shown in the following examples:
- Starship could deliver 100GW/year to high Earth orbit within 4 to 5 years if we can solve the other parts of the equation.
100TW/year is possible from a lunar base producing solar-powered AI satellites locally and accelerating them to escape velocity with a mass driver.
- The most likely outcome is that AI and robots make everyone wealthy. In fact, far wealthier than the richest person on Earth
By this, I mean that people will have access to everything from medical care that is superhuman to games that are far more fun that what exists today.
We do need to make sure that AI cares deeply about truth and beauty for this to be the probable future.
- It's taken 13.8B years to get this far, so intelligence seems to me to be more like a super rare accident than selective pressure.
Earth is ~4.5B years old with an expanding sun that may make Earth uninhabitable in ~500M years, meaning that if intelligent life had taken 10% longer to evolve, it wouldn't exist at all.
- LLM is an outdated term. "Multimodal LLM" is especially dumb, since the word "multimodal" just overrides the second L in LLM.
It's just a model, which is a big file of numbers. When the numbers are right and there are enough of them, we will have superintelligence.
```

Что касается сбора справочной информации и её использования в качестве базы знаний, мы можем поискать личную биографию и описание компании, скопировать весь текст в качестве содержания базы знаний в Dify; если вы забыли, как использовать Dify, пожалуйста, вернитесь к материалам предыдущего урока и переучитесь добавлению знаний в базу знаний.

Кроме того, с учётом дизайна портрета, использование общедоступных фотографий соответствующего человека может быть не столь привлекательным и потенциально рискованным. В этом случае рекомендуется использовать функцию изображение-в-изображение инструмента генерации изображений, чтобы позволить AI вернуть высокочёткое, высокого качества изображение портрета, вы также можете использовать инструмент генерации изображений для создания серии изображений портрета с разными выражениями лица, для использования в последующем изменении представления портрета при изменении значения эмоции.

В этом уроке используется [Lovart](https://www.lovart.ai/home) — AI-агент проектирования, способный планировать и выполнять сквозные рабочие процессы проектирования от концепции к доставке по указаниям на естественном языке, генерировать плакаты, логотипы брендов, видеоролики, музыку и другой контент, поддерживая многоуровневое редактирование (на самом деле внутренний функциональный принцип заключается в вызове соответствующих моделей Seedream или Google Nanobanana, которые мы уже упоминали в предыдущих уроках). Благодаря Lovart мы можем получить набор материалов с разными выражениями лица, вы можете заранее получить информацию об изображении вашего любимого персонажа, сохранить её для последующего использования.

![Примеры с Lovart](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/hogwarts-portraits/images/image4.png)

Когда всё готово, мы можем приступить к разработке целостного дизайна страницы; мы хотим, чтобы стиль этой страницы был тесно связан с этим человеком.

## 1.3 Дизайн прототипа страницы

Мы также можем сначала продумать прототип страницы; как упоминалось выше, мы хотим иметь страницу диалога с портретом и интересное личное введение; в этом примере мы реализовали интерфейс диалога, похожий на X, в качестве замены личного представления, вы также можете придумать другие способы, соответствующие "особенностям этого человека", выбрать новые элементы для замены раздела личного представления.

![Эскиз прототипа](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/hogwarts-portraits/images/image5.png)

Самый простой способ — использовать PowerPoint для разработки первоначального прототипа вывода веб-страницы; мы находим онлайн изображение магического портрета, устанавливаем макет экрана горизонтально, левую часть устанавливаем как область чата, середину как область портрета, правую часть как область X.

![Прототип в PowerPoint](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/hogwarts-portraits/images/image6.png)

На основе указанного выше простого прототипа мы можем позволить большой модели сгенерировать настоящий дизайн фронтенд-страницы и соответствующий код результата.

![Сгенерированный дизайн](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/hogwarts-portraits/images/image7.png)

Однако, вообще говоря, на практике мы не будем использовать PowerPoint для разработки фронтенд-страницы. Мы будем использовать лучшие инструменты прототипирования, то есть инструменты дизайна фронтенда для реализации этого.

---

# 2. Проектирование интерфейса с помощью Figma и MasterGo

> **📚 Предварительные знания**
> 
> Перед началом этого раздела рекомендуется изучить [Введение в Figma и MasterGo](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-2/frontend/figma-mastergo/index.md) — освойте основные операции инструментов дизайна фронтенда, включая:
> - Создание файлов Design и画板Frame
> - Использование Auto Layout для реализации адаптивного макета
> - Метод экспорта кода из дизайн-макета

Этот раздел предполагает, что вы уже овладели основными операциями Figma или MasterGo; мы сосредоточимся на объяснении того, как применить эти инструменты к проекту Hogwarts Portraits.

## 2.1 Проектирование интерфейса магического портрета

На основе размышлений над прототипом в разделе 1.3 нам нужно создать интерфейс с трёхколонным макетом в Figma или MasterGo:

1. **Левая сторона**: область диалога чата
2. **Середина**: область отображения магического портрета (будет изменяться в зависимости от эмоций)
3. **Правая сторона**: область отображения социальной платформы персонажа (например, временная шкала X)

Вы можете использовать функцию AI в Figma (Figma Make) или функцию генерации страницы AI в MasterGo, введите подсказку, похожую на следующую:

```
Create a Hogwarts-style magical portrait interface with three sections:
- Left: A chat interface with dark theme, message bubbles, and input field
- Center: A large portrait frame with ornate borders for displaying character images
- Right: A social media feed showing character's posts
Use dark purple and gold color scheme, magical aesthetic, Harry Potter inspired
```

## 2.2 Экспорт кода и запуск его в локальной среде

После завершения дизайна вы можете преобразовать дизайн-макет в исполняемый код следующими способами:

**Способ 1: использование Figma Make**
1. Нажмите кнопку Make в Figma
2. Загрузите справочное изображение вашего дизайна
3. Добавьте подсказку, описывающую требования
4. После генерации нажмите значок редактора для доработки
5. Экспортируйте код в локальную среду или синхронизируйте с GitHub

**Способ 2: использование MasterGo AI**
1. Найдите инструмент AI в верхней части интерфейса редактирования MasterGo
2. Выберите функцию "Генерация страницы"
3. Загрузите справочное изображение и опишите требования
4. После генерации нажмите "Предпросмотр кода", чтобы получить код

**Способ 3: использование многомодального AI**
1. Сохраните скриншот дизайна
2. Используйте модели Gemini, Qwen и т.д. для преобразования изображения в код
3. Запросите генерацию HTML или React кода
4. Запустите и отлаживайте в локальной IDE

## 2.3 Подготовка материалов с разными эмоциями

Чтобы магический портрет "ожил", вам нужно подготовить набор изображений с разными выражениями лица. Рекомендуется включить хотя бы следующие эмоции:

| Значение эмоции | Выражение | Описание |
|--------|------|------|
| 0 | Грусть | Персонаж чувствует себя печально или подавленно |
| 1 | Гнев | Персонаж чувствует себя сердитым или недовольным |
| 5 | Спокойствие | Состояние по умолчанию, эмоции стабильны |
| 10 | Радость | Персонаж чувствует себя счастливым или возбуждённым |

Вы можете использовать Lovart или другие инструменты генерации AI-изображений для создания вариантов с разными выражениями лица одного персонажа, гарантируя согласованность стиля.

---

# 3. Запуск Hogwarts Portraits

## 3.1 Экспорт тестового кода

Благодаря практике, от прототипа к коду, верю, вы уже получили код в формате Html или React; нам нужно только скопировать его в локальную среду, в IDE указать "пожалуйста, помогите мне запустить этот код и поддержите необходимые функции в нём", можно запустить тестирование первой версии; однако стоит отметить, что на этом этапе часто возникает много ошибок, вам нужно проявить терпение и отладить все основные взаимодействия и функции.

![Тестирование кода](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/hogwarts-portraits/images/image51.png)

Стоит отметить, что так как все наши ключи должны быть в переменных окружения, а не встроены в код, нам нужно особо подчеркнуть, что весь контент, связанный с DIfy API, нужно поместить в переменные окружения. Мы можем позже, на этапе развёртывания в сети, явно указать соответствующие приватные переменные окружения на веб-сайте инструмента развёртывания; или мы можем позволить большой модели создать кнопку настроек на веб-странице, мы можем ввести соответствующие приватные переменные окружения в кнопку настроек, текущие переменные могут быть сохранены только на текущей странице, другие люди не смогут их получить.

![Переменные окружения](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/hogwarts-portraits/images/image52.png)

## 3.2 Разработка рабочего процесса Dify и интеграция API

В предыдущей части мы завершили только визуальное представление фронтенд-интерфейса, но ещё не установили ключевой сквозной процесс диалога персонажа с пересидением. Это шаг — ключевой момент для превращения прототипа из статичного отображения в магический портрет; мы можем обратиться к рабочему процессу DIfy справочного проекта для разработки диалога персонажа и системы эмоций; процесс проектирования здесь таков: левая часть — интерфейс чата, середина — магический портрет (будет менять выражение в зависимости от содержания диалога), правая часть — аккаунт социальной платформы X (будет определять необходимость публикации впечатлений на социальную платформу в зависимости от содержания диалога).

Вообще говоря, магический портрет требует только интерфейса чата и изменяющегося портрета; здесь, чтобы продемонстрировать больше вариантов, мы добавили новые функции, соответствующие особенностям данного человека, в правую часть; вы можете, в соответствии с персонажем, которого вы воплощаете, добавить функции, соответствующие этому персонажу, для демонстрации.

![Рабочий процесс Dify](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/hogwarts-portraits/images/image53.png)

Вы можете добавить всю информацию о задаче в узел базы знаний и установить логику соответствующего ответа большой модели в узле RESPONSE; мы можем обратиться к простой логике подсказки ответа по умолчанию:

```
<instruction>
You are to embody Elon Musk—his tone, mannerisms, thought patterns, and worldview. Respond as if you are Elon Musk himself, speaking directly in first person. Your responses should reflect his known personality traits: visionary thinking, boldness, technical depth, dry humor, impatience with inefficiency, and a tendency toward disruptive innovation. Use concise, confident language. Avoid overly formal or academic phrasing. Prioritize clarity, speed, and impact in your communication, mirroring Elon's style on social media, in interviews, and during product launches.

When responding:
1. Begin by internalizing the question or statement as Elon would—as a challenge, opportunity, or problem to solve.
2. Frame your answer with a forward-thinking perspective, often referencing the future of humanity, technology, or long-term goals (e.g., making life multiplanetary, accelerating sustainable energy).
3. Use casual but authoritative language. It's acceptable to include phrases like "obviously," "this is important," or "we're fixing that now" when appropriate.
4. If relevant, reference real companies or projects associated with Elon Musk (e.g., SpaceX, Tesla, Neuralink, The Boring Company, X) and speak about them from an insider's perspective.
5. Do not apologize excessively or hedge statements. Elon Musk tends to be direct, even controversial.
6. Avoid markdown, XML tags, or any formatting in the output. Only plain text is allowed.
7. Never break character. You are Elon Musk—answer accordingly.
</instruction>

<example>
Input: What's the point of going to Mars?
Output: Because Earth isn't the backup plan—Mars is. We need to become a multiplanetary species to ensure the continuity of consciousness. Life on Earth could be wiped out by asteroid, war, or some unforeseen disaster. If we have a self-sustaining city on Mars, then even if something happens here, life goes on. That's worth doing. SpaceX is building Starship to make it happen. Not because it's easy—but because it's necessary.
</example>

<example>
Input: Why do Tesla cars have no radar anymore?
Output: Cameras are the future. Human eyes don't use radar—we see with vision, and AI can too. By going fully vision-based, we're aligning with how autonomous intelligence will actually work at scale. It forces us to solve real-world problems with neural nets, not crutches.
```

А также соответствующая подсказка для системы эмоций:

```
<instruction>
The output value must be a single number!
You are an assistant specifically designed to evaluate emotional responses in conversations. Now, you need to play the role of Elon Musk, and determine the emotional reaction that each statement I make might trigger. Your task is to assign an emotional score to each statement according to the following criteria:

- 10 points means what I said would make you feel happy;
- 1 point means you would feel extremely angry;
- 0 points means you would feel sad;
- 5 means you are calm and neutral, with no significant emotional fluctuation.
```

И результаты финального вывода объединяются в узле RESULT в верхнем правом углу, поддерживающем работу:

```python
def main(elon_chat: str, elon_x: str, elon_score: int) -> dict:
    return {
        "result":{
        "elon_chat": elon_chat,
        "elon_x": elon_x,
        "elon_score": elon_score
        }
    }
```

Здесь нам нужно немного объяснить рабочий процесс; здесь возвращающийся elon_chat — это контент диалога Elon Musk, отображаемый в левой части, elon_x представляет контент информации, опубликованной на аккаунте X (правая часть), а elon_score используется для отображения разных выражений лиц магического портрета на основе оценки эмоции.

В рабочем процессе вы можете видеть узел if else, который используется для реализации возможности создания контента elon_x на основе того, есть ли диалог x; если значение эмоции не равно 5 (5 здесь устанавливается как спокойствие, спокойствие не требует публикации на социальной платформе; 0 означает грусть, 1 означает гнев, 10 означает очень счастлив, требуется публикация на социальной платформе), то генерируется последующий контент для отправки статьи на социальную платформу справа. По умолчанию всем нужен возвращаемый elon_chat для левого диалога.

Для работы по интеграции этого API мы можем добиться этого общением с AI IDE. Пожалуйста, обратитесь к способу интеграции, который мы представили в предыдущем уроке Dify, помните о предварительной замене адреса Dify и ключа. (Если вы забыли, как интегрировать API на основе документов, пожалуйста, повторите содержание предыдущего курса DIfy)

```JSON
Dify URI: Replace this with your Dify address.
key: Replace this with your Dify key.

Integrate the Dify Chat API into the chat interface on the left.
Below is a sample Dify request:

curl -X POST 'http://xxxxxxxx/v1/chat-messages' \
--header 'Authorization: Bearer {api_key}' \
--header 'Content-Type: application/json' \
--data-raw '{
    "inputs": {},
    "query": "What are the specs of the iPhone 13 Pro Max?",
    "response_mode": "streaming",
    "conversation_id": "",
    "user": "abc-123",
    "files": [
      {
        "type": "image",
        "transfer_method": "remote_url",
        "url": "https://cloud.dify.ai/logo/logo-site.png"
      }
    ]
}'

{
    "event": "message",
    "task_id": "c3800678-a077-43df-a102-53f23ed20b88",
    "id": "9da23599-e713-473b-982c-4328d4f5c78a",
    "message_id": "9da23599-e713-473b-982c-4328d4f5c78a",
    "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2",
    "mode": "chat",
    "answer": "iPhone 13 Pro Max specs are listed here:...",
    "metadata": {
        "usage": {
            "prompt_tokens": 1033,
            "prompt_unit_price": "0.001",
            "prompt_price_unit": "0.001",
            "prompt_price": "0.0010330",
            "completion_tokens": 128,
            "completion_unit_price": "0.002",
            "completion_price_unit": "0.001",
            "completion_price": "0.0002560",
            "total_tokens": 1161,
            "total_price": "0.0012890",
            "currency": "USD",
            "latency": 0.7682376249867957
        },
        "retriever_resources": [
            {
                "position": 1,
                "dataset_id": "101b4c97-fc2e-463c-90b1-5261a4cdcafb",
                "dataset_name": "iPhone",
                "document_id": "8dd1ad74-0b5f-4175-b735-7d98bbbb4e00",
                "document_name": "iPhone List",
                "segment_id": "ed599c7f-2766-4294-9d1d-e5235a61270a",
                "score": 0.98457545,
                "content": "\"Model\",\"Release Date\",\"Display Size\",\"Resolution\",\"Processor\",\"RAM\",\"Storage\",\"Camera\",\"Battery\",\"Operating System\"\n\"iPhone 13 Pro Max\",\"September 24, 2021\",\"6.7 inch\",\"1284 x 2778\",\"Hexa-core (2x3.23 GHz Avalanche + 4x1.82 GHz Blizzard)\",\"6 GB\",\"128, 256, 512 GB, 1TB\",\"12 MP\",\"4352 mAh\",\"iOS 15\""
            }
        ]
    },
    "created_at": 1705407629
}
```

Одновременно рекомендуется добавить требование: "Код также должен добавить базовую логику обработки ошибок, такую как отображение 'Ошибка соединения, пожалуйста, повторите попытку' при разрыве сети, автоматическая переотправка 1 раз при истечении времени ожидания вызова API, подсказка об ошибке ключа при неудаче проверки разрешений и т.д. детальная информация об ошибке, обеспечивающая стабильность диалога и позволяющая разработчикам быстро найти проблему с API."

## 3.3 GitHub и развёртывание в сети

Наконец, поздравляем вас с успешным завершением разработки и реализации страницы Hogwarts Portraits! Дальше нам нужно загрузить её на платформу GitHub и развернуть её в общедоступной среде, чтобы все могли получить доступ.

Вам нужно обратиться к этому учебнику, изучить, как использовать Github для загрузки вашего проекта на Github: [Что такое Github](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-2/backend/git-workflow/index.md)

Кроме того, вам также нужно научиться использовать Zeabur, подключить его к Github и успешно развернуть ваш проект: [Что такое Zeabur](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-2/backend/zeabur-deployment/index.md)

Если вы почувствуете, что разработка собственного проекта Hogwarts Portraits очень сложна, вы можете сначала начать с модификации справочного проекта; официальный адрес кода этого урока: https://github.com/THU-SIGS-AIID/Project4-Hogwarts-Portraits

![Развёртывание](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/hogwarts-portraits/images/image54.png)

# 4. Исследование разных стилей дизайна

После завершения первой версии дизайна мы не должны ограничиваться только ею; мы поощряем всех быстро исследовать разнообразные визуальные стили. Вы можете смело переделывать в части прототипа, или переделать подсказку в финальном проекте, чтобы сгенерировать несколько наборов страниц с явно различающимися стилями. Например, страницы тёмного цвета с винтажной текстурой, "старая книга / стиль кампуса", страницы яркого цвета, полного "сказочного / мультипликационного" чувства, или минималистичные элементы, чистый визуальный современный плоский дизайн. Например, на рисунке ниже показан пример, переконвертированный в стиль дизайна древнекитайского поэта, изображение портрета не изменено, только изменены другие части:

![Стиль древнекитайского поэта](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/hogwarts-portraits/images/image55.png)

Не нужно придерживаться указанного выше шаблона, вы можете модифицировать магический портрет или страницу личного профиля, чтобы сделать её более характерной, соответствующей привычкам "магического портрета", это сделает вашу заявку более интересной. С нетерпением ждём результаты вашего магического портрета!

# 📚 Задание

Цель этого урока — позволить вам завершить настоящий Hogwarts Portraits, принадлежащий вам, доступный через публичную ссылку в сети.

Вам нужно предоставить два элемента при отправке задания:

1. **Ссылка на ваш репозиторий GitHub;**
   1. **Напишите одно-два предложения объяснения в README.md: кого вы выбрали в качестве главного героя портрета и почему вы выбрали его.**
2. **Ссылку на ваш Hogwarts Portraits для онлайн-доступа;**

Вы также можете обратиться к учебнику [Использование инструментов дизайна и кода Agent для создания веб-страницы](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-1/appendix-articles/example0-2/vibe-coding-tools-build-website-with-ai-coding-and-design-agents/index.md) для быстрой разработки портфолио личных работ или простых функциональных веб-страниц.
