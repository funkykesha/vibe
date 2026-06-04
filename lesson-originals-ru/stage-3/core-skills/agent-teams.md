# Полное руководство по Claude Agent Teams

<!-- nav -->
**📚 Версии:** [Кратко](../../../lesson-summaries/stage-3/core-skills/agent-teams.md) · [Расширенно](../../../lesson-summaries-full/stage-3/core-skills/agent-teams.md) · **Полный перевод** · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-3/core-skills/agent-teams/index.md)


## Введение в Agent Teams

**Agent Teams** — это революционная функция Claude Code, которая позволяет **нескольким независимым экземплярам AI работать вместе как настоящая команда разработчиков**.

Представьте себе, что раньше при использовании Claude Code вы работали как проектный менеджер с одним супер способным помощником. Независимо от сложности задачи, только один помощник работает. Теперь с Agent Teams вы можете собрать полноценную AI команду разработчиков — одни отвечают за фронтенд, другие за бэкенд, третьи за тестирование, и они могут **работать одновременно, общаться друг с другом и совместно выполнять сложные задачи**.

![домашняя обложка](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-3/core-skills/agent-teams/images/home-cover.svg)

### От одного помощника к командной работе

Перед тем как глубоко разбираться в Agent Teams, давайте сначала поймём проблемы, которые она решает.

**Ограничения режима с одним AI**:

При работе с одним экземпляром Claude на сложных проектах вы столкнётесь с этими узкими местами:

- **Узкое место последовательной обработки**: AI может делать только одно в раз. Например, при рефакторинге проекта ему нужно сначала проанализировать модуль аутентификации, затем модуль базы данных, и наконец модуль API. Эти шаги должны выполняться последовательно, даже если между ними нет зависимостей.

- **Проблема переполнения контекста**: вся информация находится в одном окне разговора. Когда диалог становится длинным, критические детали из начала легко теряются, и AI может забыть важные решения, обсуждавшиеся ранее.

- **Ограничение однозначной перспективы**: только один AI думает, отсутствует многоугольный анализ и проверка. При встречи со сложными решениями по дизайну некому "коллеге" дебатировать или предложить другую точку зрения.

- **Потолок производительности**: крупные рефакторинги или разработка с несколькими модулями требуют много времени, невозможно ускориться через параллелизм.

**Решение Agent Teams**:

Agent Teams решает эти проблемы через **параллельное сотрудничество нескольких экземпляров**:

- **Истинная параллельная работа**: несколько AI могут одновременно обрабатывать разные задачи. Один отвечает за UI фронтенда, один за API бэкенда, один за дизайн базы данных, и они не мешают друг другу.

- **Независимые пространства контекста**: каждый член команды имеет свой собственный полный контекстное окно в 200K токенов, не будет забывать важную информацию из-за длинного диалога.

- **Способность командной работы**: члены могут прямо общаться, обсуждать решения по дизайну, взаимно проверять качество кода, как в настоящей команде разработки.

- **Значительное повышение производительности**: согласно внутренним тестам Anthropic, производительность крупных рефакторингов проектов может увеличиться на около 50%.

---

## Agent Teams vs Subagent

Перед углублением в архитектуру Agent Teams, необходимо уточнить частое замешательство: **в чём разница между Agent Teams и Subagent?**

Обе эти функции включают "несколько AI, работающих вместе", но их модели сотрудничества совершенно различны и применимы к разным сценариям.

### Сравнение ключевых различий

| Измерение | Subagent (подагент) | Agent Teams (командные агенты) |
|---------|-------------------|----------------------|
| **Топология** | Звёздная топология — все подагенты отчитываются главному агенту | Сетевая топология — члены могут общаться друг с другом |
| **Способ общения** | Главный агент явно передаёт информацию через prompt, подагенты возвращают результат | Члены могут прямо общаться, обсуждать и координироваться |
| **Управление контекстом** | Каждый подагент имеет независимый контекст, главный агент передаёт только необходимую информацию | Каждый член имеет полностью независимый контекст |
| **Способность параллелизма** | Может выполняться параллельно, но цепь сотрудничества всё ещё центрирована вокруг главного агента | Истинная параллельная разработка и сотрудничество |
| **Координация задач** | Главный агент единолично распределяет и координирует | Члены могут самостоятельно взять задачу |
| **Стоимость** | Не низкая. При параллельном выполнении нескольких подагентов потребление токенов складывается | Довольно высокая. Члены работают независимо и чаще общаются |

### Образная аналогия

**Subagent похож на**: менеджер, который даёт несколько помощникам отдельные листки заданий. Каждый помощник берёт свой листок, работает независимо, и после завершения только возвращает результат менеджеру. Помощники не разговаривают друг с другом напрямую, и менеджер не видит полный процесс мышления помощника при выполнении задачи.

```
Вы → Главный агент → Подагент A: "Проанализируй этот файл"
Вы → Главный агент → Подагент B: "Поищи эту функцию"
         ↓
    Подагент A завершён → Отчёт главному агенту
    Подагент B завершён → Отчёт главному агенту
         ↓
    Главный агент синтезирует результаты → Отчёт вам
```

**Agent Teams похож на**: проектный менеджер, ведущий настоящую команду разработки. Члены команды могут напрямую общаться, обсуждать, сотрудничать, а не всё проходит через менеджера.

```
Вы → Team Lead: "Сделай функцию аутентификации"
         ↓
    Team Lead создаёт команду, распределяет задачи
         ↓
    Товарищ A: "@Товарищ B, API интерфейс готов?"
    Товарищ B: "Готов, вот формат..."
    Товарищ C: "Я посмотрел интерфейс, нужно обсудить..."
         ↓
    Члены команды совместно завершили → Team Lead синтезирует → Отчёт вам
```

### Когда использовать что-то

**Сценарии использования Subagent**:

- Быстрые, чёткие одиночные задачи (как "поищи этот код ошибки")
- Между задачами нет много зависимостей
- Нужна параллельная обработка, но не нужны постоянные обсуждения между членами

**Сценарии использования Agent Teams**:

- Сложный системный рефакторинг, затронувший несколько модулей
- Нужен многоугольный анализ и обсуждение (как эксперт безопасности и эксперт производительности дебатируют подход)
- Нужна истинная параллельная разработка (фронтенд, бэкенд, тестирование одновременно)
- Между задачами требуется частая координация и обмен информацией

### Краткое резюме

- **Subagent**: инструмент для распределения задач, разбирает большую задачу на малые, и распределяет "рабочим" для завершения
- **Agent Teams**: настоящая совместная команда, члены могут общаться как настоящая команда, обсуждать, сотрудничать

---

## Основная архитектура

Agent Teams — это не просто функция "многозагрузки", а полная **многоагентная система сотрудничества**. Чтобы её понять, нам нужно знать её основные компоненты и как они сотрудничают.

### Состав команды

Agent Team состоит из четырёх основных компонентов, каждый из которых выполняет свою функцию и совместно выполняет сложные задачи.

**Team Lead (лидер команды)**

Team Lead — это "мозг" и "координатор" всей команды. Не выполняет непосредственно конкретные задачи кодирования, а отвечает за:

- **Анализ требований и разделение задач**: разбирает сложные требования пользователя на несколько параллельно выполняемых подзадач
- **Создание и управление командой**: на основе особенностей задачи определяет, сколько нужно членов, каковы обязанности каждого
- **Распределение и планирование задач**: распределяет задачи подходящим членам, управляет зависимостями задач
- **Синтез результатов и контроль качества**: собирает работу всех членов, интегрирует и проводит окончательную проверку

**Teammates (члены команды)**

Teammates — это "разработчики", которые выполняют реальную работу, каждый Teammate — это независимый экземпляр Claude:

- **Независимое окно контекста**: каждый член имеет полный контекстное окно в 200K токенов, полностью изолированный от Team Lead и других членов
- **Полные права на инструменты**: может использовать все инструменты — Read, Write, Edit, Bash и т.д.
- **Самостоятельное взятие задач**: может самостоятельно выбирать и браться за задачи из общей доски
- **Способность прямого общения**: может прямо общаться с другими членами, не обязательно через Team Lead

**TaskList (общая доска задач)**

TaskList — это "инструмент управления проектом" команды, похож на Jira или Trello:

- **Управление состоянием задач**: каждая задача имеет четкое состояние — pending (ожидающие), in_progress (в процессе), completed (завершённые)
- **Управление зависимостями**: задачи могут определять зависимости, только после завершения зависимой задачи, может начать зависимая
- **Автоматический механизм разблокировки**: когда задача завершена, система автоматически проверит и разблокирует задачи, ждущие её
- **Механизм блокировки файлов**: когда член берёт и начинает работать над задачей, в директории задачи создаётся файл блокировки, предотвращая одновременное изменение одного файла несколькими членами

**Messaging System (система сообщений)**

Система сообщений — это "инструмент чата" между членами команды:

- **Двусторонняя коммуникация**: член A может прямо отправить сообщение члену B
- **Массовая трансляция**: может одновременно отправить объявления всем членам
- **На базе файловой системы**: сообщения хранятся как JSON файлы в директории `~/.claude/teams/{team-name}/inboxes/`
- **Без необходимости сети**: полностью на базе локальной файловой системы, не требует сетевого подключения или прослушивания портов

### Процесс сотрудничества

Типичный рабочий процесс Agent Teams выглядит так:

```
Пользователь выдвигает сложное требование
       ↓
Team Lead анализирует требование, разбирает задачи
       ↓
Создаёт членов команды, инициализирует TaskList
       ↓
       ├─→ Teammate A берёт задачу 1 ─┐
       ├─→ Teammate B берёт задачу 2 ─┼→ Параллельное выполнение
       ├─→ Teammate C берёт задачу 3 ─┤
       │                           ↓
       └────────────────────────── Члены общаются через систему сообщений, координируются
                                   ↓
                          После завершения всех задач, Team Lead синтезирует результаты
                                   ↓
                          Выводит финальный результат пользователю
```

### Расположение файловой системы

Agent Teams создаёт специальные директории в локальной файловой системе для управления состоянием команды:

```
~/.claude/
├── teams/
│   └── {имя-команды}/
│       ├── config.json          # Конфигурация команды (список членов, выбор модели и т.д.)
│       └── inboxes/
│           ├── team-lead.json   # Входящие Team Lead
│           ├── teammate-1.json  # Входящие члена 1
│           └── teammate-2.json  # Входящие члена 2
└── tasks/
    └── {имя-команды}/
        ├── task-1.json          # Детальная информация задачи 1
        ├── task-2.json          # Детальная информация задачи 2
        └── current_tasks/
            └── parse_if_statement.txt  # Файл блокировки при выполнении задачи
```

Преимущество такого дизайна — **полная прозрачность** — вы в любой момент можете посмотреть состояние работы команды, ход выполнения задач, записи общения между членами.

---

## Быстрый старт

### Включение экспериментальной функции

Agent Teams в настоящее время — это **экспериментальная функция**, по умолчанию отключённая. Чтобы её использовать, нужно сначала включить.

**Самый простой способ: дать Claude Code включить**

Прямо в Claude Code введите:

```
Помогите мне включить функцию Agent Teams в settings.json
```

Или:

```
Включить экспериментальную функцию agentTeams
```

Claude Code автоматически изменит файл `~/.claude/settings.json`, добавив следующую конфигурацию:

```json
{
  "experimental": {
    "agentTeams": true
  }
}
```

**Перезагрузите Claude Code**

После конфигурирования **полностью выйдите и перезагрузите Claude Code**, функция будет работать.

**Ручная конфигурация (если автоматический метод не работает)**:

Вы можете ручной отредактировать файл `~/.claude/settings.json`, добавить или изменить:

