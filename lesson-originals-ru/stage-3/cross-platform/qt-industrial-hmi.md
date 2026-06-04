---
title: Как разработать промышленное приложение Qt — мониторинг воды в HMI системе
description: Создание промышленной системы мониторинга на Qt с поддержкой Modbus TCP, реальными трендами и системой оповещений
---

<!-- nav -->
**📚 Версии:** [Кратко](../../../lesson-summaries/stage-3/cross-platform/qt-industrial-hmi.md) · [Расширенно](../../../lesson-summaries-full/stage-3/cross-platform/qt-industrial-hmi.md) · **Полный перевод** · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-3/cross-platform/qt-industrial-hmi/index.md)

# Как разработать промышленное приложение Qt — мониторинг воды в HMI системе

# Глава 1: Что такое промышленная HMI и разработка на Qt

В этом уроке мы создадим полный цикл: с нуля разработаем промышленную систему мониторинга давления в воде на Qt, которая может читать в реальном времени данные с датчиков, рисовать тренды давления, автоматически срабатывать на превышение порога с оповещениями, записывать события в логи. Весь процесс будет использовать бесплатное программное обеспечение для моделирования на ПК вместо реального оборудования управления, не требует покупки какого-либо оборудования.

Для этого урока тебе нужно:

- Компьютер (Windows или Mac, Windows рекомендуется, лучше совместим с промышленным ПО)
- Окружение разработки Qt 6.5 (Qt Creator + модули Qt Serial Bus + Qt Charts)
- Программное обеспечение Modbus Slave для моделирования (бесплатно, берёт роль "виртуального насоса")
- Твой AI помощник программирования (Cursor / Trae / Claude Code)

> **Нулевое оборудование, нулевая стоимость**: весь процесс использует бесплатное ПО (Modbus Slave) для моделирования нижнего оборудования, не требует покупки оборудования управления; код напрямую использует официальные модули Qt QModbusTcpClient + Qt Charts, не нужно ручном разбирать протокол; после запуска видишь реальные тренды давления, оповещения при превышении порога, логирование ошибок, эффект как на настоящей фабрике.

## 1.1 Что такое верхнее и нижнее оборудование?

В промышленной автоматизации есть два концепта, которые ты ОБЯЗАТЕЛЬНО должен понять: **верхнее оборудование (upper computer)** и **нижнее оборудование (lower computer)**.

**Нижнее оборудование (Lower Computer)** — "руки и ноги" на месте

Нижнее оборудование — это контроллер, который напрямую взаимодействует с физическими устройствами. На фабрике это обычно **PLC (программируемый логический контроллер)** или **датчик**, отвечающий за:

* Чтение данных в реальном времени (температура, давление, расход, уровень жидкости……)
* Управление оборудованием (запуск помпы, закрытие клапана, регулировка скорости……)
* Автоматическое выполнение логики (если давление превышено, останови помпу)

Ты можешь думать о нижнем оборудовании как о "рабочем" на фабрике — ему не нужно много думать, но он должен надёжно выполнять задачи.

**Верхнее оборудование (Upper Computer)** — "глаза и мозг" в контрольной комнате

Верхнее оборудование — это программное обеспечение мониторинга, которое работает на ПК или промышленном компьютере, то есть **HMI (Human-Machine Interface, интерфейс человеко-машинный)**, который мы сегодня разработаем. Оно отвечает за:

* Реальное отображение данных (цифры, диаграммы, анимация)
* Запись истории и оповещений с ошибками
* Позволить оператору управлять оборудованием удалённо
* Обеспечить анализ данных и отчёты

Ты можешь думать о верхнем оборудовании как о "контролёре" на фабрике — оно сидит перед экраном и контролирует весь процесс.

**Как они разговаривают?**

Верхнее и нижнее оборудование обмениваются данными через **промышленный коммуникационный протокол**. Самый используемый протокол — это **Modbus** — "старожил" с 1979 года, но все ещё самый широко используемый в промышленности, потому что он простой, надёжный, почти все промышленные устройства его поддерживают.

