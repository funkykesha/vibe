# Groovy Collections API

## List (массив)

```groovy
def list = [1, 2, 3, 4, 5]

// Трансформация
list.collect { it * 2 }             // [2, 4, 6, 8, 10]

// Фильтрация
list.findAll { it > 2 }             // [3, 4, 5]

// Первый подходящий
list.find { it > 2 }                // 3

// Сортировка
list.sort()                          // по возрастанию
list.sort { a, b -> b <=> a }       // по убыванию
list.sort { it.name }               // объекты по полю

// Агрегация
list.sum()                           // 15
list.sum { it.amount }               // сумма поля
list.max()                           // 5
list.min()                           // 1
list.inject(0) { acc, v -> acc + v } // аналог reduce

// Проверки
list.every { it > 0 }               // все > 0?  true
list.any   { it > 4 }               // есть > 4? true
list.none  { it < 0 }               // нет < 0?  true
list.count { it.even }              // количество чётных

// Уникальные
list.unique()                        // убирает дубли
list.unique { it.id }               // по полю объекта

// Первые/последние
list.take(3)                         // [1, 2, 3]
list.drop(2)                         // [3, 4, 5]
list.first()                         // 1
list.last()                          // 5

// Плоский список из вложенных
[[1,2],[3,4]].flatten()              // [1, 2, 3, 4]

// Развернуть вложенные с трансформацией
list.collectMany { [it, it*10] }    // [1,10, 2,20, ...]

// Разбить на группы
list.collate(2)                      // [[1,2],[3,4],[5]]

// Zip двух списков
[1,2,3].withIndex().collect { v, i -> "$i:$v" }
```

## Map (объект)

```groovy
def m = [name: 'Alice', age: 30, city: 'Moscow']

// Безопасное получение с дефолтом
m.get('email', 'no-email')
m.email ?: 'no-email'

// Итерация
m.each { k, v -> println "$k = $v" }
m.collect { k, v -> "$k=$v" }.join(', ')
m.findAll { k, v -> v instanceof String }

// Трансформация ключей или значений
m.collectEntries { k, v -> [k.toUpperCase(), v] }

// Слияние (новые значения побеждают)
def merged = m + [phone: '+7-900-000-0000', age: 31]

// Выбрать подмножество ключей
m.subMap(['name', 'city'])

// Удалить ключ (не мутирует оригинал)
m.findAll { k, v -> k != 'age' }
```

## Useful Groovy Idioms

```groovy
// Null-safe навигация
user?.address?.city ?: 'Unknown'

// Elvis operator для дефолтов
def n = value ?: 0
def s = str ?: 'default'

// Безопасное приведение типа
def num  = value?.toInteger()  ?: 0
def dbl  = value?.toDouble()   ?: 0.0
def str  = value?.toString()   ?: ''
def bool = value?.toBoolean()  ?: false

// Spread — вызов метода на каждом элементе
names*.toUpperCase()         // эквивалент collect { it.toUpperCase() }
items*.size()                // список длин

// Диапазоны
(1..5).collect { it * it }   // [1, 4, 9, 16, 25]
(0..<list.size())            // 0 до size-1 (не включая)

// Многострочные строки и интерполяция
def json = """{"name": "${name}", "count": ${count}}"""

// with {} — удобно для множественного присвоения
def result = [:].with {
    put('a', 1)
    put('b', 2)
    it // вернуть сам map
}

// Форматирование даты
new Date().format('yyyy-MM-dd HH:mm:ss')
Date.parse('yyyy-MM-dd', '2024-01-15').format('dd.MM.yyyy')
```

## Error Handling

```groovy
try {
    def parsed = new groovy.json.JsonSlurper().parseText(raw)
    // ...
} catch (groovy.json.JsonException e) {
    println groovy.json.JsonOutput.toJson([error: "Invalid JSON: ${e.message}"])
}
```
