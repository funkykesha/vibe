Groovy JSON Cheatsheet (Clean Version)

JSON Filter

Groovy Json Filter — фильтрует JSON объекты на основе Groovy-предиката.
	•	В предикате используется переменная _
	•	_ = каждый объект массива
	•	Условие true → левый выход
	•	Условие false → правый выход

Пример

_.country == "RU"

Несколько условий

_.is_text_dup != "-1" && _.is_super_dup != "-1"

Операторы:
	•	|| — или
	•	&& — и
	•	!= — не равно

Проверка на отсутствие поля

_.inputValues.query_region_id != null

Если JSON — массив массивов

_[0].inputValues.query_text == "artificial stone line"


⸻

Регулярные выражения

Используется оператор:

=~

Обязательно приводить к Boolean:

(_.url_left =~ /vk.com/) as Boolean

Пример

(_.url_left =~ /vk.com/) as Boolean || (_.url_right =~ /vk.com/) as Boolean

Поиск слов

(_.assessment_result.comment =~ /откаж/ || _.assessment_result.comment =~ /отказ/)


⸻

JSON Map

Преобразует JSON объекты.

Вариант 1

{
  "inputValues": {
    "url": _.url,
    "device": _.device,
    "country": _.country
  }
}

Вариант 2

_.inputValues = [:]
_.inputValues.url = _.url
_.inputValues.device = _.device
_.inputValues.country = _.country
_.remove("url")
_.remove("country")
_.remove("device")
_

Вариант 3

[
  cause: _.cause,
  timestampUtc: _.timestampUtc,
  query: _.metaData.inputValues.query,
  comment: _.comment
]

Важно: в конце всегда возвращать _

⸻

Изменение одного поля

_.inputValues.address = "Москва"
_


⸻

Извлечение JSON из JSON

_.knownSolutions = _.knownSolutions[0]["outputValues"]
_


⸻

Удаление поля

_.inputValues.remove('query_uid')
_


⸻

Добавление поля

_.newField = "value"
_


⸻

Преобразование типов

_.field = _.field.toBoolean()
_.field = _.field.toString()
_.field = _.field.toInteger()
_.field = _.field.toBigDecimal()
_.field = _.field.toDouble()
_


⸻

Случайный выбор из строки

def list = _.responsible.split(', ')
def choice = new java.util.Random().nextInt(list.size())
_.responsible = list[choice].trim()
_


⸻

Маппинг значений

_.trigger_name = [
  "cheat_incident_fingerprints_trigger": "FINGERPRINTS",
  "cheat_incident_big_income_sprav_trigger": "BIG_INCOME_SPRAV",
  "cheat_incident_big_income_trigger": "BIG_INCOME"
][_.trigger_name]
_


⸻

Удаление null-полей

if (_.tonality == null) {
  _.remove("tonality")
}
_


⸻

Сбор словаря

[(_.value): _.label]


⸻

Регулярки — извлечение из строки

def login = _.login =~ /\((.*?)\)/
def assignee = _.assignee =~ /\((.*?)\)/

[
  login: login[0][1],
  assignee: assignee[0][1],
  reason: _.reason.trim(),
  answer_form_id: _.answer_form_id.trim()
]


⸻

JSON ↔ String

JSON → String

new groovy.json.JsonBuilder(_).toString()
new groovy.json.JsonBuilder(_).toPrettyString()

String → JSON

import groovy.json.JsonSlurper
new JsonSlurper().parseText(_)


⸻

JSON Process

Основы
	•	in0 — входной массив
	•	out.write() — запись результата

Итерация

in0.each {
}


⸻

Проверка на пустой вход

if (in0.size() == 0) return


⸻

Размер массива

out.write([count: in0.size()])


⸻

Сортировка

out.write(in0.sort { it.updatedAtTs })


⸻

Статистика

def yes = 0
def no = 0

in0.each {
  if (it.outputValues."is-change" == "NO") {
    no++
  } else {
    yes++
  }
}

out.write([count: in0.size(), count_yes: yes, count_no: no])


⸻

Сумма

def sum = 0
in0.each {
  sum += it.values_to_count
}
out.write(sum: sum)


⸻

Группировка

in0.groupBy { it.workerId }.each { key, value ->
  out.write([(key): value.size()])
}


⸻

Фильтр

in0.each {
  if (it.cause == "WRONG_ANNOTATION") {
    out.write(it)
  }
}


⸻

Каждый N-элемент

def i = 0
in0.each {
  i++
  if (i == 4) {
    out.write(it)
    i = 0
  }
}


⸻

Первые N элементов

def i = 0
in0.each {
  i++
  if (i <= 10) {
    out.write(it)
  }
}


⸻

Дубликаты

in0.groupBy { it.obj }.each { k, v ->
  if (v.size() > 1) {
    out.write([key: k, value: v])
  }
}


⸻

Разделение на группы

def list = in0.collect { it.worker_id }

in0.each {
  it.group = list.indexOf(it.worker_id) % 2 == 0 ? "A" : "B"
  out.write(it)
}


⸻

Склейка JSON

def result = [:]
in0.each {
  result << it
}
out.write(result)


⸻

Исключения

Падение при пустом результате

if (in0.size() == 0) {
  throw new Exception("no data")
}

Обработка ошибок

catch (Exception e) {
  [
    _this_op_status: "Error",
    _this_op_status_details: e.toString(),
    _this_element: _
  ]
}


⸻

Парсинг JSON из строки

import groovy.json.JsonSlurper

_.field = new JsonSlurper().parseText(_.field)
_


⸻

Обратное преобразование

import groovy.json.JsonOutput

_.field = JsonOutput.toJson(_.field)
_


⸻

Итог

Этот файл — сокращённый и очищенный справочник по:
	•	JSON Filter
	•	JSON Map
	•	JSON Process
	•	Groovy-скриптам

Без лишних ссылок и с нормальным форматированием под код.