```
Контрольная комната                              Место на фабрике
┌──────────┐    Протокол Modbus    ┌──────────┐
│  Верхнее  │ ◄──────────────────► │  Нижнее   │
│ оборуд    │   "Скажи мне давл"   │ оборуд    │
│ (Qt HMI) │   "Давл 1.20MPa"     │ (PLC/датчик)│
│          │                       │ Читай датч │
│ Показывай│                       │ Управляй  │
│ Логирование│                       │ Защита    │
│ Оповещ   │                       │           │
└──────────┘                       └──────────┘
```

## 1.2 Что такое протокол Modbus?

Modbus — это "普通话" промышленной коммуникации. Определяет правила "как верхнее и нижнее оборудование разговаривают".

**Ядро только два концепта:**

* **Register (регистр)**: "ячейка" для хранения данных в нижнем оборудовании. Каждая имеет адрес (0, 1, 2……), внутри хранится число. Например адрес 0 хранит давление, адрес 1 хранит температуру.
* **Read/Write операции**: верхнее может "читать" регистр (получать данные) или "писать" регистр (отправлять команды).

**У Modbus два популярных типа:**

| Тип | Передача | Сценарий использования |
|-----|---------|---------|
| Modbus RTU | Последовательный порт (RS-485/RS-232) | Короткая дистанция, прямое соединение |
| Modbus TCP | Ethernet (TCP/IP) | Дальние расстояния, сетевая коммуникация |

Этот урок использует **Modbus TCP**, потому что это основано на сети, мы можемо на одном ПК запустить верхнее и модель нижнего оборудования, не нужны физические провода.

## 1.3 Почему выбираем Qt?

Qt — это одна из лучших платформ для разработки промышленного ПО, многие системы мониторинга на фабриках, больницах, системах транспорта используют Qt. Причины простые:

| Преимущество | Описание |
|---------|---------|
| Кроссплатформенность | Один код компилируется на Windows, Linux, встраиваемые устройства |
| Встроенные промышленные протоколы | Модуль Qt Serial Bus нативно поддерживает Modbus, не нужны библиотеки |
| Мощные диаграммы | Модуль Qt Charts обеспечивает профессиональные графики в реальном времени |
| Высокая производительность | C++ основа, подходит для рефреша данных в реальном времени |
| Стабильность | 30 лет истории, провожена промышленностью много раз |

## 1.4 Что мы разрабатываем?

Мы создадим **систему мониторинга давления в воде HMI**, моделируя реальный сценарий мониторинга на фабрике:

| Функция | Описание |
|---------|---------|
| Читай данные в реальном времени | Каждую секунду читай значение давления с нижнего оборудования и показывай |
| Тренд давления | Показывай линейный график последних 60 секунд изменение давления |
| Оповещение при превышении | Когда давление превышит установленный порог, появится окно предупреждение, интерфейс покраснеет |
| Лог ошибок | Все события оповещения записаны в SQLite БД, можно посмотреть историю |
| Ручное управление | Одна кнопка для запуска/остановки помпы (пиши в регистр нижнего оборудования) |

## 1.5 Дорожная карта этого урока

Мы будем выполнять в следующие шаги:

1. **Подготовка окружения и модели нижнего оборудования** (2 минуты): установить Qt 6.5 и Modbus Slave имитатор
2. **Создать Qt проект и подключиться к Modbus** (3 минуты): создать верхнее оборудование и устанавливаю связь с ниж оборудованием
3. **Реализовать чтение данных в реальном времени и показ** (3 минуты): читай давление данные каждую секунду и обновляй экран
4. **Рисовать тренд давления в реальном времени** (3 минуты): используй Qt Charts для рисования динамичной линии графика
5. **Реализовать систему оповещений и логирование ошибок** (3 минуты): превышение порога оповещение + SQLite запись истории
6. **Упаковка и развёртывание** (опционально): упаковать приложение и выпустить

[Продолжение урока о Qt...]

# Глава 2: Подготовка окружения и модели нижнего оборудования (2 минуты)

## 2.1 Установить Qt 6.5

Qt предоставляет свободную открытую версию, достаточно для наших целей.