```json
{
  "experimental": {
    "agentTeams": true
  }
}
```

**Проверка успешного включения**

После перезагрузки Claude Code вы можете попробовать такой разговор для проверки:

```
Вы: Можешь помочь мне создать Agent Team?

Claude: Конечно! Я могу помочь создать Agent Team для совместного завершения задач...
```

Если Claude может понять и ответить на запрос создания команды, это означает, что функция успешно включена.

### Конфигурация режима визуализации (опционально)

Если вы хотите видеть статус работы членов команды в реальном времени, можете конфигурировать **режим разбиения на несколько окон**.

**Дайте Claude Code конфигурировать**:

Прямо в Claude Code введите:

```
Помогите мне включить режим разбиения окон для Agent Teams в settings.json, используя tmux
```

Или:

```
Конфигурировать agent-teams использовать режим split-panes
```

**Установить tmux (если нету)**:

Если у вас нет tmux, можете дать Claude Code помочь установить:

```
Помогите мне установить tmux
```

Claude Code автоматически выполнит соответствующую команду установки для вашей ОС (macOS или Linux).

**Эффект после конфигурирования**:

После конфигурирования члены команды будут работать в разных окнах tmux, вы можете видеть выводы всех членов одновременно, как "стена мониторинга".

```
┌─────────────────┬─────────────────┬─────────────────┐
│  Teammate 1     │  Teammate 2     │  Teammate 3     │
│  Анализирует код│  Реализует API  │  Пишет тесты    │
│                 │                 │                 │
└─────────────────┴─────────────────┴─────────────────┘
```

**Ручная конфигурация (если автоматический метод не работает)**:

Вы можете ручной отредактировать файл `~/.claude/settings.json`:

```json
{
  "experimental": {
    "agentTeams": true
  },
  "agent-teams": {
    "displayMode": "split-panes",
    "terminalMultiplexer": "tmux"
  }
}
```

---

### Практический пример: разработка RPG игры в стиле Покемонов с помощью Agent Teams

Давайте через полный проект испытаем мощь Agent Teams. Этот пример покажет, как несколько членов AI команды сотрудничают, разрабатывая с нуля RPG игру с системой боя, диалогами и элементами исследования.

**Требования проекта**:

Разработать веб-RPG в стиле Покемонов с следующим функционалом:

- **Система персонажей**: игроки могут создать персонажа с уровнем, HP, силой атаки, защитой и прочими атрибутами
- **Система боя**: пошаговый бой с опциями атаки, умения, предметы, бегство
- **Система монстров**: множество дикого зверья с разными атрибутами и умениями
- **Система диалогов**: диалоги с NPC, боковые квесты
- **Исследование карты**: простая 2D карта, возможность движения между разными сценами
- **Система сохранения**: сохранение прогресса игры (уровень персонажа, позиция, завершённые квесты и т.д.)
- **Звуки и анимация**: визуальные эффекты и звуки атаки, получения урона, повышения уровня

**Введите в Claude Code**:

```
Я хочу разрабатывать веб-RPG в стиле Покемонов.

Создайте команду для совместной разработки:

Разделение обязанностей членов команды:
- Teammate A (архитектор игры): разработайте общую архитектуру, определите машину состояния игры, спланируйте структуру данных
- Teammate B (система боя): реализуйте логику пошагового боя, систему умений, расчёт урона
- Teammate C (система диалогов): реализуйте диалоги NPC, систему квестов, сценарий сюжета
- Teammate D (отрисовка карты): используйте Canvas для 2D отрисовки карты, движение персонажа, переход сцен
- Teammate E (UI и звуки): разработайте интерфейс игры, UI боя, воспроизведение звуков

Технические требования:
- Используйте React + TypeScript + Vite
- Используйте Tailwind CSS для стилей
- Используйте Framer Motion для анимации
- Используйте Zustand для управления состоянием
- Система пошагового боя
- Сохранение используйте localStorage
- Звуки используйте Web Audio API

Каждый член используйте модель Sonnet, Team Lead используйте Opus.

Сначала дайте архитектору разработать общий план, определить структуру данных, потом остальные члены начнут параллельную разработку.
```

**Как будет выполняться Claude**:

**Этап 1: Разработка архитектуры**

Team Lead сначала попросит Teammate A (архитектор игры) провести общую разработку:

```
Teammate A разрабатывает архитектуру игры...

Технический стек: React 18 + TypeScript + Vite + Tailwind CSS + Framer Motion + Zustand

Инициализация проекта:
npm create vite@latest pokemon-rpg -- --template react-ts
npm install zustand framer-motion
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

Структура файлов:
src/
├── App.tsx                 # основной компонент приложения
├── main.tsx                # файл входа
├── types/
│   ├── player.ts           # определения типов игрока
│   ├── monster.ts          # определения типов монстра
│   ├── skill.ts            # определения типов умения
│   └── game.ts             # определения типов состояния игры
├── stores/
│   └── gameStore.ts        # управление состоянием Zustand
├── components/
│   ├── map/                # компоненты карты
│   │   ├── MapCanvas.tsx   # Canvas карты
│   │   ├── PlayerSprite.tsx # спрайт игрока
│   │   └── NPCSprite.tsx   # спрайт NPC
│   ├── battle/             # компоненты боя
│   │   ├── BattleScreen.tsx    # экран боя
│   │   ├── BattleMenu.tsx      # меню боя
│   │   ├── HPBar.tsx           # компонент полоски HP
│   │   └── BattleLog.tsx       # журнал боя
│   ├── dialog/             # компоненты диалога
│   │   ├── DialogBox.tsx   # окно диалога
│   │   └── Choices.tsx     # компонент выбора
│   └── ui/                 # универсальные UI компоненты
│       ├── Button.tsx
│       ├── ProgressBar.tsx
│       └── StatCard.tsx
├── systems/
│   ├── BattleSystem.ts     # логика системы боя
│   ├── DialogSystem.ts     # логика системы диалога
│   ├── QuestSystem.ts      # логика системы квестов
│   └── MapSystem.ts        # логика системы карты
├── hooks/
│   ├── useBattle.ts        # Hook боя
│   ├── useDialog.ts        # Hook диалога
│   └── useAudio.ts         # Hook аудио
├── data/
│   ├── monsters.ts         # данные монстров
│   ├── skills.ts           # данные умений
│   ├── dialogues.ts        # сценарий диалогов
│   └── maps.ts             # данные карт
└── utils/
    ├── audio.ts            # инструменты аудио
    └── storage.ts          # инструменты сохранения

Проектирование основных структур данных:

// types/player.ts - тип игрока
interface Player {
  id: string;
  name: string;
  level: number;
  exp: number;
  maxExp: number;
  hp: number;
  maxHp: number;
  attack: number;
  defense: number;
  skills: Skill[];
  position: { x: number; y: number };
  direction: 'UP' | 'DOWN' | 'LEFT' | 'RIGHT';
  gold: number;
  items: string[];
}

// types/skill.ts - тип умения
interface Skill {
  id: string,
  name: string,
  type: 'attack' | 'heal' | 'buff' | 'special',
  power: number,
  accuracy: number,
  pp: number,
  maxPp: number,
  effect?: string
}

// Состояние игры
{
  screen: 'map' | 'battle' | 'dialog' | 'menu',
  player: Player,
  currentMap: string,
  position: {x: number, y: number},
  inBattle: boolean,
  dialogQueue: Array<Dialog>,
  gameData: {
    completedQuests: string[],
    items: string[],
    visitedMaps: string[]
  }
}

Проектирование системы боя:
- пошаговый бой, игрок действует первым
- каждый раунд можно выбрать: атаку, умение, предмет, бегство
- умения ограничены PP, требуют восстановления при использовании
- формула урона: (сила атаки атакующего / защита защищающегося) × мощность умения × случайный множитель(0.85~1.0)

Проектирование системы диалога:
- текст отображается эффектом печатной машинки
- поддержка ответов с ветвлением
- поддержка условного срабатывания (после завершения квеста)
- NPC имеют ориентацию, диалог автоматически срабатывает при приближении игрока
```

**Этап 2: Параллельная разработка**

После определения архитектуры, Team Lead создаёт список задач, остальные члены начинают параллельную работу:

```
Список задач:
├── [Teammate B] реализовать основную логику системы боя (в процессе...)
├── [Teammate C] реализовать систему диалогов и квестов (в процессе...)
├── [Teammate D] реализовать 2D отрисовку карты (в процессе...)
└── [Teammate E] разработать UI и звуки (в процессе...)
```

<details>
<summary>📁 Teammate B: основной код системы боя</summary>

```javascript
// battle.js - система боя
class BattleSystem {
  constructor(player, monster) {
    this.player = player;
    this.monster = monster;
    this.turn = 'player';
    this.log = [];
    this.state = 'active'; // active, victory, defeat, flee
  }

  // Атака игрока
  playerAttack(skill) {
    if (this.turn !== 'player') return;

    const damage = this.calculateDamage(this.player, this.monster, skill);
    this.monster.hp = Math.max(0, this.monster.hp - damage);

    this.log.push(`${this.player.name} использовал ${skill.name}!`);
    this.log.push(`Нанёс ${damage} урона!`);

    // Эффект умения
    if (skill.effect) {
      this.applyEffect(this.player, this.monster, skill.effect);
    }

    // Проверка завершения боя
    if (this.monster.hp <= 0) {
      this.state = 'victory';
      this.log.push(`${this.monster.name} упал!`);
      this.giveExp();
    } else {
      this.turn = 'monster';
      setTimeout(() => this.monsterAttack(), 1000);
    }
  }

  // Атака монстра
  monsterAttack() {
    if (this.state !== 'active') return;

    // Случайно выбрать умение
    const skill = this.monster.skills[Math.floor(Math.random() * this.monster.skills.length)];
    const damage = this.calculateDamage(this.monster, this.player, skill);

    this.player.hp = Math.max(0, this.player.hp - damage);

    this.log.push(`${this.monster.name} использовал ${skill.name}!`);
    this.log.push(`Нанёс ${damage} урона!`);

    if (this.player.hp <= 0) {
      this.state = 'defeat';
      this.log.push(`${this.player.name} упал...`);
    } else {
      this.turn = 'player';
    }
  }

  // Расчёт урона
  calculateDamage(attacker, defender, skill) {
    const levelFactor = (2 * attacker.level / 5 + 2);
    const attackDefense = attacker.attack / defender.defense;
    const baseDamage = levelFactor * attackDefense * skill.power + 2;
    const randomFactor = 0.85 + Math.random() * 0.15;

    // Бонус типа умения (упрощённая версия)
    let typeBonus = 1;
    // if (skill.type > defender.type) typeBonus = 1.5;

    return Math.floor(baseDamage * randomFactor * typeBonus);
  }

  // Применить эффект умения
  applyEffect(user, target, effect) {
    switch(effect) {
      case 'burn':
        this.log.push(`${target.name} получил ожог!`);
        break;
      case 'heal':
        const healAmount = Math.floor(user.maxHp * 0.3);
        user.hp = Math.min(user.maxHp, user.hp + healAmount);
        this.log.push(`${user.name} восстановил ${healAmount} HP!`);
        break;
      case 'buff':
        user.attack = Math.floor(user.attack * 1.2);
        this.log.push(`Сила атаки ${user.name} повысилась!`);
        break;
    }
  }

  // Получить опыт
  giveExp() {
    const baseExp = this.monster.level * 50;
    const expGain = Math.floor(baseExp * (1 + this.player.level / 10));

    this.player.exp += expGain;
    this.log.push(`${this.player.name} получил ${expGain} опыта!`);

    // Проверка повышения уровня
    while (this.player.exp >= this.player.maxExp) {
      this.levelUp();
    }
  }

  // Повышение уровня
  levelUp() {
    this.player.level++;
    this.player.exp -= this.player.maxExp;
    this.player.maxExp = Math.floor(this.player.maxExp * 1.5);

    // Повышение атрибутов
    const hpGain = 10 + Math.floor(Math.random() * 5);
    const atkGain = 3 + Math.floor(Math.random() * 2);
    const defGain = 2 + Math.floor(Math.random() * 2);

    this.player.maxHp += hpGain;
    this.player.hp = this.player.maxHp;
    this.player.attack += atkGain;
    this.player.defense += defGain;

    this.log.push(`${this.player.name} повысился до уровня ${this.player.level}!`);
    this.log.push(`HP +${hpGain}, Атака +${atkGain}, Защита +${defGain}`);
  }

  // Бегство
  flee() {
    if (Math.random() < 0.7) {
      this.state = 'flee';
      this.log.push('Успешно убежали!');
      return true;
    } else {
      this.log.push('Попытка побега не удалась!');
      this.turn = 'monster';
      setTimeout(() => this.monsterAttack(), 1000);
      return false;
    }
  }
}

// monster.js - данные монстров
const MONSTER_DATA = [
  {
    id: 'slime',
    name: 'Слизень',
    baseHp: 30,
    baseAtk: 8,
    baseDef: 5,
    skills: [
      {id: 'tackle', name: 'Бросок', type: 'attack', power: 40, accuracy: 100, pp: 35}
    ],
    expGain: 20
  },
  {
    id: 'goblin',
    name: 'Гоблин',
    baseHp: 45,
    baseAtk: 12,
    baseDef: 8,
    skills: [
      {id: 'tackle', name: 'Бросок', type: 'attack', power: 40, accuracy: 100, pp: 35},
      {id: 'scratch', name: 'Царапина', type: 'attack', power: 55, accuracy: 100, pp: 25}
    ],
    expGain: 35
  },
  {
    id: 'dragon',
    name: 'Молодой дракон',
    baseHp: 80,
    baseAtk: 20,
    baseDef: 15,
    skills: [
      {id: 'scratch', name: 'Царапина', type: 'attack', power: 55, accuracy: 100, pp: 25},
      {id: 'ember', name: 'Искра', type: 'attack', power: 70, accuracy: 90, pp: 15},
      {id: 'growl', name: 'Рычание', type: 'buff', power: 0, accuracy: 100, pp: 20}
    ],
    expGain: 80
  }
];
```

