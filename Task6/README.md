# Task6 — Аудит активности пользователей

## Файлы

| Файл | Назначение                                                                |
|------|---------------------------------------------------------------------------|
| [analysis.md](analysis.md) | Отчёт по обнаруженным инцидентам в audit.log                              |
| [audit-extract.json](audit-extract.json) | Выжимка подозрительных событий из audit.log                               |
| [audit.log](logs/audit.log) | Сырой лог (1399 строк) для самостоятельного анализа                       |
| [audit-filter.py](audit-filter.py) | Скрипт фильтрации: `python3 audit-filter.py logs/audit.log > result.json` |
