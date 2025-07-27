# Telegram Reminder Bot в Docker
[![Build and Push Docker](https://github.com/vsuh/cron-tg-docker/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/vsuh/cron-tg-docker/actions/workflows/build-and-push.yml)

Это Docker-версия проекта [reminder-tgm](https://github.com/vsuh/reminder-tgm). Бот позволяет создавать и управлять напоминаниями через веб-интерфейс, отправляя уведомления в Telegram по расписанию.

## Особенности

- Веб-интерфейс для управления напоминаниями
- Поддержка CRON-выражений для гибкой настройки расписания
- Отправка уведомлений в различные Telegram чаты (от имени телеграм-бота)
- Контейнеризация с использованием Docker
- Сохранение данных в БД SQLite
- Ротация логов

## Требования

- Docker
- Docker Compose
- Telegram Bot Token
- CHAT_ID Telegram чата для отправки уведомлений

## Установка и запуск

1. Клонируйте репозиторий:
   ```bash
   git clone https://github.com/vsuh/cron-tg-docker.git
   cd cron-tg-docker
   ```

2. Создайте файл с переменными окружения `.env`

3. Отредактируйте файл `.env`:
актуальную версия примера `.env` файла нужно смотреть в соответствующем [репозитории](https://github.com/vsuh/reminder-tgm/blob/master/env/.env.SAMLPE).
Убедитесь, что значение переменной TLCR_FLASK_PORT в `.env` файле и правая часть выражения [ports](https://github.com/vsuh/cron-tg-docker/blob/cb34851ef50964f790ef9e3d9264bd35c8960c0a/docker-compose.yml#L6) совпадают
 
4. Создайте необходимые директории для базы данных и протоколов. В контейнере программы запускаются от имени пользователя `appuser(5678)`
   ```bash
   mkdir -p /opt/cron-reminder/{log,db}
   chown -R 5678:5678 /opt/cron-reminder/*
   ```

5. Запустите контейнер:
   ```bash
   docker compose up -d
   ```

## Структура проекта

- `web_prod.sh` - скрипт запуска веб-сервера (gunicorn)
- `rund_prod.sh` - скрипт запуска планировщика задач
- `start.sh` - точка входа контейнера
- `log/` - директория для логов
- `db/` - директория с базой данных SQLite
- `.env` - конфигурационный файл

## Порты и URL

- Веб-интерфейс доступен по адресу: `http://localhost:7878`
- Внутренний порт gunicorn: 7999

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
- `/opt/cron-reminder/.env` - конфигурация
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