</details>

<details>
<summary>📁 Teammate C: код системы диалогов и квестов</summary>

```javascript
// dialog.js - система диалогов
class DialogSystem {
  constructor() {
    this.dialogQueue = [];
    this.currentDialog = null;
    this.isShowing = false;
    this.onComplete = null;
  }

  // Показать диалог
  showDialog(dialog, onComplete) {
    this.dialogQueue = Array.isArray(dialog) ? dialog : [dialog];
    this.onComplete = onComplete;
    this.isShowing = true;
    this.showNext();
  }

  // Показать следующий диалог
  showNext() {
    if (this.dialogQueue.length === 0) {
      this.isShowing = false;
      if (this.onComplete) this.onComplete();
      return;
    }

    this.currentDialog = this.dialogQueue.shift();

    // Обработка специальных типов диалогов
    if (typeof this.currentDialog === 'function') {
      this.currentDialog();
      this.showNext();
      return;
    }

    this.renderDialog();
  }

  // Отрисовать окно диалога
  renderDialog() {
    const dialogBox = document.getElementById('dialogBox');
    const speakerEl = document.getElementById('dialogSpeaker');
    const textEl = document.getElementById('dialogText');

    if (this.currentDialog.speaker) {
      speakerEl.textContent = this.currentDialog.speaker;
      speakerEl.style.display = 'block';
    } else {
      speakerEl.style.display = 'none';
    }

    // Эффект печатной машинки
    textEl.textContent = '';
    let i = 0;
    const text = this.currentDialog.text;
    const speed = this.currentDialog.speed || 30;

    const typeWriter = setInterval(() => {
      if (i < text.length) {
        textEl.textContent += text.charAt(i);
        i++;
      } else {
        clearInterval(typeWriter);
      }
    }, speed);

    // Показать выборы (если есть)
    this.renderChoices();
  }

  // Отрисовать выборы
  renderChoices() {
    if (!this.currentDialog.choices) return;

    const choicesEl = document.getElementById('dialogChoices');
    choicesEl.innerHTML = '';
    choicesEl.style.display = 'block';

    this.currentDialog.choices.forEach(choice => {
      const btn = document.createElement('button');
      btn.textContent = choice.text;
      btn.onclick = () => {
        if (choice.condition === undefined || choice.condition()) {
          this.dialogQueue = [];
          this.showDialog(choice.dialog, this.onComplete);
        }
      };
      choicesEl.appendChild(btn);
    });
  }

  // Далее
  next() {
    if (this.currentDialog && this.currentDialog.choices) return; // требуется выбор если есть опции
    this.showNext();
  }
}

// Система квестов
class QuestSystem {
  constructor() {
    this.quests = {};
    this.activeQuests = [];
    this.completedQuests = [];
  }

  // Принять квест
  acceptQuest(questId) {
    if (this.completedQuests.includes(questId)) return false;
    if (this.activeQuests.includes(questId)) return false;

    this.activeQuests.push(questId);
    return true;
  }

  // Обновить ход выполнения квеста
  updateProgress(type, target) {
    this.activeQuests.forEach(questId => {
      const quest = this.quests[questId];
      if (!quest) return;

      quest.objectives.forEach(obj => {
        if (obj.type === type && obj.target === target && !obj.completed) {
          obj.current = (obj.current || 0) + 1;
          if (obj.current >= obj.required) {
            obj.completed = true;
          }
        }
      });

      this.checkCompletion(questId);
    });
  }

  // Проверить завершение квеста
  checkCompletion(questId) {
    const quest = this.quests[questId];
    if (!quest) return;

    const allComplete = quest.objectives.every(obj => obj.completed);
    if (allComplete) {
      this.completeQuest(questId);
    }
  }

  // Завершить квест
  completeQuest(questId) {
    const index = this.activeQuests.indexOf(questId);
    if (index > -1) {
      this.activeQuests.splice(index, 1);
      this.completedQuests.push(questId);

      // Дать награду
      const quest = this.quests[questId];
      this.giveRewards(quest.rewards);
    }
  }

  // Дать награду
  giveRewards(rewards) {
    if (rewards.exp) player.gainExp(rewards.exp);
    if (rewards.gold) player.gold += rewards.gold;
    if (rewards.items) rewards.items.forEach(item => player.addItem(item));
  }
}

// dialogues.js - пример скрипта диалогов
const DIALOGUES = {
  villageChief: {
    firstMeeting: [
      {speaker: 'Вождь деревни', text: 'О, авантюрист... ты наконец-то пришёл.'},
      {speaker: 'Вождь деревни', text: 'Рядом с нашей деревней в последнее время появилось много диких монстров, жители нас очень пугают.'},
      {speaker: 'Вождь деревни', text: 'Если ты поможешь прогнать этих монстров, я буду тебе бесконечно благодарен!'},
      {
        choices: [
          {text: 'Ладно, я принимаю эту задачу', dialog: () => {
            quests.acceptQuest('defeatMonsters');
            return [
              {speaker: 'Вождь деревни', text: 'Спасибо! Пожалуйста, победи 3 Слизня на севере.'},
              {speaker: 'Система', text: 'Квест [Прогнать слизней] принят!'}
            ];
          }},
          {text: 'Я сейчас занят', dialog: [
            {speaker: 'Вождь деревни', text: 'Ладно, когда будешь готов, приходи ко мне.'}
          ]}
        ]
      }
    ],
    afterQuest: [
      {speaker: 'Вождь деревни', text: 'Ты действительно это сделал! Спасибо огромное!'},
      {speaker: 'Система', text: 'Квест [Прогнать слизней] завершён! Получено 100 опыта!'},
      {speaker: 'Вождь деревни', text: 'Пожалуйста, прими это как выражение моей благодарности.'}
    ]
  },

  shopkeeper: [
    {speaker: 'Хозяин магазина', text: 'Добро пожаловать! Что-то интересует?'},
    {
      choices: [
        {text: 'Посмотреть товары', dialog: () => {
          game.openShop();
          return [{speaker: 'Хозяин магазина', text: 'Выбирай что хочешь!'}];
        }},
        {text: 'Уйти', dialog: [{speaker: 'Хозяин магазина', text: 'До встречи!'}]}
      ]
    }
  ]
};
```

</details>

<details>
<summary>📁 Teammate D: код системы 2D отрисовки карты</summary>

