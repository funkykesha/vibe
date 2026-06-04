# Начни с NanoBanana: создай собственного агента по производству активов

<!-- nav -->
**📚 Версии:** [Кратко](../../../lesson-summaries/stage-2/frontend/lovart-assets.md) · [Расширенно](../../../lesson-summaries-full/stage-2/frontend/lovart-assets.md) · **Полный перевод** · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-2/frontend/lovart-assets/index.md)


## Глава 1: Сгенерируй первый материал за 1 минуту

Прежде чем говорить о дизайне, стиле или промптах, давай сначала сгенерируем первое изображение с минимальными шагами.

### 1.1 Знакомство с NanoBanana

Перед обсуждением стиля дизайна и инженерии промптов, давай решим более важное: **убедитесь, что вы действительно можете сгенерировать изображение.**

Нынешние основные большие модели уже имеют возможности генерации и редактирования изображений, такие модели обычно называются **генеративными моделями.**

Чтобы максимально упростить процесс, этот учебник выбрал модель с установленными стабильными возможностями генерации и редактирования изображений в качестве примера — NanoBanana. Это модель генерирования изображений от Google, официально названная **Gemini 3.1 Flash Image Preview**, поддерживает как прямую генерацию изображений из естественного языка, так и редактирование на основе существующих изображений.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image1.png)

На уровне возможностей она не отличается принципиально от других моделей, которых ты мог слышать (таких как GPT-4o, Claude, Qwen, Midjourney и т.д.): **введите описание, модель отвечает за генерирование результата.**

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image2.png)![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image3.png)![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image4.png)

Можешь думать о этом как о "кисти". На этой главе мы сосредоточены на одном:
👉 **Может ли эта кисть нарисовать первый штрих в твоих руках.**

На практике NanoBanana может быть использован через официальные платформы, такие как **Google AI Studio**, или интегрирован в процесс разработки через **API**. Этот учебник использует API вызовы. Недавно вышла модель NanoBanana 2, ты можешь использовать новейшую большую модель для попыток.

### 1.2 Генерирование "Hello World" уровня

Прежде чем начать, тебе нужно выполнить три следующих шага:

1. Создай новую папку в Trae

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image5.png)

2. Создай новый файл Python

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image6.png)

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image7.png)

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image8.png)

3. Полностью скопируй следующий код

Trae автоматически завершит необходимое развёртывание окружения и установку зависимостей, никакой дополнительной настройки не требуется.

Код будет использовать API Key от NanoBanana. Мы не будем подробно рассказывать о процессе получения — просто получи и заполни соответствующие параметры. **На этом этапе не стремись понять каждую строку кода, просто пусть она работает.**

```Python
# /// script
# dependencies = [
#  "gradio>=4.0.0",
#  "pillow>=10.0.0",
#  "requests>=2.31.0",
# ]
# ///

import gradio as gr
import requests
import base64
from PIL import Image
import io
import os
import time
import re
from typing import Optional, Dict, Any, List

# Конфигурация информации API
NANOBANANA_API_URL: str = "YOUR API URL"
NANOBANANA_API_KEY: str = "YOUR API KEY"
OUTPUT_DIR: str = "outputs"

# Убеди, что выходной каталог существует
os.makedirs(OUTPUT_DIR, exist_ok=True)

def image_to_base64_data_uri(image: Image.Image) -> str:
    """
    Преобразуй PIL изображение в формат OpenAI API data URI.
    """
    buffer = io.BytesIO()
    # Преобразуй в PNG для гарантии совместимости
    image.save(buffer, format="PNG")
    encoded = base64.b64encode(buffer.getvalue()).decode('utf-8')
    return f"data:image/png;base64,{encoded}"

def base64_to_image(base64_str: str) -> Optional[Image.Image]:
    """
    Преобразуй чистую строку base64 в PIL Image.
    """
    try:
        image_bytes = base64.b64decode(base64_str)
        return Image.open(io.BytesIO(image_bytes))
    except Exception as e:
        print(f"Ошибка декодирования Base64: {e}")
        return None

def extract_base64_from_response(content: Any) -> Optional[str]:
    """
    Основная логика парсинга: извлеки данные Base64 изображения из контента API.
    Совместима с форматом Markdown и структурированным форматом списка.
    """
    if not content:
        return None

    base64_data = None

    # 1. Попытайся структурированное извлечение (List)
    # Соответствует формату возврата: [{"type": "image_url", "image_url": {"url": "data:..."}}]
    if isinstance(content, list):
        for part in reversed(content):  # Обратный поиск, обычно новое изображение в конце
            if isinstance(part, dict):
                # Проверь field image_url или output_image
                img_field = part.get("image_url") or part.get("image") or part.get("output_image")
                if isinstance(img_field, dict):
                    url = img_field.get("url", "")
                    if url.startswith("data:image/") and "," in url:
                        return url.split(",", 1)[1].strip()

        # Если в списке нет структурированного изображения, попробуй собрать текст для Markdown
        text_parts = [
            str(p.get("text", ""))
            for p in content
            if isinstance(p, dict) and p.get("type") in ["text", "input_text"]
        ]
        content_str = "".join(text_parts)
    else:
        content_str = str(content)

    # 2. Попытайся Markdown regex извлечение (String)
    # Соответствует формату возврата: "Here is your image: ![img](data:image/png;base64,AAAA...)"
    pattern = re.compile(r"!\[.*?\]\((data:image/[^;]+;base64,[^)]+)\)", re.IGNORECASE)
    match = pattern.search(content_str)

    if match:
        data_url = match.group(1)
        if "," in data_url:
            return data_url.split(",", 1)[1].strip()

    return None

def synthesize(prompt: str, input_image: Optional[Image.Image]) -> Optional[Image.Image]:
    """
    Вызови Nanobanana API для генерирования.
    """
    if not prompt or not prompt.strip():
        gr.Warning("Пожалуйста, введите промпт")
        return None

    print(f">>> Начало задачи: {prompt[:50]}...")

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {NANOBANANA_API_KEY}"
    }

    # Построй payload, согласно стандартам OpenAI Vision / Chat
    messages = []

    if input_image is not None:
        # Режим image-to-image / многомодальный ввод
        print(">>> Обнаружено входное изображение, используется многомодальный режим")
        img_base64 = image_to_base64_data_uri(input_image)
        messages.append({
            "role": "user",
            "content": [
                {"type": "text", "text": prompt},
                {"type": "image_url", "image_url": {"url": img_base64}}
            ]
        })
    else:
        # Режим text-to-image
        messages.append({
            "role": "user",
            "content": prompt
        })

    payload = {
        "messages": messages,
        # Используй первый проверенный модель из кода
        "model": "gemini-2.5-flash-image",
        # Опциональные параметры, в зависимости от поддержки API
        "stream": False
    }

    try:
        # Увеличь время ожидания, генерирование изображения обычно медленнее
        response = requests.post(NANOBANANA_API_URL, headers=headers, json=payload, timeout=120)

        # Проверь HTTP статус
        if response.status_code != 200:
            error_msg = f"API запрос провален: {response.status_code} - {response.text}"
            print(error_msg)
            gr.Error(error_msg)
            return None

        result = response.json()
        # Debug: вывести часть результата возврата для облегчения отладки
        print(f"Исходный ответ API (урезан): {str(result)[:200]}...")

        # Извлеки Content
        content = None
        if "choices" in result and len(result["choices"]) > 0:
            content = result["choices"][0].get("message", {}).get("content")

        if not content:
            gr.Warning("В результате API нет field content")
            return None

        # Используй проверенную логику для извлечения Base64
        base64_str = extract_base64_from_response(content)

        if base64_str:
            output_image = base64_to_image(base64_str)
            if output_image:
                return output_image

        # Если изображение не извлечено, возможно модель отклонила или только вернула текст
        text_content = str(content) if not isinstance(content, list) else " ".join([str(x) for x in content])
        gr.Info(f"Изображение не было сгенерировано, модель вернула текст: {text_content[:100]}...")
        return None

    except requests.exceptions.Timeout:
        gr.Error("Запрос истёк, пожалуйста, повторите позже")
        return None
    except Exception as e:
        import traceback
        traceback.print_exc()
        gr.Error(f"Произошла неизвестная ошибка: {str(e)}")
        return None

# Конфигурация Gradio интерфейса
with gr.Blocks(title="Nanobanana Image Generator") as app:
    gr.Markdown("# 🍌 Nanobanana Text/Image to Image")
    gr.Markdown("На основе модели Gemini-2.5-Flash-Image, поддерживает text-to-image и image-to-image.")

    with gr.Row():
        with gr.Column():
            prompt_input = gr.Textbox(
                label="Промпт (Prompt)",
                placeholder="Например: A cyberpunk cat holding a neon sign...",
                lines=3
            )
            image_input = gr.Image(
                label="Эталонное изображение (Опционально, для image-to-image)",
                type="pil",
                height=300
            )
            submit_btn = gr.Button("Начать генерирование", variant="primary")

        with gr.Column():
            image_output = gr.Image(label="Результат генерирования", format="png")

    submit_btn.click(
        fn=synthesize,
        inputs=[prompt_input, image_input],
        outputs=image_output
    )

if __name__ == "__main__":
    app.launch(share=True)
```

