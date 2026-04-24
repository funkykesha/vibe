# Groovy JSON Processing

## Parsing (JsonSlurper)

```groovy
import groovy.json.JsonSlurper

// Чтение из stdin (основной способ в агенте)
def input = new JsonSlurper().parseText(System.in.text ?: '{}')

// Парсинг строки
def data = new JsonSlurper().parseText('{"name": "Alice", "age": 30}')

// Безопасное обращение к полям
def name = data?.name ?: 'Unknown'
def items = data?.items ?: []
```

## Generating (JsonOutput)

```groovy
import groovy.json.JsonOutput

def map = [name: "Bob", items: [1, 2, 3]]

// Компактный JSON
println JsonOutput.toJson(map)
// {"name":"Bob","items":[1,2,3]}

// Красивый (форматированный) JSON — рекомендуется
println JsonOutput.prettyPrint(JsonOutput.toJson(map))
```

## Complete Script Template

```groovy
import groovy.json.JsonSlurper
import groovy.json.JsonOutput

def input = new JsonSlurper().parseText(System.in.text ?: '{}')

// === Трансформация ===
def result = input

println JsonOutput.prettyPrint(JsonOutput.toJson(result))
```

## Common Transformations

### Добавить поле к каждому элементу массива
```groovy
def result = input.items.collect { item ->
    item + [processedAt: new Date().format('yyyy-MM-dd HH:mm:ss')]
}
```

### Переименовать поля
```groovy
def result = input.items.collect { item ->
    [id: item.old_id, name: item.full_name, status: item.is_active ? 'active' : 'inactive']
}
```

### Фильтровать по условию
```groovy
def result = input.items.findAll { it.status == 'active' && it.amount > 0 }
```

### Сгруппировать по полю
```groovy
def result = input.items.groupBy { it.category }
// Вернёт: {"catA": [...], "catB": [...]}
```

### Вычислить агрегаты
```groovy
def result = [
    total: input.items.size(),
    sum: input.items.sum { it.amount ?: 0 },
    avg: input.items.empty ? 0 : input.items.sum { it.amount ?: 0 } / input.items.size(),
    byStatus: input.items.groupBy { it.status }.collectEntries { k, v -> [k, v.size()] }
]
```

### Выровнять вложенную структуру
```groovy
def result = input.orders.collectMany { order ->
    order.items.collect { item ->
        [orderId: order.id, itemId: item.id, name: item.name, qty: item.quantity]
    }
}
```

### Объединить два массива по ключу
```groovy
def usersMap = input.users.collectEntries { [(it.id): it] }
def result = input.orders.collect { order ->
    order + [userName: usersMap[order.userId]?.name ?: 'Unknown']
}
```

### Преобразование ключей (camelCase → snake_case)
```groovy
def toSnake = { String s ->
    s.replaceAll(/([A-Z])/, /_$1/).toLowerCase().replaceAll(/^_/, '')
}
def result = input.collectEntries { k, v -> [(toSnake(k.toString())): v] }
```