```javascript
// map.js - система отрисовки карты
class MapRenderer {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.tileSize = 32;
    this.currentMap = null;
    this.player = null;
    this.npcs = [];
    this.camera = {x: 0, y: 0};
  }

  // Загрузить карту
  loadMap(mapData) {
    this.currentMap = mapData;
    this.npcs = mapData.npcs || [];
    this.updateCamera();
  }

  // Отрисовать карту
  render() {
    if (!this.currentMap) return;

    // Очистить холст
    this.ctx.fillStyle = '#000';
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);

    // Сохранить контекст
    this.ctx.save();

    // Применить смещение камеры
    this.ctx.translate(-this.camera.x, -this.camera.y);

    // Отрисовать слои карты
    this.renderLayers();

    // Отрисовать NPC
    this.renderNPCs();

    // Отрисовать игрока
    this.renderPlayer();

    // Восстановить контекст
    this.ctx.restore();
  }

  // Отрисовать слои карты
  renderLayers() {
    const map = this.currentMap;

    for (let layer = 0; layer < map.layers.length; layer++) {
      const data = map.layers[layer].data;

      for (let y = 0; y < map.height; y++) {
        for (let x = 0; x < map.width; x++) {
          const tileId = data[y * map.width + x];
          if (tileId === 0) continue;

          const tileX = x * this.tileSize;
          const tileY = y * this.tileSize;

          this.renderTile(tileX, tileY, tileId);
        }
      }
    }
  }

  // Отрисовать отдельный блок
  renderTile(x, y, tileId) {
    // Отрисовать разные блоки на основе ID
    const tileType = this.getTileType(tileId);

    switch(tileType) {
      case 'grass':
        this.ctx.fillStyle = '#4a8f4a';
        this.ctx.fillRect(x, y, this.tileSize, this.tileSize);
        // Текстура травы
        this.ctx.fillStyle = '#3d7f3d';
        for (let i = 0; i < 3; i++) {
          const px = x + Math.random() * this.tileSize;
          const py = y + Math.random() * this.tileSize;
          this.ctx.fillRect(px, py, 2, 2);
        }
        break;

      case 'water':
        this.ctx.fillStyle = '#4a90d9';
        this.ctx.fillRect(x, y, this.tileSize, this.tileSize);
        // Эффект волн воды
        const wave = Math.sin(Date.now() / 500 + x / 20) * 2;
        this.ctx.fillStyle = '#5aa0e9';
        this.ctx.fillRect(x, y + 10 + wave, this.tileSize, 2);
        break;

      case 'wall':
        this.ctx.fillStyle = '#8b7355';
        this.ctx.fillRect(x, y, this.tileSize, this.tileSize);
        this.ctx.fillStyle = '#7a6248';
        this.ctx.fillRect(x + 2, y + 2, this.tileSize - 4, this.tileSize - 4);
        break;

      case 'path':
        this.ctx.fillStyle = '#c4a77d';
        this.ctx.fillRect(x, y, this.tileSize, this.tileSize);
        break;

      case 'house':
        this.ctx.fillStyle = '#a0522d';
        this.ctx.fillRect(x, y, this.tileSize, this.tileSize);
        // Крыша
        this.ctx.fillStyle = '#8b4513';
        this.ctx.beginPath();
        this.ctx.moveTo(x, y);
        this.ctx.lineTo(x + this.tileSize / 2, y - 10);
        this.ctx.lineTo(x + this.tileSize, y);
        this.ctx.fill();
        break;
    }
  }

  // Получить тип блока
  getTileType(tileId) {
    const types = {
      1: 'grass', 2: 'water', 3: 'wall', 4: 'path', 5: 'house'
    };
    return types[tileId] || 'grass';
  }

  // Отрисовать NPC
  renderNPCs() {
    this.npcs.forEach(npc => {
      const x = npc.x * this.tileSize;
      const y = npc.y * this.tileSize;

      // Отрисовать NPC
      this.ctx.fillStyle = npc.color || '#ff6b6b';
      this.ctx.beginPath();
      this.ctx.arc(
        x + this.tileSize / 2,
        y + this.tileSize / 2,
        this.tileSize / 3,
        0,
        Math.PI * 2
      );
      this.ctx.fill();

      // Отрисовать имя
      this.ctx.fillStyle = '#fff';
      this.ctx.font = '10px Arial';
      this.ctx.textAlign = 'center';
      this.ctx.fillText(npc.name, x + this.tileSize / 2, y - 5);
    });
  }

  // Отрисовать игрока
  renderPlayer() {
    if (!this.player) return;

    const x = this.player.x * this.tileSize;
    const y = this.player.y * this.tileSize;

    // Тело игрока
    this.ctx.fillStyle = '#4ecdc4';
    this.ctx.beginPath();
    this.ctx.arc(
      x + this.tileSize / 2,
      y + this.tileSize / 2,
      this.tileSize / 3,
      0,
      Math.PI * 2
    );
    this.ctx.fill();

    // Индикатор направления игрока
    const directions = {UP: [0, -8], DOWN: [0, 8], LEFT: [-8, 0], RIGHT: [8, 0]};
    const [dx, dy] = directions[this.player.direction] || [0, 0];

    this.ctx.fillStyle = '#2d3436';
    this.ctx.beginPath();
    this.ctx.arc(
      x + this.tileSize / 2 + dx,
      y + this.tileSize / 2 + dy,
      4,
      0,
      Math.PI * 2
    );
    this.ctx.fill();
  }

  // Обновить позицию камеры
  updateCamera() {
    if (!this.player) return;

    // Камера следит за игроком, держит его в центре экрана
    const targetX = this.player.x * this.tileSize - this.canvas.width / 2;
    const targetY = this.player.y * this.tileSize - this.canvas.height / 2;

    // Плавное движение
    this.camera.x += (targetX - this.camera.x) * 0.1;
    this.camera.y += (targetY - this.camera.y) * 0.1;

    // Ограничить камеру, чтобы не выходить за границы карты
    const maxX = this.currentMap.width * this.tileSize - this.canvas.width;
    const maxY = this.currentMap.height * this.tileSize - this.canvas.height;
    this.camera.x = Math.max(0, Math.min(this.camera.x, maxX));
    this.camera.y = Math.max(0, Math.min(this.camera.y, maxY));
  }

  // Проверить столкновение
  checkCollision(x, y) {
    // Проверить границы карты
    if (x < 0 || x >= this.currentMap.width || y < 0 || y >= this.currentMap.height) {
      return true;
    }

    // Проверить столкновение блоков
    const tileId = this.currentMap.layers[0].data[y * this.currentMap.width + x];
    const solidTiles = [3, 5]; // Стены и дома — препятствия

    if (solidTiles.includes(tileId)) {
      return true;
    }

    // Проверить столкновение с NPC
    for (const npc of this.npcs) {
      if (npc.x === x && npc.y === y) {
        // Вызвать диалог NPC
        this.triggerNPC(npc);
        return true;
      }
    }

    return false;
  }

  // Вызвать диалог NPC
  triggerNPC(npc) {
    if (npc.dialogue) {
      game.dialogSystem.showDialog(npc.dialogue);
    }
  }
}

// Пример данных карты
const VILLAGE_MAP = {
  name: 'Деревня новичков',
  width: 20,
  height: 15,
  layers: [
    {
      name: 'ground',
      data: [
        // Данные карты (упрощённое отображение)
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,4,4,4,1,1,5,5,5,1,1,4,4,4,4,1,1,1,1,1,
        1,4,1,4,1,1,5,5,5,1,1,4,1,1,4,1,1,1,1,1,
        1,4,4,4,1,1,1,1,1,1,1,4,4,4,4,1,2,2,1,1,
        1,1,1,1,1,1,4,4,4,1,1,1,1,1,1,1,2,2,1,1,
        1,4,4,4,1,1,4,4,4,1,1,1,1,1,1,1,2,2,1,1,
        1,4,1,4,1,1,1,1,1,1,1,4,4,4,1,1,1,1,1,1,
        1,4,4,4,1,1,1,1,1,1,1,4,1,1,4,1,1,1,1,1,
        // ... больше данных карты
      ]
    }
  ],
  npcs: [
    {
      id: 'village_chief',
      name: 'Вождь деревни',
      x: 5,
      y: 5,
      color: '#ffd93d',
      dialogue: DIALOGUES.villageChief.firstMeeting,
      direction: 'DOWN'
    },
    {
      id: 'shopkeeper',
      name: 'Хозяин магазина',
      x: 15,
      y: 8,
      color: '#6bcf7f',
      dialogue: DIALOGUES.shopkeeper,
      direction: 'DOWN'
    }
  ],
  exits: [
    {x: 10, y: 0, to: 'forest_map', spawnX: 5, spawnY: 14}
  ]
};
```

</details>

<details>
<summary>📁 Teammate E: код интерфейса боя</summary>

```html
<!-- HTML интерфейса боя -->
<div id="battleScreen" class="screen hidden">
  <!-- Область врага -->
  <div class="enemy-area">
    <div class="monster-sprite">
      <canvas id="monsterSprite" width="128" height="128"></canvas>
    </div>
    <div class="monster-info">
      <div class="name" id="enemyName">Слизень</div>
      <div class="level">Уровень <span id="enemyLevel">3</span></div>
      <div class="hp-bar">
        <div class="hp-fill" id="enemyHpBar" style="width: 100%"></div>
      </div>
      <div class="hp-text">
        <span id="enemyHp">30</span> / <span id="enemyMaxHp">30</span>
      </div>
    </div>
  </div>

  <!-- Область игрока -->
  <div class="player-area">
    <div class="player-info">
      <div class="name" id="playerName">Герой</div>
      <div class="level">Уровень <span id="playerLevel">5</span></div>
      <div class="hp-bar">
        <div class="hp-fill" id="playerHpBar" style="width: 80%"></div>
      </div>
      <div class="hp-text">
        <span id="playerHp">80</span> / <span id="playerMaxHp">100</span>
      </div>
      <div class="exp-bar">
        <div class="exp-fill" id="expBar" style="width: 60%"></div>
      </div>
    </div>
    <div class="player-sprite">
      <canvas id="playerSprite" width="128" height="128"></canvas>
    </div>
  </div>

  <!-- Меню боя -->
  <div class="battle-menu" id="battleMenu">
    <div class="menu-row">
      <button class="menu-btn" data-action="attack">Атака</button>
      <button class="menu-btn" data-action="skills">Умения</button>
      <button class="menu-btn" data-action="items">Предметы</button>
      <button class="menu-btn" data-action="flee">Бегство</button>
    </div>
  </div>

  <!-- Подменю умений -->
  <div class="submenu hidden" id="skillsMenu">
    <div class="submenu-title">Выбери умение</div>
    <div class="submenu-list" id="skillsList"></div>
    <button class="back-btn" onclick="hideSubmenu()">Назад</button>
  </div>

  <!-- Журнал боя -->
  <div class="battle-log">
    <div id="battleLog"></div>
  </div>
</div>
```

```css
/* battle.css - стили интерфейса боя */
.battle-screen {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(180deg, #87ceeb 0%, #e0f7fa 50%, #4a5568 50%, #2d3748 100%);
  display: flex;
  flex-direction: column;
}

.enemy-area {
  flex: 1;
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 40px;
}

.monster-sprite canvas {
  image-rendering: pixelated;
  filter: drop-shadow(0 4px 8px rgba(0,0,0,0.3));
  animation: float 2s ease-in-out infinite;
}

@keyframes float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
}

.monster-info {
  margin-left: 40px;
  text-align: center;
}

.monster-info .name {
  font-size: 24px;
  font-weight: bold;
  color: #2d3748;
}

.monster-info .level {
  font-size: 14px;
  color: #718096;
  margin: 8px 0;
}

.hp-bar {
  width: 200px;
  height: 20px;
  background: #e2e8f0;
  border-radius: 10px;
  overflow: hidden;
  border: 2px solid #4a5568;
}

.hp-fill {
  height: 100%;
  background: linear-gradient(90deg, #48bb78, #38a169);
  transition: width 0.3s ease;
}

.hp-text {
  margin-top: 8px;
  font-size: 14px;
  color: #4a5568;
}

.player-area {
  flex: 1;
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  padding: 40px;
}

.player-info {
  background: rgba(255,255,255,0.9);
  border-radius: 12px;
  padding: 20px;
  border: 3px solid #4a5568;
}

.exp-bar {
  width: 200px;
  height: 8px;
  background: #e2e8f0;
  border-radius: 4px;
  margin-top: 8px;
}

.exp-fill {
  height: 100%;
  background: linear-gradient(90deg, #4299e1, #3182ce);
  border-radius: 4px;
}

.battle-menu {
  background: rgba(255,255,255,0.95);
  border: 3px solid #4a5568;
  border-radius: 12px;
  padding: 20px;
  margin: 0 40px 40px;
}

.menu-row {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
}

.menu-btn {
  padding: 16px 24px;
  font-size: 18px;
  font-weight: bold;
  background: linear-gradient(180deg, #fff 0%, #e2e8f0 100%);
  border: 2px solid #4a5568;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.menu-btn:hover {
  background: linear-gradient(180deg, #4299e1 0%, #3182ce 100%);
  color: white;
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.2);
}

.battle-log {
  position: absolute;
  bottom: 120px;
  left: 40px;
  right: 40px;
  max-height: 100px;
  overflow-y: auto;
  background: rgba(0,0,0,0.7);
  border-radius: 8px;
  padding: 12px;
}

#battleLog {
  color: #fff;
  font-size: 14px;
  line-height: 1.8;
}

.log-entry {
  margin-bottom: 4px;
  opacity: 0;
  animation: fadeIn 0.3s forwards;
}

@keyframes fadeIn {
  to { opacity: 1; }
}

/* Анимация получения урона */
@keyframes shake {
  0%, 100% { transform: translateX(0); }
  25% { transform: translateX(-5px); }
  75% { transform: translateX(5px); }
}

.shake {
  animation: shake 0.3s ease-in-out;
}

/* Анимация атаки */
@keyframes attackRight {
  0% { transform: translateX(0); }
  50% { transform: translateX(30px); }
  100% { transform: translateX(0); }
}

.attack-right {
  animation: attackRight 0.3s ease-in-out;
}
```

</details>

<details>
<summary>📁 Код аудиосистемы</summary>