Когда Trae указывает на успешное выполнение, кликни на предоставленный локальный адрес (обычно http://127.0.0.1:7860).

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image9.png)

Если всё нормально, ты увидишь функциональный интерфейс ИИ рисования.

Интерфейс выглядит просто, но он уже имеет две самые основные возможности коммерческих инструментов рисования, то есть text-to-image и image-to-image.

* **Слева:** **Зона инструкций (Input Zone)** — здесь ты отдаёшь команды.
* **Prompt (поле промпта):** введи своё творческое описание (рекомендуется использовать английский).
* **Input Image (поле эталонного изображения):**
  * **Режим text-to-image:** оставь это **пусто**.
  * **Режим image-to-image:** перетащи локальное изображение сюда, ИИ создаст на его основе.
* **Кнопка Submit:** кликни, чтобы отправить команду и начать генерирование.
* **Справа: зона вывода (Output Zone)** — место, где происходит чудо, результат появляется здесь.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image10.png)

Теперь мы можем попытаться сгенерировать твоё первое изображение!

Промпт для этого примера:

> **A red apple**

Это намеренно упрощённый пример без описания стиля и параметров.

#### Фактический процесс

После выполнения кода процесс можно резюмировать в три шага:

1. Отправь текстовое описание модели
2. Модель генерирует соответствующее изображение
3. Изображение сохраняется как локальный файл

Через несколько секунд ты увидишь результат генерирования локально. Так как генерирование моделью имеет случайность, один и тот же промпт даст разные результаты, ты можешь генерировать несколько раз и выбрать понравившееся изображение.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image11.png)![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image12.png)

Можешь также обогатить свой промпт, дав ему больше описания и ограничений. Например, следующий промпт даст более особое изображение.

```
"A hyper-realistic close-up of a fresh red apple with water droplets on its skin, sitting on a dark rustic wooden table. Cinematic dramatic lighting, rim light, shallow depth of field, bokeh background, 8k resolution, macro photography."
```

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image13.png)

Кликни кнопку загрузки в области Output Image, чтобы сохранить на локальный компьютер.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image14.png)

### 1.3 Распространённые сценарии создания материалов моделью генерирования

На практике генерирование изображений большой моделью используется больше для **эффективного производства дизайн-материалов**, чем для создания единственного произведения искусства.

Когда ты смотришь на высокорейтинговые примеры в аккаунтах дизайн-маркетинга, обнаружишь, что их выпуск сосредоточен на двух сценариях:

* **Text-to-image (от 0 к 1)**
* **Генерирование с образцом изображения (от 1 к N)**

#### Один: Text-to-image: быстро получи дизайн-материалы

Этот сценарий сосредоточен на эффективности. Когда нужно заполнить пробелы в дизайне (как пустое состояние, аватары, сопутствующие изображения), ИИ, по сути, действует как **мгновенная библиотека изображений**.

1. ##### Генерируй UI материалы

* Тренд: часто встречается на Dribbble матовое стекло, глиняные 3D иконки
* Обычное проявление: прозрачные материалы, излучение на краях, конфетные цвета функциональных или погодных иконок

**Пример Prompt:**

> A set of 3D weather icons (sun, cloud, rain), glassmorphism style, frosted glass texture, soft pastel gradient colors, soft studio lighting, isometric view, transparent background, 4k.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image15.png)

