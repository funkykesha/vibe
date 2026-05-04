## Context

Приложение — single-file React 18 + Babel + Tailwind (`index.html`, ~500 строк). Всё состояние в памяти, персистируется в localStorage под ключом `fin-v3`. Нет сборки, нет npm-зависимостей в dev. Единственный файл для изменений.

Текущие проблемы:
- `payDay` (state) + `salaryEventType` (state) дублируют друг друга
- `INIT_DEDS` массив из 5 элементов (Бейдж, НДФЛ, ДМС, Страховка, Перерасход) используется непоследовательно: Бейдж — фактически не вычет, НДФЛ — пустое поле
- Округления нет: `net * pct / 100` даёт float
- Нет связи между вычетами и категориями бюджета

## Goals / Non-Goals

**Goals:**
- Один dropdown вместо двух полей для типа/дня выплаты
- Топ-блок с явными input-полями для всех изменяемых входных данных (gross, badge, dms, insurance, overspend)
- НДФЛ как read-only расчётное поле
- Вычеты скрыты для не-5-го числа
- `Math.floor` для всех категорий; "На себя" = остаток
- `deductionMapping` — настраиваемый маппинг с дефолтами
- Колонки "потрачено/доступно" в таблице распределения

**Non-Goals:**
- Не трогать таб "Капитал"
- Не добавлять бэкенд или новые CDN зависимости
- Не менять логику копирования в буфер

## Decisions

### 1. Убрать `payDay`, оставить только `salaryEventType`

`payDay` вычисляется из `salaryEventType`:
```js
const payDay = salaryEventType === "5th_payday" ? 5
             : salaryEventType === "20th_payday" ? 20
             : 5; // дефолт для vacation/bonus/other
```
Альтернатива: оставить оба. Отклонено — избыточно, пользователь должен выбирать одно.

### 2. Отдельные state вместо массива `deds`

Заменить `deds: [{id, name, val}]` на скалярные state:
```js
const [badge, setBadge]       = useState("");
const [dmsAmount, setDms]     = useState("1601.72");
const [insAmount, setIns]     = useState("203.84");
const [overspend, setOver]    = useState("");
```
Минус: теряется гибкость "добавить вычет". Допустимо — структура вычетов фиксирована по договорённости.

### 3. `deductionMapping` как объект ключ→id категории

```js
const DEFAULT_DEDUCTION_MAPPING = { ndfl: 13, dms: 7, insurance: 7, overspend: 10 };
```
Сохраняется в `fin-v3` вместе с остальными настройками. При отсутствии ключа при загрузке — применять дефолт.

### 4. Округление: Math.floor + остаток

```js
const dist = useMemo(() => {
  const nonSelf = cats.filter(c => c.id !== 13);
  const floored = nonSelf.map(c => ({ ...c, amount: Math.floor(net * parse(c.pct) / 100) }));
  const selfAmount = net - floored.reduce((s, c) => s + c.amount, 0);
  const self = cats.find(c => c.id === 13);
  return [...floored, { ...self, amount: selfAmount }];
}, [cats, net]);
```

### 5. Таблица распределения: "потрачено" и "доступно"

```js
const deductionsByCategory = useMemo(() => {
  const ndfl = parse(badge) * 0.13;
  const map = { [deductionMapping.ndfl]: ndfl, ... };
  // аккумулировать суммы по category id
}, [...]);
```
Каждая строка таблицы: `выделено − потрачено = доступно`. Отрицательное доступно → красный цвет.

## Risks / Trade-offs

- **Потеря гибкости вычетов** → принято: фиксированный набор соответствует реальному использованию
- **localStorage migration**: старый `fin-v3` без `deductionMapping` → дефолт применяется тихо, данные не теряются
- **"На себя" без %**: если пользователь удалит категорию с id=13 из настроек, логика сломается → защита: скрыть кнопку удаления для id=13, не показывать поле % в настройках

## Migration Plan

1. Изменить `index.html` (один файл)
2. При загрузке `fin-v3`: если `badge`/`dmsAmount`/`insAmount`/`overspend` отсутствуют — инициализировать дефолтами
3. Старое поле `deds` в localStorage игнорируется (не читается)
4. Rollback: вернуть старый `index.html` из git

## Open Questions

- Нужна ли возможность ручного ввода дня (число) для типов vacation/bonus/other? → По умолчанию 5, добавить позже при необходимости
