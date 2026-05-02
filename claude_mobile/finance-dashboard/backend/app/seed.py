from sqlalchemy.orm import Session

from . import models

INIT_CATS = [
    {"id": 1, "name": "НЗ", "pct": "15"},
    {"id": 2, "name": "Новый дом", "pct": "0"},
    {"id": 3, "name": "Сын / учёба", "pct": "5"},
    {"id": 4, "name": "Ипотека", "pct": "32.4"},
    {"id": 5, "name": "ЖКХ / страх / инет", "pct": "8"},
    {"id": 6, "name": "Шмотки", "pct": "2"},
    {"id": 7, "name": "Здоровье", "pct": "2.5"},
    {"id": 8, "name": "Мотоцикл", "pct": "2"},
    {"id": 9, "name": "Фикс платежи", "pct": "1.5"},
    {"id": 10, "name": "Свободный поток", "pct": "5"},
    {"id": 11, "name": "Кредитка Тани", "pct": "18.6"},
    {"id": 12, "name": "На семью", "pct": "4"},
    {"id": 13, "name": "На себя", "pct": "4"},
]

INIT_DEDS = [
    {"id": 1, "name": "Бейдж", "val": ""},
    {"id": 2, "name": "НДФЛ", "val": ""},
    {"id": 3, "name": "ДМС Тани", "val": "1601.72"},
    {"id": 4, "name": "Страховка Тани", "val": "203.84"},
    {"id": 5, "name": "Перерасход", "val": ""},
]

INIT_ACCS = [
    {"id": 101, "bank": "Тинькоф", "name": "НЗ", "type": "Счет", "cat": "Быстрые", "val": ""},
    {"id": 102, "bank": "Тинькоф", "name": "НЗ (накопит.)", "type": "Счет", "cat": "Быстрые", "val": ""},
    {"id": 103, "bank": "Тинькоф", "name": "Свободный поток", "type": "Счет", "cat": "На что то", "val": ""},
    {"id": 104, "bank": "Тинькоф", "name": "Шмотки", "type": "Счет", "cat": "На что то", "val": ""},
    {"id": 105, "bank": "Тинькоф", "name": "ЖКХ + Страх + инет", "type": "Счет", "cat": "Ипотека", "val": ""},
    {"id": 106, "bank": "Тинькоф", "name": "Здоровье", "type": "Счет", "cat": "Жизнь", "val": ""},
    {"id": 107, "bank": "Тинькоф", "name": "Мотоцикл", "type": "Счет", "cat": "Жизнь", "val": ""},
    {"id": 108, "bank": "Тинькоф", "name": "Фикс платежи", "type": "Счет", "cat": "Жизнь", "val": ""},
    {"id": 109, "bank": "Тинькоф", "name": "Личные", "type": "Счет", "cat": "Жизнь", "val": ""},
    {"id": 110, "bank": "Тинькоф", "name": "Семья", "type": "Счет", "cat": "Жизнь", "val": ""},
    {"id": 111, "bank": "Тинькоф", "name": "Дебетовый", "type": "Счет", "cat": "Жизнь", "val": ""},
    {"id": 112, "bank": "Тинькоф", "name": "Семейный счет", "type": "Счет", "cat": "Семейные", "val": ""},
    {"id": 113, "bank": "Тинькоф", "name": "Семейный накоп.", "type": "Счет", "cat": "Семейные", "val": ""},
    {"id": 114, "bank": "Тинькоф", "name": "Вклад Тихон", "type": "Вклад", "cat": "Сын", "val": ""},
    {"id": 115, "bank": "Тинькоф", "name": "ИИС (НЗ)", "type": "ИИС", "cat": "Инвест", "val": ""},
    {"id": 116, "bank": "Тинькоф", "name": "Брокерский (Актив.)", "type": "Брокер", "cat": "Быстрые", "val": ""},
    {"id": 201, "bank": "Яндекс", "name": "Брокер (Тихон)", "type": "Брокер", "cat": "Сын", "val": ""},
    {"id": 202, "bank": "Яндекс", "name": "Дебетовый", "type": "Счет", "cat": "Жизнь", "val": ""},
    {"id": 301, "bank": "ДОМ РФ", "name": "НЗ вклад 1", "type": "Вклад", "cat": "Быстрые", "val": ""},
    {"id": 302, "bank": "ДОМ РФ", "name": "НЗ вклад 2", "type": "Вклад", "cat": "Быстрые", "val": ""},
    {"id": 303, "bank": "ДОМ РФ", "name": "НЗ вклад 3", "type": "Вклад", "cat": "Быстрые", "val": ""},
    {"id": 304, "bank": "ДОМ РФ", "name": "Семейный вклад 1", "type": "Вклад", "cat": "Семейные", "val": ""},
    {"id": 305, "bank": "ДОМ РФ", "name": "Семейный вклад 2", "type": "Вклад", "cat": "Семейные", "val": ""},
    {"id": 306, "bank": "ДОМ РФ", "name": "Ипотечный буфер", "type": "Счет", "cat": "Ипотека", "val": ""},
    {"id": 307, "bank": "ДОМ РФ", "name": "Кредитное плечо", "type": "Счет", "cat": "Жизнь", "val": ""},
    {"id": 401, "bank": "Финуслуги", "name": "Семейный 07.05", "type": "Вклад", "cat": "Семейные", "val": ""},
    {"id": 402, "bank": "Финуслуги", "name": "Семейный 05.08", "type": "Вклад", "cat": "Семейные", "val": ""},
    {"id": 501, "bank": "ФридФин", "name": "Баксы", "type": "Счет", "cat": "Валюта", "val": "", "currency": "USD"},
    {"id": 601, "bank": "Наличка", "name": "Баксы", "type": "Наличка", "cat": "Валюта", "val": "", "currency": "USD"},
    {"id": 701, "bank": "Долги", "name": "За окна", "type": "Долг", "cat": "Долги", "val": "-200000"},
]

DEFAULT_USD_RATE = "80.33"
DEFAULT_MORTGAGE = "11948583"


def seed_defaults(db: Session) -> None:
    for item in INIT_CATS:
        if db.get(models.Category, item["id"]) is None:
            db.add(models.Category(**item))

    for item in INIT_DEDS:
        if db.get(models.Deduction, item["id"]) is None:
            db.add(models.Deduction(**item))

    for item in INIT_ACCS:
        if db.get(models.Account, item["id"]) is None:
            payload = {"currency": "RUB", **item}
            db.add(models.Account(**payload))

    existing = db.get(models.AppSettings, 1)
    if existing is None:
        db.add(models.AppSettings(id=1, usd_rate=DEFAULT_USD_RATE, mortgage=DEFAULT_MORTGAGE))

    db.commit()