2. ##### Генерируй Logo

* Тренд: минимальные линии, геометрические комбинации логотипа на тему технологий
* Обычное проявление: чёрно-белая цветовая схема, дизайн отрицательного пространства, явный брендинг

**Пример Prompt:**

> Minimalist vector logo design for a tech brand "Coffee Code", combining a coffee cup with coding brackets < >, flat design, solid black lines, white background, Paul Rand style, svg.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image16.png)

3. ##### Генерируй фотографии пользователя для официального сайта

* Тренд: SaaS официальный сайт обычно использует 3D виртуальный аватар, чтобы избежать авторских прав реального человека
* Обычное проявление: дружелюбное выражение, мультяшные пропорции, иклон Pixar или Memoji стиля

**Пример Prompt:**

> Close-up portrait of a friendly young tech professional, smiling, Memoji 3D style, clay render, bright colors, soft lighting, solid plain background, Pixar character design.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image17.png)

4. ##### Генерируй сопутствующие изображения к статье

* Тренд: абстрактные плоские иллюстрации, часто встречаются в блогах технологических компаний
* Обычное проявление: фиолетово-синяя цветовая схема, преувеличенные пропорции персонажа, плавающие UI элементы

**Пример Prompt:**

> Editorial flat illustration representing remote work, a person sitting on a giant globe using a laptop, corporate memphis art style, vibrant colors (purple and teal), vector texture.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image18.png)

#### Два: Генерирование с образцом изображения: сохрани визуальную последовательность

Этот сценарий больше сосредоточен на **расширяемости**. Когда уже есть удовлетворительный основной визуальный эффект, нужен полный набор материалов с последовательным стилем.

5. ##### Полный набор кнопок или интерактивных материалов, подобных основному визуальному эффекту

В разработке игр, согласованность UI очень важна. Предположим, уже есть основная кнопка **"PLAY"**, теперь нужно развернуть полный набор функциональных кнопок с единообразным стилем (как пауза, настройки, дом). Только ручной рисунок трудно гарантировать полную согласованность каждой кнопки в глянце, перспективе и цвете.

**Основной процесс:**

1. Сохрани существующее синее изображение кнопки "PLAY"

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image19.png)

2. Перетащи его в область **Input Image** интерфейса как эталон母板 для последующего генерирования
3. Сохрани описание стиля в промпте без изменений, только измени основное содержание

В этом процессе, просто замени описание основного содержания, можешь получить разные функциональные кнопки, но с одинаковым стилем.

**Пример Prompt:**

**Вариант A: Кнопка паузы (значок)**

> A capsule-shaped game UI button with a white pause icon (two vertical bars) inside. Same glossy blue jelly style, shiny plastic texture, white thick outline, vector illustration, high quality.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image20.png)

**Вариант B: Кнопка настроек (сложный значок)**

> A capsule-shaped game UI button with a white gear icon (settings symbol) inside. Same glossy blue jelly style, shiny plastic texture, white thick outline, vector illustration, high quality.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image21.png)

**Вариант C: Кнопка повтора (изменение формы)**

Если нужно отрегулировать форму кнопки, можешь прямо в промпте описать форму, модель попробует изменить структуру при сохранении характеристик материала.

> A round game UI button with a white circular arrow icon (replay symbol) inside. Same glossy blue jelly style, shiny plastic texture, white thick outline, vector illustration, high quality.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image22.png)

Через этот набор операций, не только можешь заменить функцию и значок кнопки, даже изменить форму кнопки, но все результаты генерирования остаются высоко согласованными в материале, цветовой схеме и свето-тени. Это и есть основная ценность большой модели в сценарии裂变 дизайн-материалов.

## Глава 2: Более послушный помощник по генерированию изображений — пример Lovart

В первой части мы напрямую вызывали NanoBanana через код, ощущали базовый процесс "ввод = генерирование". Этот метод работает, когда требование простое. Но когда задача генерирования начинает включать больше ограничений, например:

* Нужны несколько изображений с единообразным стилем
* Нужны повторные коррекции на основе существующих результатов
* Нужно динамически модифицировать направление генерирования в зависимости от ввода пользователя

Простой одноразовый вызов становится недостаточным.

Тогда нужно ввести **AI Agent (интеллектуальный агент)**. Эта секция использует **Lovart** в качестве примера, чтобы показать, как изменяется весь рабочий процесс, когда модель генерирования изображений имеет "слой мышления". Внимание! Это не реклама, просто помогаем быстро понять удобство AI Agent!

### 2.0 Первое знакомство с Lovart: твой ИИ дизайн-агент

Lovart — это дизайн-инструмент веб на основе Agent. По сравнению с обычными инструментами генерирования изображений, она добавляет слой "думания и планирования" перед генерированием.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image23.png)

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image24.png)

После входа в Lovart, необходимо понять следующие основные пункты управления:

#### Выбор модели

Кликни значок куба под полем ввода, можешь посмотреть текущие доступные модели генерирования (как GPT Image, Flux и т.д.).

Чтобы соответствовать предыдущему примеру, эта секция по-прежнему использует NanoBanana как нижнюю модель генерирования.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image25.png)

#### Режим мышления

Это основной выключатель Lovart:

* **Fast Mode (⚡)**: близка к исходному API, быстрый ответ, подходит для одиночного, явного указания генерирования
* **Thinking Mode (💡)**: режим Agent, ИИ сначала разберёт требование, переделает промпт, потом выполнит генерирование

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image26.png)

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image27.png)

#### Сетевая возможность

После открытия значка земли, Agent может извлекать сетевую информацию (например, дизайн тренды, цветовые схемы) при генерировании, как вспомогательный ввод.

### 2.1 Почему исходного API недостаточно?

Даже если уже можешь генерировать изображения приличного качества через Python, исходный API по-прежнему имеет ограничения в сложных задачах. Основная причина: исходный API, по сути, является императивным. Когда требуется сгенерировать конкретный объект, он может прямо выполнить; но когда ввод становится "стратегировать полный набор материалов для игры", он не будет активно разбирать цель на несколько выполняемых шагов.

Основное отличие Lovart — это механизм Agent. Между вводом пользователя и моделью генерирования изображений она добавляет слой логики для понимания и планирования: сначала определи намерение пользователя, потом разбери задачу, переделай промпт, и только потом выполни генерирование.