```javascript
// audio.js - аудиосистема
class AudioManager {
  constructor() {
    this.audioContext = null;
    this.sounds = {};
    this.musicVolume = 0.3;
    this.sfxVolume = 0.5;
    this.currentBgm = null;
  }

  // Инициализировать аудиоконтекст
  init() {
    if (!this.audioContext) {
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
    }
    if (this.audioContext.state === 'suspended') {
      this.audioContext.resume();
    }
  }

  // Воспроизвести фоновую музыку
  playBgm(bgmName) {
    if (this.currentBgm === bgmName) return;

    this.stopBgm();

    // Использовать осциллятор для создания простой BGM
    this.currentBgm = bgmName;
    this.playGeneratedBgm(bgmName);
  }

  // Создать простую фоновую музыку
  playGeneratedBgm(type) {
    const melodies = {
      battle: [262, 294, 330, 262, 294, 330, 349, 330],
      village: [330, 349, 392, 349, 330, 294, 262, 294],
      victory: [392, 440, 494, 523, 494, 440, 392, 349]
    };

    const melody = melodies[type] || melodies.village;
    let noteIndex = 0;

    const playNote = () => {
      if (this.currentBgm !== type) return;

      const osc = this.audioContext.createOscillator();
      const gain = this.audioContext.createGain();

      osc.connect(gain);
      gain.connect(this.audioContext.destination);

      osc.frequency.value = melody[noteIndex];
      osc.type = 'triangle';

      gain.gain.setValueAtTime(this.musicVolume, this.audioContext.currentTime);
      gain.gain.exponentialRampToValueAtTime(
        0.01,
        this.audioContext.currentTime + 0.4
      );

      osc.start(this.audioContext.currentTime);
      osc.stop(this.audioContext.currentTime + 0.4);

      noteIndex = (noteIndex + 1) % melody.length;
      setTimeout(playNote, 500);
    };

    playNote();
  }

  // Остановить фоновую музыку
  stopBgm() {
    this.currentBgm = null;
  }

  // Воспроизвести звуковой эффект
  playSfx(sfxName) {
    this.init();

    switch(sfxName) {
      case 'attack':
        this.playAttackSound();
        break;
      case 'hit':
        this.playHitSound();
        break;
      case 'victory':
        this.playVictorySound();
        break;
      case 'levelup':
        this.playLevelUpSound();
        break;
      case 'dialog':
        this.playDialogSound();
        break;
    }
  }

  // Звук атаки
  playAttackSound() {
    const osc = this.audioContext.createOscillator();
    const gain = this.audioContext.createGain();

    osc.connect(gain);
    gain.connect(this.audioContext.destination);

    osc.frequency.setValueAtTime(200, this.audioContext.currentTime);
    osc.frequency.exponentialRampToValueAtTime(
      100,
      this.audioContext.currentTime + 0.1
    );
    osc.type = 'sawtooth';

    gain.gain.setValueAtTime(this.sfxVolume, this.audioContext.currentTime);
    gain.gain.exponentialRampToValueAtTime(
      0.01,
      this.audioContext.currentTime + 0.1
    );

    osc.start(this.audioContext.currentTime);
    osc.stop(this.audioContext.currentTime + 0.1);
  }

  // Звук получения урона
  playHitSound() {
    const osc = this.audioContext.createOscillator();
    const gain = this.audioContext.createGain();

    osc.connect(gain);
    gain.connect(this.audioContext.destination);

    osc.frequency.value = 100;
    osc.type = 'square';

    gain.gain.setValueAtTime(this.sfxVolume * 0.8, this.audioContext.currentTime);
    gain.gain.exponentialRampToValueAtTime(
      0.01,
      this.audioContext.currentTime + 0.2
    );

    osc.start(this.audioContext.currentTime);
    osc.stop(this.audioContext.currentTime + 0.2);
  }

  // Звук победы
  playVictorySound() {
    const notes = [523, 659, 784, 1047];
    notes.forEach((freq, i) => {
      setTimeout(() => {
        const osc = this.audioContext.createOscillator();
        const gain = this.audioContext.createGain();

        osc.connect(gain);
        gain.connect(this.audioContext.destination);

        osc.frequency.value = freq;
        osc.type = 'sine';

        gain.gain.setValueAtTime(this.sfxVolume, this.audioContext.currentTime);
        gain.gain.exponentialRampToValueAtTime(
          0.01,
          this.audioContext.currentTime + 0.5
        );

        osc.start(this.audioContext.currentTime);
        osc.stop(this.audioContext.currentTime + 0.5);
      }, i * 150);
    });
  }

  // Звук повышения уровня
  playLevelUpSound() {
    const notes = [392, 523, 659, 784, 1047];
    notes.forEach((freq, i) => {
      setTimeout(() => {
        const osc = this.audioContext.createOscillator();
        const gain = this.audioContext.createGain();

        osc.connect(gain);
        gain.connect(this.audioContext.destination);

        osc.frequency.value = freq;
        osc.type = 'triangle';

        gain.gain.setValueAtTime(this.sfxVolume, this.audioContext.currentTime);
        gain.gain.exponentialRampToValueAtTime(
          0.01,
          this.audioContext.currentTime + 0.3
        );

        osc.start(this.audioContext.currentTime);
        osc.stop(this.audioContext.currentTime + 0.3);
      }, i * 100);
    });
  }

  // Звук диалога
  playDialogSound() {
    const osc = this.audioContext.createOscillator();
    const gain = this.audioContext.createGain();

    osc.connect(gain);
    gain.connect(this.audioContext.destination);

    osc.frequency.value = 800;
    osc.type = 'sine';

    gain.gain.setValueAtTime(this.sfxVolume * 0.3, this.audioContext.currentTime);
    gain.gain.exponentialRampToValueAtTime(
      0.01,
      this.audioContext.currentTime + 0.05
    );

    osc.start(this.audioContext.currentTime);
    osc.stop(this.audioContext.currentTime + 0.05);
  }
}
```

</details>

**Диалоги сотрудничества между членами**:

```
Teammate B → Teammate C:
"Система боя завершена, когда игрок побеждает, вызывается метод giveExp() для повышения уровня.
Проверь систему квестов, убедись, что повышение уровня правильно сохраняется."

Teammate C → Teammate B:
"Получено. Система квестов использует localStorage для сохранения данных игры,
включая уровень, опыт, список завершённых квестов и т.д. Я добавлю механизм автосохранения."

Teammate D → All:
"Система отрисовки карты завершена, данные ориентации NPC уже подключены к системе диалогов.
При приближении игрока к NPC диалог автоматически срабатывает, проверьте логику срабатывания диалога."

Teammate C → Teammate D:
"Проверено. DialogSystem имеет метод showDialog(), может принять массив диалогов,
убедюсь, что все данные диалогов NPC в этом формате."

Teammate E → Teammate B:
"UI боя готов, но нужны данные игрока и монстра в реальном времени для обновления полоски HP.
Система боя предоставляет callback функции?"

Teammate B → Teammate E:
"Да. BattleSystem имеет callback onUpdate, срабатывает в конце каждого раунда.
Можешь зарегистрировать этот callback для обновления UI."

Teammate E → Teammate D:
"При переключении карты нужно пересчитать позицию камеры.
MapRenderer имеет метод updateCamera()?"

Teammate D → Teammate E:
"Есть. Автоматически вызывается после каждого loadMap().
Также можешь вручную вызвать его после движения игрока для плавного движения камеры."
```

**Этап 3: интеграция и тестирование**

После завершения всех компонентов Team Lead отвечает за интеграцию:

<details>
<summary>📁 Основной контроллер игры</summary>

```javascript
// game.js - основной контроллер игры
class Game {
  constructor() {
    this.state = 'map'; // map, battle, dialog, menu
    this.canvas = document.getElementById('gameCanvas');
    this.ctx = this.canvas.getContext('2d');

    // Инициализировать системы
    this.player = this.createPlayer();
    this.mapRenderer = new MapRenderer(this.canvas);
    this.battleSystem = null;
    this.dialogSystem = new DialogSystem();
    this.questSystem = new QuestSystem();
    this.audioManager = new AudioManager();

    // Загрузить карту
    this.currentMapId = 'village';
    this.mapRenderer.loadMap(VILLAGE_MAP);
    this.mapRenderer.player = this.player;

    // Обработка ввода
    this.setupInput();

    // Запустить игровой цикл
    this.lastTime = 0;
    this.gameLoop = this.gameLoop.bind(this);
    requestAnimationFrame(this.gameLoop);

    // Автоматическое загрузка сохранённых данных
    this.loadGame();
  }

  // Создать игрока
  createPlayer() {
    return {
      name: 'Герой',
      level: 1,
      exp: 0,
      maxExp: 100,
      hp: 50,
      maxHp: 50,
      attack: 15,
      defense: 10,
      skills: [
        {id: 'tackle', name: 'Бросок', type: 'attack', power: 40, accuracy: 100, pp: 35}
      ],
      x: 10,
      y: 7,
      direction: 'DOWN',
      gold: 100,
      items: ['potion', 'potion', 'antidote']
    };
  }

  // Настроить обработку ввода
  setupInput() {
    document.addEventListener('keydown', (e) => {
      if (this.state === 'map') {
        this.handleMapInput(e);
      } else if (this.state === 'dialog') {
        this.handleDialogInput(e);
      } else if (this.state === 'battle') {
        this.handleBattleInput(e);
      }
    });
  }

  // Обработка ввода на карте
  handleMapInput(e) {
    if (this.dialogSystem.isShowing) {
      if (e.key === ' ' || e.key === 'Enter') {
        this.dialogSystem.next();
      }
      return;
    }

    let dx = 0, dy = 0;
    switch(e.key) {
      case 'ArrowUp': case 'w': dy = -1; this.player.direction = 'UP'; break;
      case 'ArrowDown': case 's': dy = 1; this.player.direction = 'DOWN'; break;
      case 'ArrowLeft': case 'a': dx = -1; this.player.direction = 'LEFT'; break;
      case 'ArrowRight': case 'd': dx = 1; this.player.direction = 'RIGHT'; break;
      default: return;
    }

    const newX = this.player.x + dx;
    const newY = this.player.y + dy;

    if (!this.mapRenderer.checkCollision(newX, newY)) {
      this.player.x = newX;
      this.player.y = newY;
      this.mapRenderer.updateCamera();

      // Проверить случайный бой
      if (Math.random() < 0.05) {
        this.startBattle();
      }

      // Сохранить игру
      this.saveGame();
    }
  }

  // Обработка ввода диалога
  handleDialogInput(e) {
    if (e.key === ' ' || e.key === 'Enter') {
      this.dialogSystem.next();
      if (!this.dialogSystem.isShowing) {
        this.state = 'map';
      }
    }
  }

  // Обработка ввода боя
  handleBattleInput(e) {
    if (!this.battleSystem) return;
    if (this.battleSystem.turn !== 'player') return;
  }

  // Начать бой
  startBattle(monsterData) {
    // Случайно выбрать монстра
    const randomMonster = MONSTER_DATA[Math.floor(Math.random() * MONSTER_DATA.length)];

    // Создать экземпляр монстра
    const monster = {
      ...randomMonster,
      level: Math.max(1, this.player.level + Math.floor(Math.random() * 3) - 1),
      hp: randomMonster.baseHp + randomMonster.baseHp * 0.2 * this.player.level,
      maxHp: randomMonster.baseHp + randomMonster.baseHp * 0.2 * this.player.level,
      attack: randomMonster.baseAtk + randomMonster.baseAtk * 0.15 * this.player.level,
      defense: randomMonster.baseDef + randomMonster.baseDef * 0.1 * this.player.level
    };

    this.battleSystem = new BattleSystem(this.player, monster);
    this.state = 'battle';

    // Воспроизвести музыку боя
    this.audioManager.playBgm('battle');

    // Показать экран боя
    document.getElementById('battleScreen').classList.remove('hidden');
    document.getElementById('mapScreen').classList.add('hidden');

    // Обновить UI боя
    this.updateBattleUI();
  }

  // Обновить UI боя
  updateBattleUI() {
    if (!this.battleSystem) return;

    const player = this.battleSystem.player;
    const monster = this.battleSystem.monster;

    document.getElementById('playerName').textContent = player.name;
    document.getElementById('playerLevel').textContent = player.level;
    document.getElementById('playerHp').textContent = Math.floor(player.hp);
    document.getElementById('playerMaxHp').textContent = player.maxHp;
    document.getElementById('playerHpBar').style.width =
      (player.hp / player.maxHp * 100) + '%';

    document.getElementById('enemyName').textContent = monster.name;
    document.getElementById('enemyLevel').textContent = monster.level;
    document.getElementById('enemyHp').textContent = Math.floor(monster.hp);
    document.getElementById('enemyMaxHp').textContent = Math.floor(monster.maxHp);
    document.getElementById('enemyHpBar').style.width =
      (monster.hp / monster.maxHp * 100) + '%';

    // Обновить журнал боя
    const logEl = document.getElementById('battleLog');
    this.battleSystem.log.forEach(log => {
      const entry = document.createElement('div');
      entry.className = 'log-entry';
      entry.textContent = log;
      logEl.appendChild(entry);
    });
    logEl.scrollTop = logEl.scrollHeight;
  }

  // Завершить бой
  endBattle() {
    this.state = 'map';
    this.battleSystem = null;

    // Скрыть экран боя
    document.getElementById('battleScreen').classList.add('hidden');
    document.getElementById('mapScreen').classList.remove('hidden');

    // Воспроизвести музыку карты
    this.audioManager.playBgm('village');

    // Сохранить игру
    this.saveGame();
  }

  // Сохранить игру
  saveGame() {
    const saveData = {
      player: this.player,
      currentMapId: this.currentMapId,
      completedQuests: this.questSystem.completedQuests,
      timestamp: Date.now()
    };

    localStorage.setItem('rpgSave', JSON.stringify(saveData));
  }

  // Загрузить игру
  loadGame() {
    const saveData = localStorage.getItem('rpgSave');
    if (saveData) {
      const data = JSON.parse(saveData);
      this.player = {...this.player, ...data.player};
      this.questSystem.completedQuests = data.completedQuests || [];
      this.currentMapId = data.currentMapId || 'village';
    }
  }

  // Основной игровой цикл
  gameLoop(timestamp) {
    const deltaTime = timestamp - this.lastTime;
    this.lastTime = timestamp;

    // Очистить холст
    this.ctx.fillStyle = '#000';
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);

    // Отрисовать в зависимости от состояния
    if (this.state === 'map') {
      this.mapRenderer.render();
    }

    requestAnimationFrame(this.gameLoop);
  }
}

// Запустить игру
window.addEventListener('DOMContentLoaded', () => {
  window.game = new Game();
});
```

