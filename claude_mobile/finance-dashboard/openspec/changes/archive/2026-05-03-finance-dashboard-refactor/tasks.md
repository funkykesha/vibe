## 1. State cleanup

- [x] 1.1 Удалить `const [payDay, setPayDay] = useState("5")` из App
- [x] 1.2 Удалить `const [deds, setDeds] = useState(INIT_DEDS)` из App
- [x] 1.3 Удалить `INIT_DEDS` константу
- [x] 1.4 Добавить state: `badge`, `dmsAmount` (default "1601.72"), `insAmount` (default "203.84"), `overspend`
- [x] 1.5 Добавить state: `deductionMapping` (default: `{ ndfl: 13, dms: 7, insurance: 7, overspend: 10 }`)
- [x] 1.6 Добавить `showDeductions` state (boolean, default false) для ручного toggle

## 2. Persistence

- [x] 2.1 Обновить useEffect загрузки: читать `badge`, `dmsAmount`, `insAmount`, `overspend`, `deductionMapping` из `fin-v3`; применять дефолты если отсутствуют
- [x] 2.2 Обновить useEffect сохранения: убрать `deds`, добавить новые поля и `deductionMapping`

## 3. Расчётная логика

- [x] 3.1 Переписать `totalDeds`: `parse(badge)*0.13 + parse(dmsAmount) + parse(insAmount) + parse(overspend)`
- [x] 3.2 Переписать `dist` useMemo: `Math.floor(net * pct / 100)` для всех кроме id=13; id=13 = `net − sum(остальных)`
- [x] 3.3 Добавить `ndfl` useMemo: `parse(badge) * 0.13`
- [x] 3.4 Добавить `deductionsByCategory` useMemo: объект `{ [catId]: сумма_вычетов }` по маппингу
- [x] 3.5 Добавить `payDay` derived const из `salaryEventType` (не state)

## 4. UI ритуала (таб ЗП)

- [x] 4.1 Удалить кнопки "5-е/20-е" из блока выбора даты
- [x] 4.2 Оставить только dropdown `salaryEventType`; убедиться что он инициализирован и список опций полный
- [x] 4.3 Переделать топ-блок: поля Начислено, Бейдж, ДМС Тани, Страховка Тани, Перерасход — все NumInput
- [x] 4.4 Добавить read-only строку НДФЛ под полями (показывает `fmt(ndfl) ₽`)
- [x] 4.5 Обернуть блок вычетов в условный рендер: `salaryEventType === "5th_payday" || showDeductions`
- [x] 4.6 Добавить кнопку "+ Вычеты" когда `salaryEventType !== "5th_payday" && !showDeductions`
- [x] 4.7 Обновить строку `totalDeds` в заголовке блока вычетов

## 5. Таблица распределения

- [x] 5.1 Добавить колонки "Потрачено" и "Доступно" в каждую строку таблицы
- [x] 5.2 Если `deductionsByCategory[d.id]` > 0: показать сумму в "Потрачено"; иначе "—"
- [x] 5.3 "Доступно" = `d.amount − (deductionsByCategory[d.id] || 0)`; отрицательное → `text-red-400`
- [x] 5.4 Обновить `copyDist()`: включить потрачено/доступно в скопированный текст

## 6. Настройки

- [x] 6.1 Для категории id=13: скрыть `<input type="number">` для %, показать текст "остаток"
- [x] 6.2 Скрыть кнопку "×" удаления для категории id=13
- [x] 6.3 Добавить секцию "Маппинг вычетов" в таб Настройки
- [x] 6.4 Секция содержит 4 строки: НДФЛ, ДМС Тани, Страховка, Перерасход; у каждой `<select>` с опциями из `cats`
- [x] 6.5 При изменении select: обновить `deductionMapping` state

## 7. Проверка

- [x] 7.1 Открыть в браузере, выбрать "5-е" — вычеты видны автоматически
- [x] 7.2 Переключить на "20-е" — вычеты скрыты, кнопка "+ Вычеты" присутствует
- [x] 7.3 Ввести бейдж 30000 → НДФЛ read-only = 3 900,00 ₽
- [x] 7.4 Убедиться что sum(все категории) = net (целое число)
- [x] 7.5 Проверить что "На себя" = net − sum(остальных) и не имеет поля %
- [x] 7.6 В настройках изменить маппинг НДФЛ → другую категорию; убедиться что таблица обновилась
- [x] 7.7 Перезагрузить страницу — убедиться что настройки маппинга сохранились