### 2.2 Практическая демонстрация: создай полный набор IP эмодзи за 5 минут

На примере **"создание полного набора IP эмодзи утки программиста"**, смотрим, как Agent участвует во всём процессе.

#### Секция один: Планирование (способность размышления Agent)

**Проблема исходного API:**
Нужно самому думать об установке персонажа, эмоциональных состояниях, писать промпт для каждого изображения.

**Способ Lovart:**

1. Включи 💡 **Thinking Mode**
2. Введи инструкцию:

> Спроектируй полный набор IP эмодзи утки программиста, стиль должен быть плоский, милый

ИИ не будет сразу рисовать, а сначала поищет в сети похожие дизайны утки программиста. Выведет разборанный план, автоматически сгенерирует сценарии как Debug, Coffee Break, Panic и т.д., и соответственно сгенерирует несколько визуальных описаний.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image28.png)![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image29.png)

На этом шаге ИИ изменилась с "исполнителя" на "планировщика". После анализа требований ИИ, можешь видеть несколько разных стилей и содержания изображений утки программиста в области рисования. Можешь начать выбирать свои любимые стили.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image30.png)

#### Секция два: Последовательность (якорь визуала на основе образца)

Изображения в Lovart — не только результаты, но и участвуют в последующем генерировании.

##### Полное образцовое изображение

* Из эскиза выбери самое удовлетворительное "стандартное изображение утки", кликни соответствующее изображение в области рисования
* То изображение автоматически появится в зоне диалога как Reference

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image31.png)

* Введи новое действие (как счастье) и генерируй

Результат генерирования унаследует цвет, пропорции и детали матрицы.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image32.png)

##### Локальный образец / интеграция нескольких изображений

Кроме всего изображения как образца, Lovart также поддерживает:

* **Выбери только локальную область изображения** (например, только образец шляпы или выражение)

Кликни на вкладку слева в области рисования, выбери "Mark" ключ, пометь локальную область целевого изображения, это содержание автоматически синхронизируется в диалоговое окно. Например, здесь мы можем выбрать изменить цвет фона.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image33.png)

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image34.png)

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image35.png)

Можешь видеть, что вновь сгенерированное изображение только изменило цвет фона, что совпадает с нашим требованием.

* **Отдельно ссылай подэлементы из нескольких изображений**, потом объедини, генерируй новый результат

Например: можешь сохранить главное тело персонажа из изображения A, одновременно только заменить шляпу на стиль из изображения B, Agent автоматически интегрирует эти визуальные ограничения позади.

На примере утки программиста, можем выбрать сохранить образ утки из первого изображения и заменить его на главный элемент во втором изображении.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image36.png)

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image37.png)

Итоговый эффект также очень заметен. Можешь также попробовать другие комбинации!

#### Секция три: Приземление (вызов инструментов Agent)

После завершения генерирования, можешь прямо выполнить: увеличение, удаление фона, стирание и другие операции

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image38.png)

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image39.png)

Это не просто фильтры, а результаты Agent, автоматически диспетчеризующей разные инструменты.

После определения базового стиля, можешь очень быстро сгенерировать серию изображений эмодзи.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image40.png)

В итоге получаем материалы, готовые к прямой доставке, а не просто демонстрационное изображение.

### 2.3 Описание способа использования и взимание платы

Lovart использует модель подписки с различными тарифами, соответствующими разным объёмам использования и разрешениям функций, конкретные детали на официальном сайте.

Этот учебник не рекомендует или не сравнивает никакие тарифы; если есть требования при использовании, можешь выбрать платное обновление в зависимости от ситуации.
В настоящее время поддерживается завершение платежей через **Alipay** и другие способы.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image41.png)

#### Краткий итог

Lovart не заменяет нижнюю модель, а через механизм Agent поднимает генерирование изображений с "одноразового выполнения" на "непрерывный рабочий процесс".

Когда задача начинает вовлекать планирование, последовательность и доставку, преимущества таких инструментов становятся очень очевидными.

## Глава 3: Сам создай интеллектуального помощника по рисованию

Кроме прямого использования Lovart, мы также можем сами реализовать упрощённую версию помощника по рисованию.

Эта глава на примере "автоматической подготовки изображений к статьям", вывод из практических проблем, пошагово построит Agent с возможностью мышления.

### 3.1 Болевые точки: почему прямо дать статью модели рисования не работает?

Прямо введи длинную статью в NanoBanana и требуй подготовить изображение, обычно трудно получить идеальный результат. Причина не в том, что модель "плохо рисует", а в том, что **она не очень хороша в понимании длинного текста**.

Модель генерирования изображений лучше обрабатывает короткие, явные визуальные описания, когда ввод становится отрывком, содержащим структуру,重点 и отношение контекста статьи, модель не может определить, какое содержание действительно нужно выразить на рисунке. Это часто приводит к тому, что результат генерирования отклоняется от темы, или может только захватить рассредоточенные детали, не хватает способности целостного обобщения.

По сути, модель изображений имеет только способность "выполнения", не хватает процесса анализа и выбора текста.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image42.png)

### 3.2 Решение: используй Agent разбей "понимание" и "выполнение"

Чтобы решить эту проблему, ключ не в более сложном промпте, а в **ясном понимании перед рисованием**. Поэтому, в процесс генерирования мы вводим независимый "слой мышления", на его основе построим самый простой используемый Agent.

Основная цель этого Agent только одна: **сделай финально генерируемое изображение максимально близким к истинному намерению выражения пользователя.**

Общий процесс можно резюмировать: **длинный текстовый ввод → понимание и суждение языковой модели → генерирование подходящего визуального промпта → выполнение генерирования моделью изображений → вывод изображения**

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image43.png)

Как же Agent, который мы построили, понять намерение пользователя?

Здесь мы выбираем упрощённый **"слой мышления"**, установили три разных намерения: неправильный ввод, прямое генерирование, длинный текст требующий понимания.

В этом Agent разделение ролей можно резюмировать четырьмя пунктами:

1. **Языковая модель как ядро принятия решения**
   Она отвечает за понимание содержания статьи, определение намерения ввода пользователя, диспетчеризацию задачи на подходящий путь генерирования, решает "что делать потом" и как генерировать промпт для рисования.
