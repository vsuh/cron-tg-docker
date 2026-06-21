# Telegram Reminder Bot в Docker

[![Build and Push Docker](https://github.com/vsuh/cron-tg-docker/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/vsuh/cron-tg-docker/actions/workflows/build-and-push.yml)
[![Docker Hub](https://img.shields.io/badge/docker%20hub-vsuh%2Fcron--tg-blue)](https://hub.docker.com/r/vsuh/cron-tg)

Это Docker-обёртка для проекта [reminder-tgm](https://github.com/vsuh/reminder-tgm) — приложения для отправки напоминаний в Telegram (и опционально в [ntfy](https://ntfy.sh)) по расписанию на основе `cron`-выражений. Образ собирает исходники `reminder-tgm` нужной версии и запускает в одном контейнере веб-интерфейс и фоновый демон рассылки.

## Содержание

- [Особенности](#особенности)
- [Требования](#требования)
- [Установка и запуск](#установка-и-запуск)
- [Структура репозитория](#структура-репозитория)
- [Порты и URL](#порты-и-url)
- [Переменные окружения](#переменные-окружения)
- [Логи](#логи)
- [Обновление образа](#обновление-образа)
- [Автоматическая сборка при новом релизе reminder-tgm](#автоматическая-сборка-при-новом-релизе-reminder-tgm)
- [Резервное копирование](#резервное-копирование)
- [Устранение неполадок](#устранение-неполадок)
- [Лицензия](#лицензия)

## Особенности

- Веб-интерфейс для управления напоминаниями, чатами Telegram и каналами ntfy.
- Поддержка `cron`-выражений и дополнительных модификаторов (`d/n`, `w/n`) для гибкой настройки расписания.
- Отправка уведомлений в разные Telegram-чаты от имени одного бота.
- Опциональное дублирование уведомлений в ntfy.
- Хранение данных в SQLite с автоматическим резервным копированием.
- Ротация логов.
- Образ автоматически пересобирается и публикуется в Docker Hub при выходе нового релиза `reminder-tgm`.

## Требования

- Docker
- Docker Compose
- Токен Telegram-бота (получить у [@BotFather](https://t.me/BotFather))
- Chat ID Telegram-чата/группы для отправки уведомлений

## Установка и запуск

1. Клонируйте репозиторий:

   ```bash
   git clone https://github.com/vsuh/cron-tg-docker.git
   cd cron-tg-docker
   ```

2. Создайте директории для конфигурации, базы данных и логов на хосте, а также сам `.env`-файл:

   ```bash
   mkdir -p /opt/cron-reminder/env /opt/cron-reminder/log /opt/cron-reminder/db
   ```

3. Подготовьте файл `/opt/cron-reminder/env/.env.prod` с переменными окружения.

   Актуальный пример `.env`-файла со всеми поддерживаемыми переменными нужно смотреть в репозитории приложения: [env/.env.SAMPLE](https://github.com/vsuh/reminder-tgm/blob/master/env/.env.SAMPLE).

   ```bash
   curl -o /opt/cron-reminder/env/.env.prod \
     https://raw.githubusercontent.com/vsuh/reminder-tgm/master/env/.env.SAMPLE
   # отредактируйте файл, указав свои значения
   ```

   Минимально необходимо задать:

   | Переменная | Назначение |
   |---|---|
   | `TLCR_TELEGRAM_TOKEN` | Токен бота от `@BotFather` |
   | `TLCR_TELEGRAM_CHAT_ID` | ID чата/группы по умолчанию |
   | `TLCR_TZ` | Временная зона сервера |
   | `TLCR_SECRET_KEY` | Секретный ключ Flask (обязательно своё значение, не из примера) |

   > **Важно:** значение переменной `TLCR_FLASK_PORT` в `.env`-файле должно совпадать с внутренним (правым) портом в секции [`ports`](docker-compose.yml) файла `docker-compose.yml` (по умолчанию контейнер слушает `7999` внутри, а наружу публикуется `7878`).

4. Права доступа: процессы в контейнере выполняются от имени пользователя `appuser` с UID/GID `5678`. Каталоги `log` и `db` на хосте должны быть доступны этому пользователю на запись:

   ```bash
   chown -R 5678:5678 /opt/cron-reminder/log /opt/cron-reminder/db
   ```

5. Запустите контейнер:

   ```bash
   docker compose up -d
   ```

6. Откройте веб-интерфейс по адресу `http://localhost:7878` (или на хосте, где запущен контейнер) и создайте хотя бы один чат на странице `/chats`, прежде чем добавлять расписания.

## Структура репозитория

| Файл | Назначение |
|---|---|
| `Dockerfile` | Сборка образа: скачивает архив указанного релиза `reminder-tgm`, устанавливает зависимости, настраивает непривилегированного пользователя `appuser` |
| `docker-compose.yml` | Запуск готового образа из Docker Hub с volume-мапингом конфигурации, БД и логов |
| `.github/workflows/build-and-push.yml` | CI: пересобирает и публикует образ при новом релизе `reminder-tgm`, обновляет тег в `Dockerfile`, шлёт уведомление в Telegram |

Внутри собранного образа (унаследовано из `reminder-tgm`) используются:

- `web_prod.sh` — запуск веб-сервера (`gunicorn`);
- `rund_prod.sh` — запуск демона-планировщика рассылки;
- `start.sh` — точка входа контейнера: запускает оба процесса параллельно и завершает работу, если один из них упал;
- `log/` — директория для логов;
- `db/` — директория с базой данных SQLite.

## Порты и URL

| Что | Значение |
|---|---|
| Веб-интерфейс снаружи контейнера | `http://localhost:7878` (настраивается в `docker-compose.yml`, секция `ports`) |
| Порт `gunicorn` внутри контейнера | `7999` (должен совпадать с `TLCR_FLASK_PORT` в `.env`) |

## Переменные окружения

Полный список переменных окружения приложения (Telegram, БД, бэкапы, веб-интерфейс, авторизация, планировщик, логирование) описан в [README проекта reminder-tgm](https://github.com/vsuh/reminder-tgm#переменные-окружения) и в файле-примере [env/.env.SAMPLE](https://github.com/vsuh/reminder-tgm/blob/master/env/.env.SAMPLE).

В `docker-compose.yml` `.env`-файл с хоста монтируется внутрь контейнера:

```yaml
volumes:
  - /opt/cron-reminder/env/.env.prod:/workspaces/cron-tg-docker/.env
```

## Логи

Логи приложения сохраняются в директории `/opt/cron-reminder/log/` на хосте:

- `web_app.log` — логи веб-приложения;
- `db_utils.log` — логи операций с базой данных;
- `rmndr.log` — логи демона рассылки;
- `gunicorn-access.log` — логи доступа к веб-серверу;
- `gunicorn-error.log` — логи ошибок веб-сервера.

Просмотр логов контейнера в реальном времени:

```bash
docker compose logs -f
```

## Обновление образа

### Вручную

1. Узнайте тег нужного релиза в репозитории [reminder-tgm](https://github.com/vsuh/reminder-tgm/releases).
2. Обновите значение `TAG` в `Dockerfile`:

   ```dockerfile
   ENV TAG="v1.6.2"
   ```

3. Пересоберите и перезапустите контейнер:

   ```bash
   docker compose down
   docker compose up -d --build
   ```

### Автоматически (готовый образ из Docker Hub)

Если используется готовый образ `docker.io/vsuh/cron-tg:latest` (как в стандартном `docker-compose.yml`), достаточно перезапустить контейнер с пересозданием:

```bash
docker compose pull
docker compose up -d
```

## Автоматическая сборка при новом релизе reminder-tgm

При публикации нового тега в репозитории `reminder-tgm` срабатывает `repository_dispatch` (`new-reminder-tgm-tag`), который запускает workflow [`build-and-push.yml`](.github/workflows/build-and-push.yml) в этом репозитории. Workflow:

1. Проверяет, что архив исходников с указанным тегом существует.
2. Обновляет переменную `TAG` в `Dockerfile` и коммитит изменение.
3. Собирает образ и публикует его в Docker Hub с тегами `<версия>` и `latest`.
4. Отправляет уведомление об успешной сборке в Telegram.

Запустить пересборку вручную можно через `workflow_dispatch` (вкладка **Actions** на GitHub, указав нужный тег), либо тестовым `repository_dispatch`-запросом — см. раздел «Тестирование цепочки workflow» в [README reminder-tgm](https://github.com/vsuh/reminder-tgm#тестирование-цепочки-workflow).

## Резервное копирование

Все важные данные хранятся в директориях на хосте:

- `/opt/cron-reminder/db/` — база данных SQLite (а также автоматические бэкапы, если настроен `TLCR_BACKUP_PATH` внутри этой директории);
- `/opt/cron-reminder/env/.env.prod` — конфигурация;
- `/opt/cron-reminder/log/` — логи.

Для резервного копирования достаточно сохранить эти директории. Само приложение также умеет создавать периодические бэкапы БД и (опционально) реплицировать их по `scp` — см. переменные `TLCR_BACKUP_*` в документации `reminder-tgm`.

## Устранение неполадок

1. Проверка статуса контейнера:

   ```bash
   docker compose ps
   ```

2. Просмотр логов:

   ```bash
   docker compose logs -f
   ```

3. Проверка прав доступа к смонтированным директориям (процессы внутри контейнера работают под UID/GID `5678`):

   ```bash
   ls -la /opt/cron-reminder/{log,db}
   ```

4. Если веб-интерфейс не открывается — убедитесь, что `TLCR_FLASK_PORT` в `.env` совпадает с внутренним портом, указанным в `docker-compose.yml` (`ports: "7878:<TLCR_FLASK_PORT>"`).

5. Если расписания не приходят — проверьте, что в веб-интерфейсе создан хотя бы один чат (`/chats`) и указан верный `TLCR_TELEGRAM_TOKEN`.

## Лицензия

Этот проект является Docker-обёрткой для [reminder-tgm](https://github.com/vsuh/reminder-tgm) и распространяется под той же лицензией ([BSD-3-Clause](https://github.com/vsuh/reminder-tgm/blob/master/LICENSE)).

### Примечание для мейнтейнера

Чтобы получить хеш для проверки целостности скачиваемого архива релиза, на странице [Releases](https://github.com/vsuh/reminder-tgm/releases) репозитория `reminder-tgm` создайте очередной релиз, а затем вычислите хеш по ссылке на `tar.gz`:

```bash
curl -sL https://github.com/vsuh/reminder-tgm/archive/refs/tags/v1.0.1.tar.gz | sha256sum
```

Полученное значение можно использовать в `Dockerfile` для директивы `ADD --checksum=sha256:...`.
