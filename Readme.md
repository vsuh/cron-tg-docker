# Telegram Reminder Bot в Docker

[![Build and Push Docker](https://github.com/vsuh/cron-tg-docker/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/vsuh/cron-tg-docker/actions/workflows/build-and-push.yml)
[![Docker Hub](https://img.shields.io/badge/docker%20hub-vsuh%2Fcron--tg-blue)](https://hub.docker.com/r/vsuh/cron-tg)
[![GitHub tag (latest by date)](https://img.shields.io/github/v/tag/vsuh/reminder-tgm?label=version)](https://github.com/vsuh/reminder-tgm/tags)


Это Docker-обёртка для проекта [reminder-tgm](https://github.com/vsuh/reminder-tgm) — приложения для отправки напоминаний в Telegram (и опционально в [ntfy](https://ntfy.sh)) по расписанию на основе `cron`-выражений. Образ собирает исходники `reminder-tgm` нужной версии и запускает в одном контейнере веб-интерфейс и фоновый демон рассылки.
 
## Содержание
 
- [Особенности](#особенности)
- [Требования](#требования)
- [Установка и запуск](#установка-и-запуск)
- [Структура репозитория](#структура-репозитория)
- [Порты и URL](#порты-и-url)
- [Переменные окружения](#переменные-окружения)
- [Резервное копирование БД по scp](#резервное-копирование-бд-по-scp)
- [Логи](#логи)
- [Обновление образа](#обновление-образа)
- [Автоматическая сборка при новом релизе reminder-tgm](#автоматическая-сборка-при-новом-релизе-reminder-tgm)
- [Устранение неполадок](#устранение-неполадок)
- [Лицензия](#лицензия)
## Особенности
 
- Веб-интерфейс для управления напоминаниями, чатами Telegram и каналами ntfy.
- Поддержка `cron`-выражений и дополнительных модификаторов (`d/n`, `w/n`) для гибкой настройки расписания.
- Отправка уведомлений в разные Telegram-чаты от имени одного бота.
- Опциональное дублирование уведомлений в ntfy.
- Хранение данных в SQLite с автоматическим резервным копированием, включая опциональную репликацию бэкапов по `scp`.
- Ротация логов.
- Образ автоматически пересобирается и публикуется в Docker Hub при выходе нового релиза `reminder-tgm`.
## Требования
 
- Docker
- Docker Compose
- Токен Telegram-бота (получить у [@BotFather](https://t.me/BotFather))
- Chat ID Telegram-чата/группы для отправки уведомлений
## Установка и запуск
 
1. Клонируйте репозиторий (нужен только `docker-compose.yml`; сборка образа происходит в CI, локально пересобирать не нужно):
```bash
   git clone https://github.com/vsuh/cron-tg-docker.git
   cd cron-tg-docker
```
 
2. Создайте директории для конфигурации, базы данных и логов на хосте:
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
   | `TLCR_FLASK_HOST` | **Обязательно `0.0.0.0`** для запуска в Docker. Значение `127.0.0.1` (как в `.env.SAMPLE` для локальной отладки) сделает веб-интерфейс недоступным снаружи контейнера — без единой ошибки в логах, см. [«Устранение неполадок»](#устранение-неполадок) |
 
   > **Важно:** значение переменной `TLCR_FLASK_PORT` в `.env`-файле должно совпадать с внутренним (правым) портом в секции [`ports`](docker-compose.yml) файла `docker-compose.yml` (по умолчанию контейнер слушает `7999` внутри, а наружу публикуется `7878`).
 
4. Права доступа: процессы в контейнере выполняются от имени пользователя `appuser` с UID/GID `5678`. Каталоги `log` и `db` на хосте должны быть доступны этому пользователю на запись:
```bash
   chown -R 5678:5678 /opt/cron-reminder/log /opt/cron-reminder/db
```
 
5. Запустите контейнер. **Не используйте `docker compose up --build`** — в `docker-compose.yml` указан только `image:`, образ берётся готовым из Docker Hub:
```bash
   docker compose pull
   docker compose up -d
```
 
6. Откройте веб-интерфейс по адресу `http://<host>:7878` и создайте хотя бы один чат на странице `/chats`, прежде чем добавлять расписания.
## Структура репозитория
 
| Файл | Назначение |
|---|---|
| `Dockerfile` | Сборка образа: скачивает архив релиза `reminder-tgm` нужной версии (`ARG TAG`), устанавливает зависимости, настраивает непривилегированного пользователя `appuser` |
| `docker-compose.yml` | Запуск готового образа из Docker Hub с volume-мапингом конфигурации, БД, логов и ssh-ключа для бэкапов |
| `.github/workflows/build-and-push.yml` | CI: пересобирает и публикует образ в Docker Hub при новом релизе `reminder-tgm` |
 
> В репозитории нет локальной сборки «по умолчанию» — `Dockerfile` используется только в CI (GitHub Actions) для публикации образа в Docker Hub. Для обычного запуска достаточно `docker-compose.yml` и готового образа `vsuh/cron-tg:latest`.
 
Внутри собранного образа (унаследовано из `reminder-tgm`) используются:
 
- `web_prod.sh` — запуск веб-сервера (`gunicorn`);
- `rund_prod.sh` — запуск демона-планировщика рассылки;
- `start.sh` — точка входа контейнера: запускает оба процесса параллельно и завершает работу, если один из них упал;
- `log/` — директория для логов;
- `db/` — директория с базой данных SQLite.
## Порты и URL
 
| Что | Значение |
|---|---|
| Веб-интерфейс снаружи контейнера | `http://<host>:7878` (настраивается в `docker-compose.yml`, секция `ports`) |
| Порт `gunicorn` внутри контейнера | `7999` (должен совпадать с `TLCR_FLASK_PORT` в `.env`) |
 
## Переменные окружения
 
Полный список переменных окружения приложения (Telegram, БД, бэкапы, веб-интерфейс, авторизация, планировщик, логирование) описан в [README проекта reminder-tgm](https://github.com/vsuh/reminder-tgm#переменные-окружения) и в файле-примере [env/.env.SAMPLE](https://github.com/vsuh/reminder-tgm/blob/master/env/.env.SAMPLE).
 
В `docker-compose.yml` `.env`-файл с хоста монтируется внутрь контейнера:
 
```yaml
volumes:
  - /opt/cron-reminder/env/.env.prod:/workspaces/cron-tg-docker/.env
```
 
## Резервное копирование БД по scp
 
Если в `.env` заданы `TLCR_BACKUP_SCP_ODD`/`TLCR_BACKUP_SCP_EVEN` и `TLCR_BACKUP_SSH_KEY_PATH`, приложение само реплицирует бэкапы БД на удалённый хост по `scp` (подробности — в документации `reminder-tgm`). Чтобы это сработало внутри контейнера, приватный ssh-ключ должен быть смонтирован по тому же пути, что указан в `TLCR_BACKUP_SSH_KEY_PATH`:
 
```yaml
volumes:
  - /opt/cron-reminder/keys:/keys:ro
```
 
Тогда, например, `TLCR_BACKUP_SSH_KEY_PATH=/keys/backup_id_ed25519` будет указывать на файл `/opt/cron-reminder/keys/backup_id_ed25519` на хосте.
 
Несколько важных моментов:
 
- Владелец и права ключа на хосте должны позволять читать его пользователю с UID `5678` (тому самому `appuser`, под которым работает контейнер). Проще всего сделать ключ читаемым этим UID:
```bash
  chown 5678 /opt/cron-reminder/keys/backup_id_ed25519
  chmod 600 /opt/cron-reminder/keys/backup_id_ed25519
```
 
- Публичный ключ должен быть добавлен в `~/.ssh/authorized_keys` на удалённом хосте-приёмнике бэкапов.
- Порт для `scp` задаётся переменными `TLCR_BACKUP_SSH_PORT_ODD`/`TLCR_BACKUP_SSH_PORT_EVEN` (по умолчанию `22`).
## Логи
 
Логи приложения сохраняются в директории `/opt/cron-reminder/log/` на хосте:
 
- `web_app.log` — логи веб-приложения;
- `db_utils.log` — логи операций с базой данных;
- `rmndr.log` — логи демона рассылки (в том числе результаты scp-репликации бэкапов);
- `gunicorn-access.log` — логи доступа к веб-серверу;
- `gunicorn-error.log` — логи ошибок веб-сервера.
Просмотр логов контейнера в реальном времени:
 
```bash
docker compose logs -f
```
 
## Обновление образа
 
Образ публикуется автоматически через CI при выходе нового релиза `reminder-tgm` (см. ниже). Чтобы обновиться до последней версии на сервере, где уже запущен контейнер:
 
```bash
docker compose pull
docker compose up -d
```
 
Это стянет актуальный `vsuh/cron-tg:latest` и пересоздаст контейнер. Локальная пересборка (`--build`) не требуется и не предусмотрена текущим `docker-compose.yml`.
 
## Автоматическая сборка при новом релизе reminder-tgm
 
При публикации нового тега в репозитории `reminder-tgm` срабатывает `repository_dispatch` (`new-reminder-tgm-tag`), который запускает workflow [`build-and-push.yml`](.github/workflows/build-and-push.yml) в этом репозитории. Workflow:
 
1. Проверяет, что архив исходников с указанным тегом существует.
2. Собирает образ из `Dockerfile`, передавая версию релиза как build-arg (`TAG=<тег>`) — без изменения и коммита файлов в этом репозитории.
3. Публикует образ в Docker Hub с тегами `<версия>` и `latest`.
4. Отправляет уведомление об успешной сборке в Telegram.
Запустить пересборку вручную можно через `workflow_dispatch` (вкладка **Actions** на GitHub, указав нужный тег), либо тестовым `repository_dispatch`-запросом — см. раздел «Тестирование цепочки workflow» в [README reminder-tgm](https://github.com/vsuh/reminder-tgm#тестирование-цепочки-workflow).
 
> Значение `ARG TAG` в самом `Dockerfile` — это только дефолт для локальной/ручной сборки (`docker build .` без аргументов). При сборке через CI реальная версия всегда приходит снаружи через `--build-arg TAG=...` и переопределяет этот дефолт.
 
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
   ls -la /opt/cron-reminder/{log,db,keys}
```
 
4. Если веб-интерфейс не открывается — убедитесь, что `TLCR_FLASK_PORT` в `.env` совпадает с внутренним портом, указанным в `docker-compose.yml` (`ports: "7878:<TLCR_FLASK_PORT>"`).
5. **`curl` зависает или возвращает `Empty reply from server`, а в `gunicorn-error.log` всё «чисто» (gunicorn стартовал, воркеры забутились, никаких ошибок)** — почти наверняка `TLCR_FLASK_HOST=127.0.0.1` в `.env`. Внутри контейнера `127.0.0.1` — это loopback самого контейнера: gunicorn слушает порт, но недоступен снаружи, даже если порт «проброшен» в `docker-compose.yml`. Для Docker/production обязательно нужно `TLCR_FLASK_HOST=0.0.0.0`. Проверить, на каком адресе реально слушает gunicorn, можно по строке в логе:
```bash
   docker compose logs | grep "Listening at"
   # Listening at: http://0.0.0.0:7999   — правильно
   # Listening at: http://127.0.0.1:7999 — неправильно для Docker
```
 
   После правки `.env` контейнер нужно пересоздать (`docker compose up -d` достаточно — gunicorn перечитывает конфиг при старте процесса, на лету это не применяется).
 
6. Если расписания не приходят — проверьте, что в веб-интерфейсе создан хотя бы один чат (`/chats`) и указан верный `TLCR_TELEGRAM_TOKEN`.
7. Если контейнер запущен из локально пересобранного (а не из Docker Hub) образа и ведёт себя «по-старому» — проверьте, что в `docker-compose.yml` нет секции `build:`. Сочетание `image:` и `build:` заставляет Compose пересобирать образ локально при любой команде со сборкой и присваивать ему тот же тег `latest`, из-за чего легко получить устаревшую версию, даже выполнив `docker compose pull`.
8. Если scp-репликация бэкапов падает с `Identity file ... not accessible` — ssh-ключ не виден внутри контейнера. Проверьте, что путь в `TLCR_BACKUP_SSH_KEY_PATH` (внутри контейнера) соответствует реально смонтированному volume, например `/opt/cron-reminder/keys:/keys:ro`.
9. Если scp-репликация падает с `Permission denied (publickey,password)` при том, что ключ виден контейнеру — проверьте права/владельца файла ключа на хосте (должен читаться UID `5678`) и что соответствующий публичный ключ добавлен в `authorized_keys` на удалённом хосте.
## Лицензия
 
Этот проект является Docker-обёрткой для [reminder-tgm](https://github.com/vsuh/reminder-tgm) и распространяется под той же лицензией ([BSD-3-Clause](https://github.com/vsuh/reminder-tgm/blob/master/LICENSE)).