2. **Модель изображений как исполнитель**
   Модель изображений не участвует в понимании и суждении, только принимает уже организованные визуальные команды, сосредоточивается на завершении рендеринга изображений.
3. **Пользователь как интервенционный проводник**
   Кроме прямого ввода текста, пользователь также может вручную отрегулировать генерируемый промпт в процессе, или добавить образцовое изображение для вспомогательного генерирования, ведущих и коррегирующих финальный результат.
4. **Gradio и backеnd API как общий несущий слой**
   Они отвечают за связи интерфейса, вызовов моделей и вывода результатов, гарантируя, что весь Agent может стабильно работать в форме полного веб приложения.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image44.png)

### 3.3 Практическая подготовка: получи API

Звучит интересно? Чтобы запустить вышеприведённый процесс, нам нужно подготовить два класса API.

#### Рука: NanoBanana API (генерирование изображений)

Прямо используй API Key и API URL, уже настроенные в главе 1, без дополнительной настройки.

#### Мозг: SiliconFlow API (текстовое мышление)

Нам нужна большая языковая модель для несения ответственности "слоя мышления". Этот учебник использует услугу модели, предоставленную SiliconFlow: https://cloud.siliconflow.cn/

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image45.png)

SiliconFlow предоставляет интерфейсы, совместимые со спецификацией OpenAI API, может быть очень удобно вызваны в проекте через стандартный сетевой запрос. Здесь мы выбираем бесплатную модель Qwen2.5-7B-Instruct, всё необходимое для вызова уже написано в нижеприведённом Prompt. Прежде чем начать, нужно зарегистрировать аккаунт на официальном сайте и создать API Key.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image46.png)

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image47.png)

Этот Key будет использоваться для последующих вызовов модели.

### 3.4 Построение Agent:

Этот эксперимент в основном использует Trae, чтобы помочь нам писать код, этот учебник выбрал модель Gemini-3-Pro-Preview. Общая идея: после создания проекта скопируй нижеприведённый полный Prompt в диалоговое окно и введи, пошагово замени API KEY и запусти код, заверши тестирование.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image48.png)

#### Секция 1️⃣: Основной фреймворк Gradio Blocks и раскладка интерфейса

На этой секции наша основная цель — сначала дать всему Agent "внешний вид", реализовать дизайн фронтенд-страницы. После копирования нижеприведённого Prompt в диалоговое окно Trae, ты получишь локальный URL (обычно http://127.0.0.1:7860) для просмотра интерфейса, и проверь эффект реализации.

```
Блок 1: Основной фреймворк Gradio Blocks и раскладка интерфейса
1、Цель задачи
·На основе Gradio 4.0.0+ Blocks раскладки, реализуй интерфейс базового уровня проекта "LLM+Nanobanana text-to-image", строго следуй фиксированной левой-правой двухколонной раскладке, инициализируй все UI компоненты и установи правильное начальное состояние.

2、Требования технологического стека
·Нужна программа Gradio 4.0.0+ Blocks, запрещён режим Interface;
·Зависимости: gradio>=4.0.0, pillow>=10.0.0 (только import, логика обработки изображений не реализована);
·Код — полный работающий Python файл, содержит все необходимые import.

3、Правила раскладки интерфейса (основные ограничения, интегрирует реальные детали)
·Общая раскладка:
Заголовок страницы: LLM-ориентированный инструмент text-to-image полного процесса;
Фиксированная левая-правая двухколонная: левая 60% ширины, правая 40% ширины, используй gr.Row и gr.Column для контроля доли.
·Левая 60% (зона процесса генерирования промпта) список компонентов:
input_text: gr.Textbox, метка "Ввод текста (учебный раздел / инструкция рисования)", lines=6, placeholder "Пожалуйста, введи учебный текст, требующий подготовки изображения, или прямую инструкцию рисования...";
identify_intent_btn: gr.Button, value="Определи намерение", начальное состояние нормально кликабельно;
intent_status: gr.Textbox, метка "Тип намерения / Состояние обработки", lines=2, interactive=False, начальное значение "Намерение не определено";
system_prompt: gr.Textbox, метка "System Prompt (только для намерения подготовки статей редактируемо)", lines=4, interactive=False, placeholder "Ограничивающие правила для генерирования промпта ИИ...";
confirm_prompt_btn: gr.Button, value="确认生成生图提示词", interactive=False (начально отключено, чтобы предотвратить ошибочное нажатие);
generation_prompt: gr.Textbox, метка "Промпт рисования (редактируемо)", lines=3, interactive=True, начальное значение пусто, placeholder "Генерируемый английский промпт рисования появится здесь, поддерживает ручное редактирование...".
·Правая 40% (функциональная зона Nanobanana рисования) список компонентов:
ref_image: gr.Image, метка "Образцовое изображение (опционально, image-to-image)", type=filepath, height=300, разрешить загрузку;
generate_btn: gr.Button, value="Генерируй изображение", interactive=False (начально отключено, без промпта не кликабельно);
result_image: gr.Image, метка "Результат генерирования", type=pil, height=300, начально пусто, interactive=False.

4、Требования интерактивной логики
·Начальное состояние interactive всех компонентов строго по вышеуказанной конфигурации, позже динамически обновляй через функции;
·Состояние кнопки отключения нужно видно (серое), чтобы избежать ошибочного действия пользователя.

5、Требования вывода
·Генерируй полный Python код, только реализуй раскладку интерфейса и инициализацию компонентов, не включай никакую бизнес-логику;
·Комментарий кода ясен, имя компонента совпадает с реальной версией (input_text/identify_intent_btn и т.д.);
·Код может быть прямо запущен, структура интерфейса полностью совпадает с описанием.
```

После открытия http://127.0.0.1:7860 в браузере, можешь видеть, что Trae по нашему требованию сгенерировала следующую веб-страницу, примерно соответствует нашему требованию, можешь перейти к следующему этапу генерирования.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image49.png)

#### Секция 2️⃣: LLM модуль определения намерения (Siliconflow API)

При ежедневном использовании VLM для рисования, могут быть следующие три распространённых ситуации ввода:

1. Бессмысленное содержимое, как "привет", "ты сегодня ел?", не может нарисовать соответствующее изображение.
2. Статья/длинный текст, около 200 слов структурированной статьи, нужно сначала понять структуру и содержание статьи, потом подумать, как сгенерировать изображение, полностью обобщающее этот текст.
3. Прямая инструкция рисования, как "нарисуй мне собаку, принимающую ванну", требование уже очень явно сформулировано, можешь прямо генерировать изображение.

Как и раньше, скопируй нижеприведённый Prompt в диалоговое окно Trae для реализации, и дополни полученный API на предыдущем шаге.

```
Блок 2: LLM модуль определения намерения (Siliconflow API)
1、Цель задачи
На основе реализованного Gradio интерфейса, добавь логику нажатия кнопки "Определи намерение", вызови Siliconflow API для завершения определения намерения, и свяжи состояние компонентов.

2、Требования технологического стека
На основе Gradio 4.0.0+ Blocks;
Зависимости: requests>=2.31.0, openai;
Вывод полный работающий Python файл, содержит раскладка блока 1 + логику этого модуля.

3、Основные правила бизнеса (абсолютно не может отклоняться)
·Правила классификации намерения (только 3 типа, строго возврати число + описание)
1 = Бессмысленное содержимое: только обычный разговор, приветствие, нет отношения к диалогу, нет никаких требований рисования или подготовки изображений (как "привет""ты сегодня ел?");
2 = Требование подготовки изображений для статьи / длинного текста: пользователь введёт полную статью, учебник, раздел, пояснительный текст, содержание склоняется к рассказу / пояснению / объяснению, скрытое намерение нужна подготовка изображений для этого содержимого, не нужно пользователю явно сказать "подготовь изображение для этого текста";
3 = Прямая инструкция рисования: пользователь введёт короткую, явную команду рисования, без фона длинного текста, прямо требует нарисовать некоторое содержимое (как "нарисуй кошку в стиле Apple").
·Ограничение вызова LLM (интегрирует реальный шаблон версии)
Адрес интерфейса: https://api.siliconflow.cn/v1/chat/completions;
Модель: Qwen/Qwen2.5-7B-Instruct;
temperature=0.1;
Унифицированное определение кода:
LLM_BASE_URL = "https://api.siliconflow.cn/v1"
LLM_API_KEY = ""  # пользователь самостоятельно заменит
LLM_MODEL = "Qwen/Qwen2.5-7B-Instruct"
# Проверенный на практике шаблон определения намерения (зафиксировано в коде)
INTENT_PROMPT_TEMPLATE = """Нужно определить намерение введённого текста пользователя, только возврати один из следующих 3 результатов (формат: число + китайское описание):
1 = Бессмысленное содержимое; 2 = Требование подготовки для статьи / длинного текста; 3 = Прямая инструкция рисования.

Ввод пользователя: {user_input}

Результат определения:
Только извлеки число и описание в результате возврата, запрещено дополнительное содержимое."""

4、Правила связи компонентов
·Результат 1: intent_status отобрази "1 = Бессмысленное содержимое: нет требования рисования", system_prompt оставить отключённым, confirm_prompt_btn отключить;
·Результат 2: intent_status отобрази "2 = Требование подготовки для статьи / длинного текста: генерируй подготовку для введённого содержимого", включи system_prompt и заполни правилами по умолчанию, активируй confirm_prompt_btn;
·Результат 3: intent_status отобрази "3 = Прямая инструкция рисования: генерируй изображение по инструкции", system_prompt отключи и заполни правилами по умолчанию, активируй confirm_prompt_btn.

5、Обработка исключений
Исключение API, исключение парсинга оба выведи дружелюбное сообщение, не крахируй, компоненты возвращаются в начальное состояние.

6、Требования вывода
Генерируй полный работающий код, замени LLM_API_KEY и можешь использовать, логика ясна, комментарии полны, шаблон определения намерения строго используй реальную версию.
```

Обнови предыдущий адрес http://127.0.0.1:7860, начни тестировать может ли правильно обнаруживать три ситуации.

1. Бессмысленное содержимое, можешь попробовать ввести "привет", "спасибо" и т.д., обнаруживаешь может правильно определить.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image50.png)

