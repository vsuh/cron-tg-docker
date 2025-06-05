# Telegram Reminder Bot в Docker

Это Docker-версия проекта [reminder-tgm](https://github.com/vsuh/reminder-tgm). Бот позволяет создавать и управлять напоминаниями через веб-интерфейс, отправляя уведомления в Telegram по расписанию.

## Особенности

- Веб-интерфейс для управления напоминаниями
- Поддержка CRON-выражений для гибкой настройки расписания
- Отправка уведомлений в различные Telegram чаты
- Контейнеризация с использованием Docker
- Сохранение данных в SQLite
- Ротация логов

## Требования

- Docker
- Docker Compose
- Telegram Bot Token
- ID Telegram чата для отправки сообщений

## Установка и запуск

1. Клонируйте репозиторий:
   ```bash
   git clone https://github.com/your-username/cron-tg-docker.git
   cd cron-tg-docker
   ```

2. Создайте файл с переменными окружения:
   ```bash
   mkdir -p /opt/cron-reminder/env
   cp env/.env.example /opt/cron-reminder/env/.env.prod
   ```

3. Отредактируйте файл `.env.prod`:
   ```env
   TLCR_SECRET_KEY=your-secret-key
   DEBUG=False
   TLCR_TELEGRAM_TOKEN=your-telegram-bot-token
   TLCR_TELEGRAM_CHAT_ID=your-default-chat-id
   TLCR_TZ=Europe/Moscow
   TLCR_DB_PATH=db/settings.db
   TLCR_LOGPATH=log
   TLCR_LOG_LEVEL=INFO
   TLCR_FLASK_PORT=7000
   ```

4. Создайте необходимые директории:
   ```bash
   mkdir -p /opt/cron-reminder/{log,db}
   ```

5. Запустите контейнер:
   ```bash
   docker compose up -d
   ```

## Структура проекта

- `web_prod.sh` - скрипт запуска веб-сервера (gunicorn)
- `rund_prod.sh` - скрипт запуска планировщика задач
- `log/` - директория для логов
- `db/` - директория с базой данных SQLite
- `env/` - конфигурационные файлы окружения

## Порты и URL

- Веб-интерфейс доступен по адресу: `http://localhost:7111`
- Внутренний порт gunicorn: 7878
- Внешний порт: 7111

## Логи

Логи приложения сохраняются в директории `/opt/cron-reminder/log/`:
- `web_app.log` - логи веб-приложения
- `db_utils.log` - логи операций с базой данных
- `gunicorn-access.log` - логи доступа к веб-серверу
- `gunicorn-error.log` - логи ошибок веб-сервера

## Обновление

Для обновления до новой версии:

1. Измените версию в переменной окружения `TAG` в `Dockerfile`
2. Пересоберите и перезапустите контейнер:
   ```bash
   docker compose down
   docker compose up -d --build
   ```

## Резервное копирование

Все важные данные хранятся в директориях:
- `/opt/cron-reminder/db/` - база данных
- `/opt/cron-reminder/env/` - конфигурация
- `/opt/cron-reminder/log/` - логи

Для резервного копирования достаточно сохранить эти директории.

## Устранение неполадок

1. Проверка статуса контейнера:
   ```bash
   docker compose ps
   ```

2. Просмотр логов:
   ```bash
   docker compose logs -f
   ```

3. Проверка прав доступа:
   ```bash
   ls -la /opt/cron-reminder/{log,db}
   ```

## Лицензия

Этот проект является Docker-оберткой для [reminder-tgm](https://github.com/vsuh/reminder-tgm) и распространяется под той же лицензией.


### Note

> чтобы получить хеш для проверки целостности архива надо в `github.com` на странице релизов [репозитария](https://github.com/vsuh/reminder-tgm/releases) сделать очередной релиз и url tar.gz архива релиза вставить в команду:

```sh 
curl -sL https://github.com/vsuh/reminder-tgm/archive/refs/tags/v1.0.1.tar.gz | sha256sum
```