</details>

**Финальный результат**:

Примерно через 1-2 часа полнофункциональная RPG игра в стиле Покемонов готова!

```
Резюме завершения проекта:
✅ Разработка архитектуры игры - Teammate A
✅ Система пошагового боя - Teammate B
✅ Система диалогов и квестов - Teammate C
✅ 2D отрисовка карты - Teammate D
✅ UI интерфейс и звуки - Teammate E

Файлы проекта:
├── index.html (120 строк)
├── css/
│   ├── main.css (100 строк)
│   ├── battle.css (180 строк)
│   └── dialog.css (80 строк)
├── js/
│   ├── game.js (250 строк)
│   ├── state.js (60 строк)
│   ├── player.js (50 строк)
│   ├── monster.js (80 строк)
│   ├── battle.js (220 строк)
│   ├── dialog.js (180 строк)
│   ├── map.js (280 строк)
│   └── audio.js (150 строк)
└── data/
    ├── monsters.js (100 строк)
    ├── skills.js (80 строк)
    └── dialogues.js (120 строк)

Итого: примерно 2050 строк кода, завершено 5 членами AI команды!

Функции игры:
🎮 Система пошагового боя (атака, умения, предметы, бегство)
💬 Система диалогов с NPC (эффект печатной машинки, ветвления выборов)
📜 Система квестов (прием, обновление, завершение с наградами)
🗺️ Исследование 2D карты (переключение сцен, взаимодействие с NPC)
💾 Автосохранение (сохранение прогресса через localStorage)
🔊 Звуки и BGM (Web Audio API)
📊 Рост персонажа (опыт, повышение уровня, повышение атрибутов)
```

**Наблюдение за работой команды**:

Если вы настроили режим разбиения окон tmux, вы увидите несколько окон терминала, работающих одновременно:

```
┌─────────────────┬─────────────────┬─────────────────┐
│  Teammate B     │  Teammate C     │  Teammate D     │
│  Реализует      │  Пишет диалоги  │  Отрисовывает   │
│  формулу урона  │  ...            │  блоки...       │
│                 │                 │                 │
│  "Teammate E,   │  "MapRenderer   │  "Монстр нужно  │
│   ширина        │   готов?"       │   анимацию      │
│   полоски HP    │                 │   атаки..."     │
│   процент?"     │                 │                 │
└─────────────────┴─────────────────┴─────────────────┘
```

**Ключевые выводы**:

Этот практический пример демонстрирует несколько основных преимуществ Agent Teams:

1. **Истинная параллельная разработка**: 5 членов одновременно разрабатывают разные системы игры
2. **Управление сложным проектом**: 2000+ строк кода разумно разделены и интегрированы
3. **Профессиональное разделение обязанностей**: боевая система, диалоги, карта, UI — каждая у эксперта
4. **Координация интерфейсов**: члены согласовывают интерфейсы и форматы данных через систему сообщений
5. **Быстрая доставка**: работа, которая раньше требовала недель для одного человека, команда завершает за часы

Вы можете попробовать запустить эту игру и испытать мощь AI командной разработки в стиле Покемонов!

---

## Система координации дел

Как работают задачи в Agent Teams и как они помогают организовать работу команды.

### Типы задач

Agent Teams различает несколько типов задач в зависимости от их назначения:

**Задачи для члена команды** (Teammate Task)

> **Описание**: это задачи, которые член команды выполняет независимо

> **Примеры**: "Реализовать боевую логику для системы боя", "Создать компоненты UI диалога"

> **Статусы**: ожидание → выполняется → завершено

**Задачи координации** (Coordination Task)

> **Описание**: задачи, которые требуют координации между членами

> **Примеры**: "Договориться об интерфейсе между системой боя и UI", "Синхронизировать структуру данных игрока"

> **Специальность**: требует обмена сообщениями между членами перед выполнением

**Задачи интеграции** (Integration Task)

> **Описание**: собрать результаты разных членов в одно целое

> **Примеры**: "Объединить все системы в главном контроллере", "Протестировать взаимодействие между модулями"

> **Особенность**: часто выполняется Team Lead после завершения всех параллельных задач

### Управление зависимостями

Когда задача A зависит от задачи B, система автоматически управляет порядком:

**Механизм работы**:

- Задача B находится в статусе "pending" (ожидание) до завершения задачи A
- Когда задача A завершена, система автоматически переводит задачу B в статус "ready" (готова)
- Member C может теперь взять задачу B и начать выполнение

**Пример зависимостей**:

```
Задача 1 (независимая):
- Teammate A: Проектирование архитектуры ✓

Задача 2-4 (зависит от Задачи 1):
- Teammate B: Реализация боевой системы (ждёт архитектуры)
- Teammate C: Реализация диалоговой системы (ждёт архитектуры)
- Teammate D: Реализация системы карты (ждёт архитектуры)

Задача 5 (зависит от Задач 2-4):
- Team Lead: Интеграция всех систем (ждёт, пока все 3 завершат)
```

---

## Сравнение: один Prompt vs Agent Teams

Для наглядного понимания мощи Agent Teams давайте сравним два подхода к одной задаче.

### Тест: разработка полнофункциональной RPG игры в стиле Покемонов

#### Способ A: единственный Prompt

Это традиционный способ — просить AI выполнить всё в одном диалоге.

**Введите в Claude Code**:

```
Помогите мне разрабатывать полнофункциональную сетевую RPG игру в стиле Покемонов, содержащую следующие функции:
- Система персонажей (уровень, HP, атака, защита)
- Система пошагового боя (атака, умения, предметы, бегство)
- Система диалогов с NPC
- Исследование 2D карты
- Функция сохранения
- Система звуков

Использовать React + TypeScript + Vite + Tailwind CSS.
Дайте мне полный код, который я могу запустить сразу.
```

**Ожидаемый результат**:

| Аспект | Ожидание |
|---------|---------|
| **Качество кода** | AI будет пытаться создать весь код, но из-за ограничения контекста, множество деталей будут опущены или заменены комментариями |
| **Полнота функций** | Основные функции могут быть, но много продвинутых функций будут упущены или упрощены |
| **Возможность запуска** | Возможны баги, требуется несколько раундов отладки перед запуском |
| **Время разработки** | Один диалог может занять 30-60 минут, требуется несколько итераций редактирования |
| **Количество кода** | примерно 500-800 строк (потому что AI сжимает код) |

**Вероятные проблемы**:

1. **Код обрезан**: ответ AI имеет ограничение по длине, код может создаться наполовину и затем остановиться
2. **Функции неполные**: система диалогов может быть только базовой, без системы квестов
3. **Нет деталей**: звуки могут быть только комментарием TODO
4. **Сложность отладки**: если в коде есть проблемы, нужно просить AI исправить в том же диалоге, контекст становится всё более запутанным

#### Способ B: Agent Teams

Это подход, описанный выше — мультиагентная командная разработка.

**Введите в Claude Code** (с активированными Agent Teams):

```
Я хочу разрабатывать полнофункциональную сетевую RPG игру в стиле Покемонов.

Создайте команду для совместной разработки:

Разделение обязанностей членов команды:
- Teammate A (архитектор игры): разработайте общую архитектуру, определите машину состояния игры, спланируйте структуру данных
- Teammate B (система боя): реализуйте логику пошагового боя, систему умений, расчёт урона
- Teammate C (система диалогов): реализуйте диалоги NPC, систему квестов, сценарий сюжета
- Teammate D (отрисовка карты): используйте Canvas для 2D отрисовки карты, движение персонажа, переход сцен
- Teammate E (UI и звуки): разработайте интерфейс игры, UI боя, воспроизведение звуков

Технические требования:
- Используйте оригинальный HTML/CSS/JavaScript
- Используйте Canvas для отрисовки игры
- Система пошагового боя
- Сохранение используйте localStorage
- Звуки используйте Web Audio API

Каждый член используйте модель Sonnet, Team Lead используйте Opus.

Сначала дайте архитектору разработать общий план, определить структуру данных, потом остальные члены начнут параллельную разработку.
```

**Ожидаемый результат**:

| Аспект | Ожидание |
|---------|---------|
| **Качество кода** | Каждый член сосредоточен на своей области, код более профессионален и полноценен |
| **Полнота функций** | Все функции имеют полную реализацию, включая систему квестов, несколько сцен карты и т.д. |
| **Возможность запуска** | Члены будут взаимно проверять интерфейсы, проблем интеграции меньше |
| **Время разработки** | примерно 1-2 часа завершить все функции (потому что параллельная разработка) |
| **Количество кода** | примерно 2000+ строк (полная реализация, без сжатия) |

#### Таблица количественного сравнения

| Аспект сравнения | Один Prompt | Agent Teams |
|---------|-------------|-------------|
| **Всего строк кода** | 500-800 строк | 2000+ строк |
| **Время разработки** | 30-60 минут (но функции неполные) | 1-2 часа (функции полные) |
| **Полнота функций** | 60-70% | 95%+ |
| **Поддерживаемость кода** | средняя (один большой файл) | высокая (модульный дизайн) |
| **Количество ошибок** | много (нет тестирования) | меньше (члены взаимно проверяют) |
| **Расширяемость после** | трудно (код связан) | легко (модульная структура) |
| **Потребление токенов** | ~50K tokens | ~200K tokens (5 членов) |
| **Стоимость** | ~$0.50 | ~$2.00 |