2. Статья/длинный текст, здесь мы выбрали отрывок описания искусственного интеллекта. Можешь также попробовать использовать свой текст раздела диссертации для тестирования.

```
Искусственный интеллект переделывает экосистему образования на беспрецедентной глубине и широте. Через адаптивные алгоритмы обучения, системы ИИ могут построить карту познания каждого студента, в реальном времени отслеживать их траекторию знаний, и динамически регулировать сложность и способ представления содержимого обучения. В традиционной классной среде учителям часто трудно одновременно удовлетворить потребности студентов с разными стилями обучения и уровнями способностей, в то время как платформы образования на основе глубокого обучения могут анализировать поведенческие модели студентов в интерактивных имитационных экспериментах, определять их микроскопические препятствия в понимании сложных концепций, как квантовая механика или исчисление, и предоставлять точные познавательные опоры.

Передовые механизмы обработки естественного языка, управляемые виртуальными наставниками, не только могут разбирать открытые вопросы, как "Как оценить влияние французской революции на современные демократические системы", но и могут направлять сократический диалог, вдохновляя критическое мышление. Когда студенты пишут статьи о влиянии изменения климата на экосистемы полюсов, помощник ИИ по письму может анализировать строгость аргументационной логики, указывать проблемы своевременности ссылок на данные, и предлагать более точную научную терминологию. В сфере специального образования, техники компьютерного зрения позволяют ИИ определять невербальные сигналы детей спектра аутизма при социальном взаимодействии, регулировать стратегии вмешательства, в то время как алгоритмы вычисления эмоций помогают обнаруживать разочарование при онлайн обучении, предоставляя своевременную обнадёживающую обратную связь.

Однако такое слияние технологии вызывает ряд этических дилемм. Смещение алгоритма может непреднамеренно маргинализировать студентов из специфических культурных предпосылок, проблемы прозрачности сбора данных вызывают озабоченность по поводу приватности в академических кругах, в то время как чрезмерная зависимость от систем автоматической оценки может подорвать глубокое понимание учителями мыслительных процессов студентов. Более сложно, когда ИИ начинает генерировать высоко реалистичный опыт виртуальной лаборатории, нам нужно переопределить ценность "практического опыта" в образовании. Парадигма будущего образования может развиться в то, что преподаватели-люди сосредоточены на развитии творчества, сочувствия и способности морального суждения, в то время как системы ИИ берут на себя передачу знаний, тренировку навыков и персонализированную оценку, формируя вид симбиотического образования с совместной эволюцией, что может развить вычислительные преимущества машин, и одновременно сохранить уникальную тепло человеческого образования.
```

