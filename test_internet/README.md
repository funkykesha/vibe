# Internet Speed Monitor

MVP мониторинга скорости интернета на macOS. Меряет два профиля:

- **vpn** — через дефолтный маршрут (Tunnelblick/utun), `networkQuality -c`.
- **modem** — обход VPN через `--interface en0` (curl на cachefly + ping).

Хранит NDJSON, отдаёт дашборд на `http://localhost:9876`.

## Запуск

```bash
python3 internet_speed_monitor.py doctor    # проверка окружения
python3 internet_speed_monitor.py sample    # один цикл замера
python3 internet_speed_monitor.py server    # дашборд на :9876
```

Override модемного интерфейса: `SPEED_MODEM_IFACE=en1 python3 ...`.

## Файлы

- `data/speed-tests.ndjson` — одна JSON-строка на тест.
- `logs/internet-speed.log` — текстовые логи.

## launchd (автозапуск)

Sampler встроен в server-процесс. Достаточно одного агента.

```bash
cp launchd/com.user.speedmon.server.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.user.speedmon.server.plist
```

Снять:
```bash
launchctl unload ~/Library/LaunchAgents/com.user.speedmon.server.plist
```

Интервал авто-сэмпла меняется из дашборда. По умолчанию 30 мин. Override стартового значения: `SPEED_INTERVAL_MIN=10`.

## API

- `GET /` — HTML дашборд (Chart.js, 2 графика: vpn / modem).
- `GET /api/series?bucket=30m|1h|3h|6h|12h|1d` — trimmed median + count по бакетам.
- `GET /api/logs?limit=200` — текстовые логи.
- `GET /api/state` — `{interval_min, last_sample_ts, sampling}`.
- `POST /api/sample` — принудительный sample. Возвращает `{started}`.
- `POST /api/interval?minutes=15` — сменить интервал авто-сэмпла. `0` = выкл.

## Схема записи

```json
{
  "ts": 1779786626.99,
  "profile": "modem|vpn",
  "method": "networkQuality|curl-bound",
  "interface_name": "utun4|en0",
  "source_ip": "192.168.88.248",
  "public_ip": "94.29.16.137",
  "bypass_verified": true,
  "download_mbps": 165.13,
  "upload_mbps": null,
  "ping_ms": 23.81,
  "ok": true,
  "error": "...",
  "duration_sec": 24.33
}
```