#### Рекомендации по реальному тестированию

**Шаг 1: Тест одного Prompt**

```
1. Откройте новый диалог Claude Code
2. Используйте "Способ A" из prompt выше
3. Запишите: сколько времени прошло? сколько строк кода? какие функции отсутствуют?
```

**Шаг 2: Тест Agent Teams**

```
1. Убедитесь, что Agent Teams активирована
2. Используйте "Способ B" из prompt выше
3. Наблюдайте: как члены сотрудничают? полноценнее ли код?
```

**Шаг 3: Сравните два результата**

```
1. Запустите обе версии кода
2. Сравните список функций: какие функции отсутствуют в одном Prompt?
3. Сравните структуру кода: более ли модульным код Agent Teams?
4. Оценивайте: если продолжить разработку этой игры, какая версия легче расширяемая?
```

#### Почему такие различия?

**Ограничения одного Prompt**:

1. **Давление контекста**: AI должна обработать всю информацию в одном ответе, неизбежно упрощение
2. **Рассеивание внимания**: одновременно внимание на боевую систему, диалоги, карту, UI, детали легко упускаются
3. **Отсутствие проверки сотрудничества**: никто не проверит, соответствуют ли интерфейсы, ошибки легко возникают

**Преимущества Agent Teams**:

1. **Профессиональное разделение**: каждый член сосредоточен на своей области, может углубиться в детали
2. **Параллельная обработка**: боевая система, диалоги, карта разрабатываются одновременно, эффективность выше
3. **Взаимная проверка**: члены согласовывают интерфейсы, снижаются проблемы интеграции
4. **Независимый контекст**: каждый член имеет свой контекст из 200K, не помешают друг другу

#### Выводы

Основное значение Agent Teams не в "более быстро", а в **"более полно и профессионально"**.

- Для простых проектов (как змейка), одного Prompt хватит
- Для сложных проектов (как полнофункциональная RPG), Agent Teams создаст лучший результат

Ключ — **выбрать подходящий инструмент**: не используй Agent Teams для переименования переменных, не используй один Prompt для разработки полной RPG игры.

---

## Лучшие практики

Agent Teams — мощный инструмент, но чтобы использовать его хорошо, нужно освоить некоторые лучшие практики. Этот опыт собран из реальной практики пользователей сообщества и может помочь тебе избежать частых ловушек и максимизировать стоимость командного сотрудничества.

### Практика первая: Contract-First (контрактно-ориентированный дизайн)

Перед тем как несколько Agent начнут параллельную работу, потрать время на определение чистого "контракта" — то есть интерфейсного договора.

**Почему это важно**:

Предположим, что Teammate A отвечает за бэкенд API, а Teammate B за вызовы фронтенда. Если они одновременно начнут работу, без предварительного соглашения формата интерфейса, вероятно получится такое:

```
Teammate A: реализовал POST /api/login, принимает {username, password}
Teammate B: реализовал фронтенд вызов, отправляет {user, pass}
Результат: не совпадает, нужна переделка
```

**Как делать**:

Перед запуском команды, сначала позволь Claude спроектировать интерфейс:

```
Не спешите разрабатывать, помогите мне сначала спроектировать интерфейсы системы пользовательской аутентификации:

1. Формат запроса и ответа интерфейса входа
2. Формат запроса и ответа интерфейса регистрации
3. Процесс и интерфейсы сброса пароля
4. Стандарты обработки ошибок

Напишите эти определения интерфейсов ясно, потом позвольте команде начать разработку.
```

**Контракт должен содержать**:

- Сигнатуры функций и структуры данных
- Форматы JSON входа и выхода
- Значения HTTP статус-кодов
- Соглашение обработки ошибок
- Правила валидации полей

### Практика вторая: Разумное распределение моделей

Разные задачи требуют моделей разных способностей, разумное распределение может сбалансировать эффект и стоимость.

**Team Lead используйте Opus**:

Team Lead отвечает за разбор задач и синтез результатов, это требует мощной логики, рекомендуется использовать Opus:

```
Создайте команду, Team Lead использует модель Opus, отвечает за общее планирование и проверку результатов.
Teammates используют модель Sonnet, отвечают за конкретную реализацию.
```

**Teammates используйте Sonnet**:

Конкретные задачи кодирования и тестирования, Sonnet полностью подходит, и стоимость ниже:

- Opus 4.6: примерно $15/миллион выходных токенов
- Sonnet 4.5: примерно $3/миллион выходных токенов

Использование Sonnet для членов может значительно снизить общую стоимость.

**Специальные случаи используйте Haiku**:

Для простых задач (как обновление документации, простое написание тестов), можно рассмотреть использование Haiku (примерно $0.80/миллион выходных токенов).

### Практика третья: Контролировать размер задач

Слишком большие или слишком малые задачи влияют на эффективность, нужно найти подходящий размер.

**Правило опыта**:

Каждая задача должна позволить одному члену независимо завершить в **15-30 минут**.

**Задачи слишком большие**:

```
Плохо: реализовать систему аутентификации пользователя
```

Эта задача слишком большая, содержит несколько подзадач, одному человеку требуется много времени для завершения, теряются преимущества параллелизма.

**Задачи слишком малые**:

```
Плохо: создать пустой файл с именем auth.js
```

Эта задача слишком мелкая, члены потратят больше времени на координацию, чем на настоящую работу.

**Подходящий размер**:

```
Хорошо: реализовать интерфейс входа API, включая:
1. Интерфейс POST /api/login
2. Валидировать имя пользователя и пароль
3. Вернуть JWT токен
4. Обработка ошибок
```

Эта задача имеет чёткие границы и результаты, один человек может её независимо завершить, и её не слишком мелкие.

**Рекомендуемая конфигурация**:

Каждый член отвечает за **5-6 задач среднего размера**, это даёт достаточный параллелизм без чрезмерной координационной стоимости.

### Практика четвёртая: Избежать конфликтов файлов

Множество членов, одновременно изменяющих один файл, ведут к конфликтам слияния — это самая частая проблема Agent Teams.

**Принципы распределения**:

Постарайся позволить разным членам отвечать за **разные файлы**:

```
Хорошо:
- Teammate A: отвечает за все файлы в директории src/auth/
- Teammate B: отвечает за все файлы в директории src/api/
- Teammate C: отвечает за все файлы в директории tests/auth/

Плохо:
- Teammate A и Teammate B оба нужно изменить src/app.js
```

**Если обязательно нужно изменить один файл**:

Разработай последовательные фазы изменения:

```
Фаза 1 (параллель):
- Teammate A: проанализировать, какие функции нужно добавить в auth.js
- Teammate B: спроектировать интерфейсы новых функций
- Teammate C: написать тестовые примеры

Фаза 2 (последовательно):
- Team Lead синтезирует все входы
- Один член единолично изменяет auth.js
```

### Практика пятая: Предоставить обогащённый начальный контекст

Когда Teammates запускаются, история разговора пуста — они не знают, о чём Team Lead и пользователь обсуждали ранее.

**Неправильно**:

```
Создайте команду, позвольте членам начать работу.
```

Члены запустятся в замешательстве: какой проект? какой технологический стек? что делать?

**Правильно**:

```
Это электронный проект React + Node.js, используя TypeScript.

Структура проекта:
- src/frontend/: код фронтенда React
- src/backend/: код бэкенда Node.js
- prisma/: модели базы данных

Стиль кода:
- Используйте функциональные компоненты и Hooks
- Бэкенд использует Express.js
- База данных используется PostgreSQL

Теперь создайте команду, позвольте членам добавить функцию аутентификации пользователя в src/auth/.
```

Предоставь достаточный контекст, члены работают эффективнее.

### Практика шестая: Сначала исследовать, потом реализовать

Не позволяй членам сразу начать кодировать, сначала позвольте им исследовать и спроектировать план.

**Двухфазный процесс**:

**Фаза 1: исследование и проектирование**

```
Создайте команду, первая фаза — исследование:
- Один член исследует существующие планы аутентификации (JWT vs Session)
- Один член анализирует технологический стек проекта, определяет лучшие практики
- Один член проектирует структуру таблиц базы данных

После исследования члены обсуждают через систему сообщений, определяют финальный план.
```

**Фаза 2: реализация**

```
После определения плана, вторая фаза начинается реализацией:
- Один член реализует логику бэкенд аутентификации
- Один член реализует страницу фронтенд входа
- Один член пишет тесты
```

Преимущество этого подхода: **раньше обнаружить архитектурные несовпадения**, избежать ситуации, когда пишешь половину и обнаруживаешь, что план не работает.

### Практика седьмая: активное наблюдение и вмешательство

Даже если ты настроил автоматизацию, ты всё ещё должен активно наблюдать статус работы команды.

**Используй режим разбиения экрана**:

Если ты настроил разбиение экрана tmux, можешь видеть вывод всех членов в реальном времени:

```
┌─────────────────┬─────────────────┐
│  Teammate 1     │  Teammate 2     │
│  Анализирует... │  Реализует API  │
│                 │                 │
│  Погодите,      │                 │
│  этот план      │                 │
│  похож на       │                 │
│  проблему...    │                 │
└─────────────────┴─────────────────┘
```

Когда ты заметишь, что какой-то член работает не в том направлении, ты можешь своевременно вмешаться:

```
@Teammate1 Погодите, направление анализа неправильное. Модуль аутентификации должен быть в src/auth/, а не в src/user/.
```

**Регулярно проверяй статус задач**:

Используй команду TaskList для просмотра статуса всех задач:

```
/tasks
```

Это покажет текущий статус всех задач — какие завершены, какие в процессе, какие заблокированы.

---

## Применимые сценарии

Agent Teams очень мощный инструмент, но не все задачи подходят для его использования. Понимание его применимых сценариев может помочь тебе принять правильное решение.

### Сценарии, подходящие для Agent Teams

**Рефакторинг сложных систем**

Когда твой рефакторинг затрагивает несколько модулей с чёткими границами между ними:

```
Сценарий: разбиение монолитного приложения на микросервисы

Создание команды:
- Teammate A: анализирует зависимости модуля пользователей
- Teammate B: анализирует зависимости модуля заказов
- Teammate C: анализирует зависимости модуля платежей
- Teammate D: проектирует протокол взаимодействия между сервисами
```

Три модуля могут анализироваться одновременно, результаты затем объединяются — это намного быстрее, чем последовательный анализ.

**Многоаспектная код-ревью**

Когда требуется рецензировать код с нескольких измерений:

```
Сценарий: полный обзор безопасности модуля платежей

Создание команды:
- Teammate A: сосредоточен на уязвимостях безопасности (SQL-инъекции, XSS и т.д.)
- Teammate B: проверяет проблемы производительности (N+1 запросы, утечки памяти и т.д.)
- Teammate C: проверяет полноту обработки ошибок
- Teammate D: оценивает покрытие тестами
```

Каждый член сосредоточен на одном измерении, обзор более детальный, в конце объединяется в одно полное отчёт.

**Параллельная разработка фронтенд и бэкенда**

Когда требуется одновременная разработка фронтенда и бэкенда:

```
Сценарий: разработка функции управления пользователями

Создание команды:
- Teammate A (фронтенд): реализует страницу списка пользователей
- Teammate B (фронтенд): реализует страницу редактирования пользователей
- Teammate C (бэкенд): реализует CRUD API
- Teammate D (координатор): проектирует интерфейс API, обеспечивает согласованность
```