Также обнаруживаешь успешно!

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image51.png)

3. Прямая инструкция рисования, здесь введён "я хочу нарисовать кошку", также определено точно.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image52.png)

До этого мы успешно реализовали вторую секцию — определение намерения.

#### Секция 3️⃣: Модуль генерирования промпта (второй вызов LLM)

После определения намерения, для статей или длинного текста, есть очень важный шаг — генерирование промпта рисования, и это именно фокус этого Agent.

```
Блок 3: Модуль генерирования промпта рисования (второй вызов LLM)
1、Цель задачи
На основе определения намерения, реализуй логику кнопки "확認生成生图提示词", вызови LLM для оптимизации текста в подходящий для рисования английский визуальный промпт, заполни фрейм редактирования и свяжи кнопку "Генерируй изображение".

2、Требования технологического стека
То же, что блок 2, вывод полный код = блок 1 + блок 2 + этот модуль;
Совместное использование определённых LLM_BASE_URL, LLM_API_KEY, LLM_MODEL из блока 2, не добавляй новые ключи.

3、Основные правила бизнеса (интегрирует реальную логику собирания Prompt версии)
·Правило ввода генерирования промпта (необходимо строго следовать)
Генерирование промпта не является простым собиранием строк, а построением стандартного списка сообщений Chat, структура кода как следует:
messages=[# Роль System: содержимое system_prompt, окончательно подтвержденное/отредактированное пользователем на веб-странице{"role": "system", "content": final_system_prompt},# Роль User: несёт обработанные данные, явно выражает цель задачи{"role": "user", "content": f"Пожалуйста, генерируй визуальный промпт для следующего содержимого:\n\n{user_input}"}]
Когда намерение 2: содержимое System берётся из окончательной версии system_prompt, отредактированной пользователем;
Когда намерение 3: содержимое System берётся из заполненного правилами по умолчанию в отключённом состоянии
user_input — это исходный текст, который пользователь первоначально ввёл в фрейм input_text.
·Реально проверенный System Prompt предустановка (зафиксировано в коде)
SYSTEM_PROMPT_DEFAULT = """Ты сейчас помощник по созданию промпта для рисования NanoBanana.
Нужно на основе моей обработки содержимого, образ, созданный мной, может объяснить, о чём говорится в этом отрывке, и позволить всем узнать, что структура этого отрывка описывает в целом.
Это может быть похоже на некоторые объяснения PPT (как: левый верхний угол выбирает основное понимание, правый нижний угол демонстрирует данные).
Требование стиля дизайна: простой, мышление дизайна Apple (Apple Design Philosophy).
Ограничение: пожалуйста, прямо верни промпт на английском, который может использовать NanoBanana, не возвращай никаких объяснений, префиксов или лишних разговоров."""
·Ограничение вызова LLM
Совместное использование одного набора LLM_BASE_URL, LLM_API_KEY, LLM_MODEL с блоком 2;
temperature=0.7 (гарантируй творчество и применимость промпта);
max_tokens=200 (ограничь длину вывода, соответствуй ограничению промпта);
строго используй вышеприведённую стандартную структуру списка сообщений Chat, запрещено собирание строк.
·Пример ввода-вывода (основной справочник)
Пример ввода 1 (намерение подготовки статьи): Исходный текст: "Как ИИ изменяет образование: с развитием технологии искусственного интеллекта, роль учителя изменяется с передачи знаний на наставника, помощники ИИ могут помочь студентам завершить персонализированное обучение, человеко-машинное сотрудничество в классе становится нормой." Окончательный System Prompt: SYSTEM_PROMPT_DEFAULT (не изменён) Ожидаемый вывод: "Minimalist illustration, Apple Design Philosophy, 1024x1024. Top left shows 'AI + Education' core concept, bottom right shows data of teacher-student-AI collaboration, soft color palette, clean lines, no redundant elements."
Пример ввода 2 (прямая инструкция рисования): Исходный текст: "Нарисуй кошку в стиле Apple, сидящую рядом с MacBook" Окончательный System Prompt: SYSTEM_PROMPT_DEFAULT (отключено состояние) Ожидаемый вывод: "Minimalist cat, Apple style, 1024x1024, sitting next to a silver MacBook, clean white background, soft shadows, geometric shapes, no extra details."
·Принудительное ограничение вывода промпта
Только английский, без китайского;
Должно содержать Apple Design Philosophy/Apple style + 1024x1024;
Длина 50–200 символов, валидация кода;
Нет дополнительных объяснений, префиксов или разговоров, только сам промпт.

4、Правила связи компонентов
Успешное генерирование: заполни промпт в фрейм generation_prompt, активируй generate_btn, intent_status добавь "генерирование промпта успешно, можешь редактировать и потом генерировать изображение";
Неудачное генерирование: укажи конкретную причину (как вызов API провален, длина не достаточна), generate_btn оставить отключённым, фрейм generation_prompt пусто;
Пользователь вручную редактирует / очищает фрейм generation_prompt:
Когда очищено, автоматически отключи generate_btn;
Когда не пусто, сохрани generate_btn активированным.

5、Обработка исключений
Вызов API провален: дружелюбное сообщение "генерирование промпта провалилось: {конкретная информация об ошибке}", не крахируй;
Валидация промпта провалилась: явно укажи причину (как "не включён Apple style""длина только 40 символов"), позволи повторить;
Парсинг ответа провален: укажи "невозможно парсить результат LLM, пожалуйста, повтори".

6、Требования вывода
Полный работающий код, замени LLM_API_KEY и можешь использовать;
Структура кода ясна, комментарии тщательны, интерфейс красив и просто;
Строго реализуй структуру стандартного списка сообщений Chat, параметры и логика примера совпадают;
Включи логику проверки длины промпта и содержимого, дружелюбное сообщение об ошибке.
```

Также скопируй текст второй секции для тестирования.

Стоит отметить, что здесь мы предустановили System Prompt для генерирования промпта рисования:

