## Purpose

Определить поведение создания LaunchAgent-конфига из меню приложения: форма ввода, валидация, генерация plist и обработка ошибок.

## Requirements

### Requirement: Действие создания LaunchAgent-конфига доступно из меню
Система SHALL предоставить пункт меню, который открывает редактор LaunchAgent-конфига.

#### Scenario: Пользователь открывает редактор конфига
- **WHEN** пользователь выбирает пункт меню для добавления конфига
- **THEN** система показывает одно окно редактора
- **THEN** окно содержит поля ввода для `name`, `command`, `path-to-start` и опционального `WorkingDirectory`
- **THEN** окно содержит кнопки "Отмена" и "Применить"

#### Scenario: Пользователь отменяет создание конфига
- **WHEN** пользователь нажимает "Отмена" в окне редактора
- **THEN** система закрывает окно редактора
- **THEN** система не создает plist-файл

### Requirement: Ввод LaunchAgent-конфига валидируется
Система SHALL требовать непустые значения `name`, `command` и `path-to-start` перед записью plist.

#### Scenario: Обязательное поле не заполнено
- **WHEN** пользователь нажимает "Применить" с пустым `name`, `command` или `path-to-start`
- **THEN** система не создает plist-файл
- **THEN** система показывает ошибку валидации

#### Scenario: Имя небезопасно
- **WHEN** пользователь нажимает "Применить" с именем, которое нельзя безопасно использовать как суффикс label, часть имени файла и имя директории логов
- **THEN** система не создает plist-файл
- **THEN** система показывает ошибку валидации

### Requirement: LaunchAgent plist генерируется из значений редактора
Система SHALL создавать plist по пути `/Users/agaibadulin/Library/LaunchAgents/com.agaibadulin.<name>.plist`, используя значения из редактора.

#### Scenario: Пользователь применяет валидный ввод
- **WHEN** пользователь применяет name `groovy-agent`, command `/opt/homebrew/bin/node`, path-to-start `server.js` и WorkingDirectory `/Users/agaibadulin/Desktop/projects/vibe/groovy_agent`
- **THEN** система записывает `/Users/agaibadulin/Library/LaunchAgents/com.agaibadulin.groovy-agent.plist`
- **THEN** plist Label равен `com.agaibadulin.groovy-agent`
- **THEN** plist ProgramArguments содержит `/opt/homebrew/bin/node` и `server.js` именно в таком порядке
- **THEN** plist WorkingDirectory равен `/Users/agaibadulin/Desktop/projects/vibe/groovy_agent`
- **THEN** plist RunAtLoad равен true
- **THEN** plist KeepAlive равен true

#### Scenario: WorkingDirectory не указан
- **WHEN** пользователь применяет валидные `name`, `command` и `path-to-start` без `WorkingDirectory`
- **THEN** система записывает plist без ключа `WorkingDirectory`

### Requirement: Пути логов LaunchAgent выводятся из имени
Система SHALL выводить пути stdout и stderr логов из введенного имени и создавать директорию логов при необходимости.

#### Scenario: Пути логов сгенерированы
- **WHEN** пользователь применяет валидный ввод с name `groovy-agent`
- **THEN** plist StandardOutPath равен `/Users/agaibadulin/Library/Logs/groovy-agent/stdout.log`
- **THEN** plist StandardErrorPath равен `/Users/agaibadulin/Library/Logs/groovy-agent/error.log`
- **THEN** система гарантирует наличие директории `/Users/agaibadulin/Library/Logs/groovy-agent`

### Requirement: Существующий LaunchAgent-конфиг не перезаписывается молча
Система SHALL предотвращать тихую перезапись, если целевой plist уже существует.

#### Scenario: Целевой plist уже существует
- **WHEN** пользователь применяет валидный ввод, для которого целевой plist уже существует
- **THEN** система не перезаписывает существующий plist
- **THEN** система показывает ошибку о том, что конфиг уже существует

### Requirement: Результат создания конфига виден пользователю
Система SHALL сообщать, успешно или с ошибкой завершилось создание LaunchAgent-конфига.

#### Scenario: Конфиг создан успешно
- **WHEN** система успешно создает plist
- **THEN** система показывает пользователю путь созданного plist

#### Scenario: Создание конфига завершилось ошибкой
- **WHEN** файловая система или запись plist возвращает ошибку
- **THEN** система показывает ошибку с причиной сбоя

### Requirement: Редактор поддерживает вставку скопированных значений
Система SHALL поддерживать стандартные действия редактирования текста в полях окна создания LaunchAgent-конфига.

#### Scenario: Пользователь вставляет значение в поле редактора
- **WHEN** пользователь фокусирует любое текстовое поле окна Add Config
- **WHEN** пользователь выполняет стандартное действие вставки
- **THEN** система вставляет содержимое буфера обмена в это поле
- **THEN** система не создает plist-файл до нажатия "Применить"

#### Scenario: Пользователь копирует или выделяет текст в поле редактора
- **WHEN** пользователь фокусирует любое текстовое поле окна Add Config
- **WHEN** пользователь выполняет стандартное действие копирования, вырезания или выделения всего текста
- **THEN** система применяет действие к активному текстовому полю
- **THEN** система не изменяет остальные поля редактора

### Requirement: Команда может быть преобразована через which
Система SHALL предоставить действие `Which` для поля `command`, которое преобразует имя команды в путь к исполняемому файлу.

#### Scenario: Пользователь преобразует node в абсолютный путь
- **WHEN** пользователь вводит `node` в поле `command`
- **WHEN** пользователь нажимает `Which`
- **THEN** система запускает `which node` с PATH, включающим `/opt/homebrew/bin`
- **THEN** при успешном результате система подставляет найденный путь в поле `command`

#### Scenario: Which сохраняет значение при ошибке
- **WHEN** пользователь вводит команду, которую `which` не может найти
- **WHEN** пользователь нажимает `Which`
- **THEN** система оставляет прежнее значение поля `command`
- **THEN** система показывает ошибку с причиной сбоя

#### Scenario: Which требует непустую команду
- **WHEN** поле `command` пустое
- **WHEN** пользователь нажимает `Which`
- **THEN** система не запускает `which`
- **THEN** система показывает ошибку валидации