1. Заходи на [Qt официальный сайт](https://www.qt.io/download-qt-installer), скачай Qt Online Installer
2. Запусти установщик, зарегистрируйся или логинься на Qt аккаунт (свободно)
3. На странице выбора компонентов, выбери:
   - **Qt 6.5.x** (или выше версия)
   - В **Additional Libraries** выбери **Qt Serial Bus** (поддержка Modbus)
   - В **Additional Libraries** выбери **Qt Charts** (рисование графиков)
   - **Qt Creator** (IDE, обычно по умолчанию)
4. Кликни Установить, подожди завершения

> **Совет**: Если уже установлен Qt но без Serial Bus или Charts модулей, запусти Qt Maintenance Tool, в "Add or Remove Components" добавь модули.

## 2.2 Установить Modbus Slave — твой "виртуальный насос"

Modbus Slave — бесплатное ПО для моделирования Modbus ведомого (устройства на фабрике). Может на твоём ПК имитировать промышленное оборудование.

1. Заходи [modbustools.com](https://www.modbustools.com/modbus_slave.html), скачай Modbus Slave
2. Установи и открой программу
3. Настрой подключение:
   - Кликни меню **Connection → Connect**
   - Выбери **Modbus TCP/IP**
   - IP адрес заполни `127.0.0.1` (локальный компьютер)
   - Порт заполни `502` (стандартный Modbus TCP порт)
   - Кликни **OK** для начала прослушивания

4. Установи модель данные:
   - Ты видишь таблицу регистров, каждая строка — адрес (0, 1, 2……)
   - Дважды кликни адрес **0** значение, измени на **120** (обозначает давление 1.20 MPa, программа разделит на 100)
   - Дважды кликни адрес **1** значение, измени на **350** (обозначает температура 35.0°C)
   - Дважды кликни адрес **2** значение, измени на **1** (обозначает статус насоса: 1=работает, 0=остановлен)

Теперь Modbus Slave — твой "24-часовой работающий виртуальный насос" — держи окно открыто, оно будет отвечать на запросы верхнего оборудования.

> **Совет для динамики**: Modbus Slave поддерживает auto-increment или случайные изменения. Правый клик значение регистра, выбери "Auto increment" или "Random", модель будет показывать реальные волны данных датчика, делая графики более динамичными.

# Глава 3: Создать Qt проект и подключиться к Modbus (3 минуты)

## 3.1 Создать новый Qt проект

Открой Qt Creator, создай новый проект:

1. Кликни **File → New Project**
2. Выбери **Application (Qt) → Qt Widgets Application**
3. Имя проекта заполни **PumpHMI**
4. Выбери установленный Qt 6.5 Kit
5. Завершить создание

Открой файл `PumpHMI.pro` (или `CMakeLists.txt` если используется CMake), добавь два ключевых модуля:

```pro
QT += core gui widgets serialbus charts sql
```

| Модуль | Функция |
|--------|---------|
| `serialbus` | Предоставляет QModbusTcpClient для Modbus TCP коммуникации |
| `charts` | Предоставляет QChart, QLineSeries для рисования трендов |
| `sql` | Предоставляет QSqlDatabase для SQLite хранилища логов ошибок |

Если используется CMake, конфиг:

```cmake
find_package(Qt6 REQUIRED COMPONENTS Widgets SerialBus Charts Sql)
target_link_libraries(PumpHMI PRIVATE
    Qt6::Widgets Qt6::SerialBus Qt6::Charts Qt6::Sql)
```

## 3.2 Объявить основные члены класса

Попроси AI помочь написать заголовочный файл:

```
Помоги написать mainwindow.h для HMI мониторинга насоса:
1. QModbusTcpClient для Modbus TCP коммуникации
2. QTimer для периодического чтения данных
3. QChart + QLineSeries для рисования тренда давления в реальном времени
4. QSqlDatabase для хранилища логов ошибок в SQLite
5. UI элементы: метка давления, индикатор статуса, кнопка старт/стоп, таблица логов
```

Основной заголовочный файл:

```cpp
// mainwindow.h
#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QModbusTcpClient>
#include <QModbusDataUnit>
#include <QTimer>
#include <QtCharts>
#include <QSqlDatabase>
#include <QLabel>
#include <QPushButton>
#include <QTableWidget>

class MainWindow : public QMainWindow {
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void connectModbus();        // Подключись к нижнему оборудованию
    void readPressure();         // Периодически читай давление
    void onReadReady();          // Коллбек после чтения
    void triggerAlarm(float v);  // Срабатывай оповещение
    void togglePump();           // Запуск/остановка насоса

private:
    // Modbus коммуникация
    QModbusTcpClient *m_modbusClient = nullptr;
    QTimer *m_pollTimer = nullptr;

    // Реальный тренд график
    QChart *m_chart = nullptr;
    QLineSeries *m_series = nullptr;
    QDateTimeAxis *m_axisX = nullptr;
    QValueAxis *m_axisY = nullptr;

    // База данных
    QSqlDatabase m_db;

    // UI элементы
    QLabel *m_pressureLabel = nullptr;    // Показ давления
    QLabel *m_statusLight = nullptr;      // Индикатор статуса
    QPushButton *m_pumpButton = nullptr;  // Кнопка старт/стоп
    QTableWidget *m_logTable = nullptr;   // Таблица логов

    // Пороги оповещения
    float m_alarmThreshold = 1.50f;  // Оповещение если давление > 1.50 MPa
    bool m_pumpRunning = false;

    void setupUI();
    void setupDatabase();
    void logAlarm(float pressure, const QString &message);
};

#endif // MAINWINDOW_H
```

## 3.3 Создать Modbus TCP подключение

В `mainwindow.cpp` реализуй логику подключения:

```cpp
// mainwindow.cpp — часть подключения
void MainWindow::connectModbus()
{
    m_modbusClient = new QModbusTcpClient(this);

    // Подключись к Modbus Slave имитатору
    m_modbusClient->setConnectionParameter(
        QModbusDevice::NetworkPortParameter, 502);
    m_modbusClient->setConnectionParameter(
        QModbusDevice::NetworkAddressParameter, "127.0.0.1");
    m_modbusClient->setTimeout(1000);       // Тайм-аут 1 сек
    m_modbusClient->setNumberOfRetries(3);  // Повтор 3 раза

    if (!m_modbusClient->connectDevice()) {
        statusBar()->showMessage("Не могу подключиться к нижнему оборуду!", 3000);
        return;
    }

    statusBar()->showMessage("Подключено к нижнему оборуду (127.0.0.1:502)", 3000);

    // Запусти таймер, читай каждую секунду
    m_pollTimer = new QTimer(this);
    connect(m_pollTimer, &QTimer::timeout, this, &MainWindow::readPressure);
    m_pollTimer->start(1000);  // 1000ms = 1 сек
}
```

**Объяснение кода:**

| Код | Смысл |
|-----|-------|
| `QModbusTcpClient` | Qt встроенный Modbus TCP клиент для коммуникации |
| `NetworkPortParameter, 502` | Подключись к порту 502 (совпадает с Modbus Slave) |
| `NetworkAddressParameter, "127.0.0.1"` | Подключись локальный компьютер (имитатор здесь) |
| `m_pollTimer->start(1000)` | Каждую 1 сек вызови `readPressure()` автоматически |

## 3.4 Читай данные давления

```cpp
// mainwindow.cpp — часть чтения
void MainWindow::readPressure()
{
    if (!m_modbusClient || m_modbusClient->state() != QModbusDevice::ConnectedState)
        return;

    // Построй запрос чтения: с адреса 0, читай 3 регистра
    QModbusDataUnit readUnit(
        QModbusDataUnit::HoldingRegisters,  // тип регистра
        0,                                   // стартовый адрес
        3                                    // количество для чтения
    );

    // Отправь запрос чтения (асинхронно)
    if (auto *reply = m_modbusClient->sendReadRequest(readUnit, 1)) {
        if (!reply->isFinished()) {
            connect(reply, &QModbusReply::finished,
                    this, &MainWindow::onReadReady);
        } else {
            delete reply;  // Для broadcast запросов
        }
    }
}

void MainWindow::onReadReady()
{
    auto *reply = qobject_cast<QModbusReply *>(sender());
    if (!reply) return;

    if (reply->error() == QModbusDevice::NoError) {
        const QModbusDataUnit unit = reply->result();

        // Парси данные (значения регистра делим на 100 для реального значения)
        float pressure = unit.value(0) / 100.0f;   // адрес 0: давление (MPa)
        float temperature = unit.value(1) / 10.0f;  // адрес 1: температура (°C)
        int pumpStatus = unit.value(2);              // адрес 2: статус насоса

        // Обнови UI показ
        m_pressureLabel->setText(
            QString("%1 MPa").arg(pressure, 0, 'f', 2));

        // Проверь нужны ли оповещения
        if (pressure > m_alarmThreshold) {
            triggerAlarm(pressure);
        }

        // Обнови график (следующая глава реализует)
        // updateChart(pressure);

    } else {
        statusBar()->showMessage(
            QString("Ошибка чтения: %1").arg(reply->errorString()), 2000);
    }

    reply->deleteLater();
}
```

**Логика чтения Modbus:**

```
readPressure() срабатывает по таймеру
    → Построй QModbusDataUnit ("скажи нижнему оборуду я хочу адреса 0-2")
    → sendReadRequest() отправь запрос (асинхронно, не блокирует UI)
    → нижнее оборуд возвращает данные
    → onReadReady() срабатывает
    → Парси значения регистров, обнови UI
```

# Глава 4: Рисовать тренд давления в реальном времени (3 минуты)

## 4.1 Инициализировать график

Qt Charts предоставляет профессиональные графиков компоненты. Попроси AI помочь инициализировать в конструкторе:

```
Помоги инициализировать Qt Charts реальный тренд график давления в MainWindow:
1. Создай QChart и QLineSeries
2. X ось — временная (QDateTimeAxis), показывай последние 60 сек
3. Y ось — значение (QValueAxis), диапазон 0-3.0 MPa
4. Линия синяя, толщина 2px
5. Добавь График в QChartView и в UI макет
```

Основной код:

```cpp
// mainwindow.cpp — инициализация графика
void MainWindow::setupChart()
{
    m_series = new QLineSeries();
    m_series->setName("Давление (MPa)");
    m_series->setPen(QPen(QColor("#2196F3"), 2));

    m_chart = new QChart();
    m_chart->addSeries(m_series);
    m_chart->setTitle("Реальный тренд давления");
    m_chart->setAnimationOptions(QChart::NoAnimation); // реальные данные без анимации

    // X ось: время
    m_axisX = new QDateTimeAxis();
    m_axisX->setFormat("HH:mm:ss");
    m_axisX->setTitleText("Время");
    m_chart->addAxis(m_axisX, Qt::AlignBottom);
    m_series->attachAxis(m_axisX);

    // Y ось: давление
    m_axisY = new QValueAxis();
    m_axisY->setRange(0, 3.0);
    m_axisY->setTitleText("Давление (MPa)");
    m_axisY->setLabelFormat("%.1f");
    m_chart->addAxis(m_axisY, Qt::AlignLeft);
    m_series->attachAxis(m_axisY);

    // Создай вид графика
    QChartView *chartView = new QChartView(m_chart);
    chartView->setRenderHint(QPainter::Antialiasing);

    // Добавь в макет (предполагается что centralLayout существует)
    centralLayout->addWidget(chartView);
}
```

## 4.2 Обновить графикданные в реальном времени

Каждый раз читай новое давление, добавь точку в линию и держи только последние 60 сек:

```cpp
// mainwindow.cpp — обновление графика
void MainWindow::updateChart(float pressure)
{
    QDateTime now = QDateTime::currentDateTime();

    // Добавь новую точку данных
    m_series->append(now.toMSecsSinceEpoch(), pressure);

    // Держи только последние 60 сек (не растёт память бесконечно)
    QDateTime cutoff = now.addSecs(-60);
    while (m_series->count() > 0 &&
           m_series->at(0).x() < cutoff.toMSecsSinceEpoch()) {
        m_series->remove(0);
    }

    // Обнови X ось диапазон: всегда показывай последние 60 сек
    m_axisX->setRange(cutoff, now);
}
```

Потом вызови это в `onReadReady()` после разбора давления:

```cpp
// В onReadReady(), после разбора давления добавь:
updateChart(pressure);
```

Теперь запусти программу, ты увидишь синюю линию скользящую в реальном времени — каждую секунду добавляется новая точка, всегда показаны последние 60 сек изменений давления. Если в Modbus Slave вручную изменить регистр, линия сразу отобразит изменение.

# Глава 5: Система оповещений и логирование (3 минуты)

## 5.1 Оповещение при превышении порога

Когда давление превышит установленный порог, нужно:界面покраснеть + всплывающее окно + запись в БД.

```cpp
// mainwindow.cpp — логика оповещения
void MainWindow::triggerAlarm(float pressure)
{
    //界面давления покраснеет
    m_pressureLabel->setStyleSheet(
        "color: white; background-color: #F44336;"
        "font-size: 32px; padding: 10px; border-radius: 8px;");

    // индикатор статуса красный
    m_statusLight->setStyleSheet(
        "background-color: #F44336; border-radius: 12px;"
        "min-width: 24px; min-height: 24px;");

    // Всплывающее окно (только в первый раз превышения, не повторять)
    static bool alarmActive = false;
    if (!alarmActive) {
        alarmActive = true;
        QMessageBox::warning(this, "Оповещение давления",
            QString("Текущее давление %1 MPa превышило порог %2 MPa!\n"
                    "Немедленно проверь статус насоса.")
                .arg(pressure, 0, 'f', 2)
                .arg(m_alarmThreshold, 0, 'f', 2));
    }

    // Запиши в БД
    logAlarm(pressure,
        QString("Давление превышило порог: %1 MPa > %2 MPa")
            .arg(pressure, 0, 'f', 2)
            .arg(m_alarmThreshold, 0, 'f', 2));

    // Давление восстановилось, сбрось оповещение
    if (pressure <= m_alarmThreshold) {
        alarmActive = false;
        m_pressureLabel->setStyleSheet(
            "color: #2196F3; font-size: 32px; padding: 10px;");
        m_statusLight->setStyleSheet(
            "background-color: #4CAF50; border-radius: 12px;"
            "min-width: 24px; min-height: 24px;");
    }
}
```

## 5.2 SQLite хранилище логов

Промышленные системы ОБЯЗАТЕЛЬНО записывают все события, для потом проверки. Используем SQLite:

```cpp
// mainwindow.cpp — инициализация БД
void MainWindow::setupDatabase()
{
    m_db = QSqlDatabase::addDatabase("QSQLITE");
    m_db.setDatabaseName("pump_alarm_log.db");

    if (!m_db.open()) {
        qWarning() << "Не могу открыть БД:" << m_db.lastError().text();
        return;
    }

    // Создай таблицу логов оповещений
    QSqlQuery query;
    query.exec(
        "CREATE TABLE IF NOT EXISTS alarm_log ("
        "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,"
        "  pressure REAL,"
        "  message TEXT"
        ")"
    );
}
```

## 5.3 Запиши и показывай логи

```cpp
// mainwindow.cpp — логирование
void MainWindow::logAlarm(float pressure, const QString &message)
{
    // Запиши в БД
    QSqlQuery query;
    query.prepare(
        "INSERT INTO alarm_log (pressure, message) VALUES (?, ?)");
    query.addBindValue(pressure);
    query.addBindValue(message);
    query.exec();

    // Одновременно обнови UI таблицу логов
    int row = m_logTable->rowCount();
    m_logTable->insertRow(row);
    m_logTable->setItem(row, 0,
        new QTableWidgetItem(
            QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss")));
    m_logTable->setItem(row, 1,
        new QTableWidgetItem(QString::number(pressure, 'f', 2)));
    m_logTable->setItem(row, 2,
        new QTableWidgetItem(message));

    // Автопрокрутка вниз к последней
    m_logTable->scrollToBottom();
}
```

Таблица логов показывает три колонны: время, давление, сообщение оповещения. Каждый раз оповещение автоматически добавляется строка, одновременно записывается в SQLite БД.

## 5.4 Управление насосом вручную

Верхнее не только читает, но и управляет. Запуск/остановка через запись в регистр:

```cpp
// mainwindow.cpp — управление
void MainWindow::togglePump()
{
    if (!m_modbusClient || m_modbusClient->state() != QModbusDevice::ConnectedState)
        return;

    m_pumpRunning = !m_pumpRunning;

    // Построй запрос записи: адрес 2 пиши 1 (старт) или 0 (стоп)
    QModbusDataUnit writeUnit(
        QModbusDataUnit::HoldingRegisters, 2, 1);
    writeUnit.setValue(0, m_pumpRunning ? 1 : 0);

    if (auto *reply = m_modbusClient->sendWriteRequest(writeUnit, 1)) {
        connect(reply, &QModbusReply::finished, this, [this, reply]() {
            if (reply->error() == QModbusDevice::NoError) {
                m_pumpButton->setText(m_pumpRunning ? "Остановить насос" : "Запустить насос");
                m_pumpButton->setStyleSheet(m_pumpRunning
                    ? "background-color: #F44336; color: white; padding: 12px;"
                    : "background-color: #4CAF50; color: white; padding: 12px;");
                statusBar()->showMessage(
                    m_pumpRunning ? "Насос запущен" : "Насос остановлен", 2000);
            }
            reply->deleteLater();
        });
    }
}
```

В Modbus Slave ты видишь адрес 2 значение переключается между 0 и 1 — вот это верхнее "управляет" нижним!

# Глава 6: Упаковка и развёртывание (опционально)

## 6.1 Использовать windeployqt / macdeployqt

Qt предоставляет официальные инструменты развёртывания:

**Windows:**

```bash
# Сначала построй Release версию, потом в папке построения:
windeployqt PumpHMI.exe
```

`windeployqt` автоматически скопирует все DLL, плагины, файлы переводов которые требует приложение, папка готова раздать другим.

**macOS:**

```bash
macdeployqt PumpHMI.app -dmg
```

Создаст `.dmg` инсталяционный образ, двойной клик устанавливает.

## 6.2 Используй Qt Installer Framework

Если нужен профессиональный инсталлер (типа "Далее → Далее → Готово"):

```
Помоги создать инсталлер для PumpHMI используя Qt Installer Framework:
1. Создай installer директорию (config, packages)
2. Конфигурируй config.xml (имя инсталлера, версия, папка установки)
3. Поместь windeployqt выходные файлы в packages/com.example.pumphmi/data/
4. Запусти binarycreator для создания инсталлера
```

# Глава 7: На этом всё

Поздравляю! Ты построил промышленную систему мониторинга с нуля. Вспомни что сделали:

1. Понял верхнее/нижнее оборуд и Modbus протокол
2. Использовал Modbus Slave имитировать "виртуальный насос", без настоящего оборуда
3. Qt QModbusTcpClient создал верхнее оборуд и подключение
4. Qt Charts рисовал реальный тренд давления с прокруткой
5. Реализовал оповещение превышения порога + SQLite логирование истории
6. Реализовал удалённое управление насоса (запуск/остановка)

Весь процесс без настоящего оборуда, но архитектура и функции полностью совпадают с реальной фабричной системой HMI. Просто замени Modbus Slave на настоящий PLC/датчик, это приложение будет работать на реальной фабрике.

**Направления развития:**

* **Мультиустройство мониторинг**: одновременно подключись к нескольким нижним оборудам, вкладки или разделение экрана для разных
* **История данные воспроизведение**: читай SQLite историю, слайдер воспроизводить любой период трендов
* **OPC UA протокол**: Modbus для простых, OPC UA для сложных промышленных систем, Qt OPC UA модуль поддерживает
* **Web удалённый мониторинг**: Qt WebSocket отправляй реальные данные в браузер, мобильное управление
* **AI прогнозная поддержка**: истории давления в ML модель, предскажи отказ оборуда заранее

***Защищай каждое оборудование на фабрике с помощью кода.***

# Справочные материалы

* [Qt Serial Bus официальная документация](https://doc.qt.io/qt-6/qtserialbus-index.html)
* [Qt Modbus TCP Client пример](https://doc.qt.io/qt-6/qtserialbus-modbus-client-example.html)
* [Qt Charts документация](https://doc.qt.io/qt-6/qtcharts-index.html)
* [Modbus спецификация](https://modbus.org/specs.php)
* [Modbus Slave имитатор](https://www.modbustools.com/modbus_slave.html)
* [Qt Installer Framework документация](https://doc.qt.io/qtinstallerframework/)