> Ты сейчас помощник по созданию промпта для рисования NanoBanana.
> Нужно на основе моей обработки содержимого, образ, созданный мной, может объяснить, о чём говорится в этом отрывке, и позволить всем узнать, что структура этого отрывка описывает в целом.
> Это может быть похоже на некоторые объяснения PPT (как: левый верхний угол выбирает основное понимание, правый нижний угол демонстрирует данные).
> Требование стиля дизайна: простой, мышление дизайна Apple (Apple Design Philosophy).
> Ограничение: пожалуйста, прямо верни промпт на английском, который может использовать NanoBanana, не возвращай никаких объяснений, префиксов или лишних разговоров.

Если хочешь заменить другой предустановленный шаблон, можешь модифицировать на предыдущем промпте, или прямо в Trae через диалог модифицировать.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image53.png)

Кроме модификации底层 кода, мы также можем быстро редактировать на веб-странице. Например, здесь я добавил фразу "добавь впереди Pic Prompt", видимо новый генерируемый промпт также включает эту фразу. Это спроектировано, чтобы легко быстро модифицировать System Prompt генерирования промпта, помогая нам быстро переключать стили.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image54.png)

#### Секция 4️⃣: Модуль Nanobanana text-to-image / image-to-image

Наконец наступил последний шаг, не подключая модель генерирования, это не будет полным Agent!

```
Блок 4: Модуль Nanobanana text-to-image / image-to-image (финальная версия)
1、Цель задачи
Реализуй логику кнопки "Генерируй изображение", вызови реальный Nanobanana API, поддерживай text-to-image / image-to-image, парсируй Base64 и отобрази изображение.

2、Требования технологического стека
На основе Gradio 4.0.0+ Blocks;
Зависимости: requests, pillow, base64, io, re;
Полный код = блок 1+2+3 + этот модуль.

3、Основной конфиг API (реально проверенный, зафиксирован)
Зафиксированный конфиг кода:
# Зафиксированный конфиг API в коде
NANOBANANA_API_URL = "https://api.zyai.online/v1/chat/completions"
NANOBANANA_MODEL = "gemini-2.5-flash-image"
NANOBANANA_API_KEY = ""  # пользователь самостоятельно заменит
Метод аутентификации: Header Authorization: Bearer {NANOBANANA_API_KEY}.

4、Требование предварительной обработки изображения (необходимо реализовать) Реализуй функцию image_to_base64_data_uri (ref_image_path), основная логика:
Преобразуй PIL изображение в формат PNG;
Автоматически масштабируй до разрешения 1024x1024;
Прозрачный канал преобразуй в белый фон;
Кодируй в Base64, возвращаемый формат: data:image/png;base64,...

5、Правило построения запроса (строго следуй логике ветвления реальной версии)
·Определение основной функции Реализуй функцию generate_image (prompt, ref_image_path):
Входные параметры: prompt (содержимое фрейма generation_prompt), ref_image_path (путь загруженного файла ref_image);
Возврат: PIL Image (отобрази на result_image) или сообщение об ошибке.
·Логика ветвления 1: Только text-to-image (ref_image_path пусто)
messages = [{"role": "user", "content": prompt}]
·Логика ветвления 2: image-to-image (ref_image_path имеет значение)
# Сначала вызови функцию предварительной обработки изображения
image_base64 = image_to_base64_data_uri(ref_image_path)
messages = [{"role": "user","content": [{"type": "text", "text": prompt},{"type": "image_url", "image_url": {"url": image_base64}}]}]

6、Требование парсинга ответа (необходимо поддержать оба формата) Извлеки Base64 из choices [0].message.content, поддержи:
Результат JSON структурированного возврата поля image_url;
Формат Markdown ![](...)
;
Унифицированное извлечение Base64 кодирования, декодируй потом преобразуй в PIL Image для возврата.

7、Связь компонентов и обработка исключений
Успешное генерирование: отобрази PIL Image на result_image, intent_status укажи "изображение успешно генерировано";
Генерирование / парсинг / загрузка провалились: отобрази в intent_status ясное текстовое сообщение (как "Base64 парсинг провален""вызов API истёк"), не крахируй.

8、Требования вывода
Полный работающий код, замени LLM_API_KEY и NANOBANANA_API_KEY и можешь прямо запустить, весь процесс работает, логика ветвления строго совпадает с реальной версией.
```

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image55.png)

Как волнующе! Наконец нам удалось успешно сгенерировать первое изображение этого Agent, внимательно посмотри, генерируемое изображение совпадает с нашим текстом и промптом. До этого ты уже основном реализовал собственный Agent!

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image56.png)

Мы также добавили функцию image-to-image, загрузи понравившееся изображение, ИИ автоматически заимствует стиль.

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image57.png)

Стоит отметить, что промпт, сгенерированный на предыдущем шаге, также редактируем на веб-странице, и мы берём промпт на момент окончательного нажатия кнопки. Даже если я здесь замену на "a cute cat", финально генерируемое изображение будет только милого кота.

## Глава 4: Резюме

![](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/frontend/lovart-assets/images/image58.png)

**Наконец закончил!**
Честно говоря, даже когда я пишу последнюю строку, я не могу не вздохнуть, не говоря уже о тебе, прошедшем весь этот процесс. Способность полностью запустить этот процесс — уже очень здорово, это означает, что ты действительно положил руки на клавиатуру и пошагово завершил дело. Браво! 🎉 🥳 👏

При написании этого содержимого я постоянно думал, что мы должны оставить? Ответ на самом деле не названия моделей, параметры или какой-нибудь фиксированный способ, а позволить тебе постепенно построить ощущение: какие вещи можешь спокойно отдать ИИ для понимания и планирования, какие места тебе просто нужно определить направление. Как только это разделение установлено, многие изначально сложные процессы генерирования начнут становиться гладкими.

Оглядываясь назад, этот путь на самом деле не сложен. Думай ясно, какую проблему хочешь решить, отдай длинный текст языковой модели для анализа, потом отдай организованное визуальное намерение модели генерирования изображений для выражения, наконец дорабатывай этот весь процесс в собственного маленького помощника. К этому моменту, ты уже "не просто используешь модель", но строишь систему, которая может долгое время сопровождать твою работу, и это, именно то, что этот учебник хочет дать тебе.

Но ты уже хорошо сделал! Верю, что обучение здесь тебе уже дало начальное понимание Vibe Coding, дай себе маленький отпуск и отдохни!