Фронтенд и бэкенд могут разрабатываться одновременно — достаточно заранее определить интерфейс API (принцип "контракт прежде всего").

**Конкурентное отладки**

Когда есть несколько возможных решений:

```
Сценарий: исправление сложного bug, есть две возможных схемы исправления

Создание команды:
- Teammate A: реализует решение 1
- Teammate B: реализует решение 2
- Teammate C: оценивает преимущества и недостатки двух решений
```

Два решения реализуются и тестируются одновременно, затем результаты сравниваются — выбирается лучший.

**Генерация документации**

Когда требуется создать большой объём документации:

```
Сценарий: написание документации для всего проекта

Создание команды:
- Teammate A: пишет документацию API
- Teammate B: пишет руководство развёртывания
- Teammate C: пишет руководство разработчика
- Teammate D: пишет справочник по решению проблем
```

Несколько документов можно писать одновременно — это значительно повышает эффективность.

### Сценарии, не подходящие для Agent Teams

**Простые задачи на изменение**

```
Не подходит: переименование переменных, исправление одного bug, добавление небольшой функции
```

Затраты на запуск команды превосходят время на фактическую работу — это убыточно.

**Высокосерийные задачи**

```
Не подходит: шаги, которые должны выполняться в определённом порядке
```

Если задача B должна начаться после завершения задачи A, то нет места для параллелизма.

**Задачи, чувствительные к стоимости**

Потребление token в Agent Teams в **2-4 раза** больше, чем в одном экземпляре (зависит от размера команды). Если стоимость — главный критерий, одна экземпляр может быть лучше.

### Схема принятия решения

```
Есть ли несколько независимых подзадач?
    │
    ├─ Нет → используй одну экземпляр
    │
    └─ Да →
         │
         Можно ли распределить подзадачи по разным файлам?
         │
         ├─ Нет → рассмотри последовательное выполнение или переделай задачи
         │
         └─ Да →
              │
              Приемлема ли стоимость (2-4x)?
              │
              ├─ Нет → используй одну экземпляр
              │
              └─ Да → используй Agent Teams ✓
```

---

## Стоимость и производительность

Использование Agent Teams увеличивает стоимость, но также может привести к значительному повышению эффективности. Понимание этого компромисса помогает принять обоснованное решение.

### Анализ стоимости

**Потребление token и размер команды**

Потребление token в Agent Teams примерно **линейно связано** с размером команды:

| Размер команды | Относительная стоимость | Применимый сценарий |
|---------|---------|---------|
| 1 человек (одна экземпляр) | 1x | Простые задачи |
| 2-х человеческая команда | 2-2.5x | Средняя сложность |
| 3-х человеческая команда | 3-4x | Сложные задачи |
| 5+ человек команда | 5-6x+ | Крупные проекты |

**Почему не точная линейная зависимость**:

- **Стартовые затраты**: каждый член нуждается в получении начального контекста при запуске
- **Стоимость координации**: члены взаимодействуют друг с другом через систему сообщений, что также потребляет token
- **Стоимость Team Lead**: Team Lead обычно использует Opus, имеющий более высокую стоимость

**Конкретный пример расчёта** (Claude Sonnet):

- Вход: $3/за миллион token
- Выход: $15/за миллион token

Предположим, задача требует:
- Team Lead (Opus): 50K вход + 20K выход ≈ $2.25
- 3 Teammates (Sonnet): по 30K вход + 15K выход ≈ $2.7 × 3 = $8.1
- **Итого**: примерно $10.35

Той же задачей с одной экземпляром (Sonnet):
- 100K вход + 50K выход ≈ $1.05

**Кратное увеличение стоимости**: примерно 10x

**Но экономия времени**: может сократиться с 3 часов до 1 часа

### Повышение эффективности

**Внутренние тестовые данные Anthropic**:

- Рефакторинг крупного проекта: повышение эффективности примерно **50%**
- Параллельная разработка мультимодульных систем: повышение эффективности примерно **60-70%**
- Задачи генерации документации: повышение эффективности примерно **80%**

**Реальный пример**:

Инженерная команда Anthropic однажды использовала **16 параллельных агентов** для создания компилятора C, который может компилировать ядро Linux 6.9 (примерно 100,000 строк кода на Rust) примерно за 2 недели и прошёл 99% тестов GCC.

### Стратегии оптимизации стоимости

**Стратегия 1: смешанное использование моделей**

```
Team Lead: Opus (требуется мощное рассуждение)
Teammates: Sonnet (хороший баланс цены и производительности)
Простые задачи: Haiku (самый дешёвый)
```

**Стратегия 2: динамическое изменение размера команды**

```
Этап анализа: 5-человеческая команда (многоаспектный анализ)
Этап реализации: 3-человеческая команда (параллельное кодирование)
Этап тестирования: 2-х человеческая команда (тестирование и исправление)
```

**Стратегия 3: пошаговое использование Agent Teams**

Не применяй Agent Teams на всём проекте, используй его только на самых сложных этапах:

```
Этап 1 (анализ требований): одна экземпляр
Этап 2 (проектирование архитектуры): Agent Teams (параллельная реализация нескольких вариантов)
Этап 3 (кодирование): одна экземпляр
Этап 4 (код-ревью): Agent Teams (многоаспектный анализ)
Этап 5 (написание документации): Agent Teams (параллельное написание)
```

### Когда это имеет смысл

**Имеет смысл**:

- Проект срочный, ценность от повышения эффективности больше, чем стоимость token
- Задача высокой сложности, одна экземпляр легко упускает детали
- Требуется многоаспектный анализ и проверка

**Не имеет смысла**:

- Простая задача, стартовые затраты на команду слишком большие
- Стоимость критична, бюджет token ограничен
- Задача высокосерийна, нет пространства для параллелизма

---

## Часто задаваемые вопросы

### Вопрос 1: Agent Teams стабильна? Можно ли использовать в production?

Agent Teams в настоящее время является **экспериментальной функцией**, может быть некоторые ошибки и нестабильность. Рекомендации:

- Для важных проектов сделай резервную копию
- Сначала протестируй и изучи на небольших проектах
- Следи за официальным журналом изменений, узнавай об улучшениях в новых версиях
- Своевременно сообщай об ошибках в official

### Вопрос 2: Сколько максимум членов можно создать?

Теоретически нет жёсткого ограничения, но с практической точки зрения:

- Небольшой проект: 2-3 человека
- Средний проект: 3-5 человек
- Крупный проект: 5-10 человек

Слишком много членов приводит к следующим проблемам:

- Стоимость координации резко возрастает
- Потребление token растёт линейно
- Вероятность конфликтов файлов увеличивается
- Сложно следить и управлять

### Вопрос 3: Могут ли члены команды видеть контекст друг друга?

**Нет**. Каждый Teammate имеет совершенно независимое окно контекста, они взаимодействуют друг с другом через систему сообщений, а не через общий контекст.

Это дизайнерское решение имеет следующие преимущества:

- Мышление каждого члена не будет загрязнено другими членами
- Контекст не будет запутан из-за чрезмерно длинных диалогов
- Больше напоминает сотрудничество в реальной команде (у каждого свой ум)

### Вопрос 4: Как переключаться между разными членами?

Если разбиение экрана не настроено, можешь использовать горячие клавиши:

- `Shift+Up`: переключиться на предыдущего члена
- `Shift+Down`: переключиться на следующего члена
- `Ctrl+O`: вернуться к Team Lead

### Вопрос 5: Что делать, если задача члена не удалась?

Если задача члена не удалась:

1. Посмотри причину ошибки: прочитай журнал вывода члена
2. Переобъяви задачу: можешь переназначить задачу другому члену
3. Ручное вмешательство: можешь вмешаться, помочь решить застрявшую проблему

### Вопрос 6: Можно ли добавить или удалить членов в процессе?

Можно. В любой момент можешь отправить инструкцию Team Lead:

```
Добавь нового члена, чтобы он отвечал за задачу XXX.
```

```
Позволь Teammate 3 завершить текущую задачу и затем покинуть команду.
```

### Вопрос 7: Можно ли использовать Agent Teams вместе с MCP и Skills, которые мы учили раньше?

Полностью возможно! И совместное использование даёт ещё лучший эффект:

- **Agent Teams + Skills**: каждый член может иметь разные skills
- **Agent Teams + MCP**: разные члены могут получить доступ к внешним ресурсам через разные MCP серверы

```
Создание команды:
- Teammate A: имеет frontend-design Skill, отвечает за UI
- Teammate B: получает доступ к репозиторию через GitHub MCP, отвечает за управление PR
- Teammate C: запрашивает данные через Database MCP, отвечает за анализ данных
```

---

## Справочные материалы

### Официальные ресурсы

- [Официальная документация Claude Code](https://docs.anthropic.com/en/docs/claude-code) — Полная документация Claude Code
- [Официальный инженерный блог Anthropic](https://www.anthropic.com/engineering) — Официальный технический блог и обновления

### Специальные учебники Agent Teams

**Полный китайский гайд**:

- [Claude Code Agent Teams Полный гайд: от начинающих к практике](https://m.blog.csdn.net/u010634066/article/details/157903022) — включает детали конфигурации и реальные примеры, впечатляющий пример создания компилятора C с 16 параллельными агентами
- [Используя Claude Code Agent Team для совместной разработки проекта: полное практическое руководство](https://m.blog.csdn.net/u010028049/article/details/158126612) — полный процесс совместной разработки проекта
- [Пошаговое руководство по настройке и использованию Claude Code Agent Teams](https://cloud.tencent.com/developer/article/2630088) — Tencent Cloud, детальное руководство конфигурации

**Практика для начинающих**:

- [Claude Code собственный Agent Teams практика: от активации к запуску трёхчленной команды](https://www.cnblogs.com/147api/p/19606317) — трёхчленная командная практика
- [Claude Code Agent Teams свежая практика для начинающих](https://m.toutiao.com/article/7606744384960266793/) — введение для новичков, включает лучшие практики контракта прежде всего
- [Больше не работайте в одиночку! используй Agent Teams, чтобы 7 Claude помогали тебе разрабатывать](https://m.toutiao.com/a7605229732241736202/) — пример сотрудничества семичленной команды

**Лучшие практики**:

- [Agent Teams лучшие практики: контракт прежде всего, гранулярность задач, распределение моделей](https://blog.csdn.net/sinat_37574187/article/details/144727588) — подробное объяснение 7 лучших практик
- [Руководство по практике Claude Code опытного инженера из крупной компании на протяжении семи лет: от начинающих к мастерству в восьми боевых правилах](https://new.qq.com/rain/a/20260111A02HE900) — опыт работы на уровне предприятия

**Принципы и сравнение**:

- [Claude Code Agent Teams: правильный способ открыть многоагентское сотрудничество](https://post.m.smzdm.com/p/adoezrmz/) — глубокий анализ многоагентского сотрудничества
- [Claude Code многоагентная командная разработка: от принципов к полному руководству по ошибкам](https://m.toutiao.com/a7605229732241736202/) — принципы и опыт ошибок

### Официальные переводы руководств

- [Claude официально опубликовал «Руководство по построению Agent» (прилагается загрузка PDF)](https://m.blog.csdn.net/sinat_37574187/article/details/144724124) — официальное руководство по построению Agent
- [Claude официально опубликовал полный перевод «Руководства по построению эффективных Agents»](https://m.blog.csdn.net/gyn_enyaer/article/details/144827922) — полный китайский перевод

### Связанные технологии

- [Стандарт Agent Skills](https://agentskills.io/) — экосистема Skills
- [skills.sh - магазин приложений Agent Skills](https://skills.sh/) — библиотека 70,000+ skills
