## Структура

```
.
├── cmd/
│   └── server/                 # точка входа HTTP-сервера
├── internal/
│   ├── app/                    # сборка зависимостей и lifecycle
│   ├── client/                 # HTTP JSON-клиент для e2e-тестов
│   ├── config/
│   ├── handler/                # HTTP handlers
│   ├── middleware/
│   ├── model/
│   ├── service/                # бизнес-логика
│   └── storage/                # in-memory хранилище
├── tests/
│   └── e2e/                    # автотесты ДЗ (Playground + GraphQL Echo)
├── postman/                    # коллекция с GraphQL subscription (SSE)
├── Dockerfile                  # образ для запуска API-автотестов
├── .dockerignore
├── .github/workflows/ci.yml    # CI: docker build + docker run
├── go.mod
└── README.md
```

## Локальный API

Эндпоинты:

| Method | Path | Описание |
|--------|------|----------|
| GET | `/health` | liveness |
| POST | `/api/v1/posts` | создать пост |
| GET | `/api/v1/posts/{id}` | получить пост |
| PATCH | `/api/v1/posts/{id}` | изменить пост |
| POST | `/api/v1/auth/login` | логин (`Bret` / `Password@123`) |
| GET | `/api/v1/auth/me` | профиль по Bearer token |

Запуск сервера:

```bash
go run ./cmd/server
```

Порт по умолчанию `:8080`.

## Автотесты (e2e)

Тесты в `tests/e2e` ходят во внешние стенды:

| API | URL |
|-----|-----|
| REST / Auth | `https://playground.nileslabs.com/api/v1` |
| GraphQL | `https://graphql.postman-echo.com/graphql` |

Сценарии:

1. **REST:** `POST /posts` → extract `id` → `PATCH` → `GET` (проверка изменённых и неизменённых полей)
2. **Auth:** login → Bearer → `/auth/me` + негатив без/с неверным token
3. **GraphQL:** query `Hello`, mutation `CreatePerson` (data + нет errors)
4. **Subscription:** в Postman (`postman/…`, SSE `Accept: text/event-stream`)
5. **+2:** параметризованный негатив login и GET несуществующего поста

Логин Playground: `Bret` / `Password@123`  
(в семинаре был `password123`; в актуальном OpenAPI — `Password@123`).

### Запуск тестов локально (без Docker)

Все тесты (локальные handler + e2e):

```bash
go test ./... -count=1
```

Только e2e:

```bash
go test ./tests/e2e -v -count=1
```

Только локальные handler-тесты (без сети):

```bash
go test ./internal/... -count=1
```

Нужен интернет для `tests/e2e`.

## Docker: сборка и запуск API-автотестов

Образ содержит Go и исходники e2e-тестов. При `docker run` тесты запускаются автоматически (`go test ./tests/e2e`), ходят в публичные API выше. Exit code контейнера = результат тестов (0 — успех, иначе — падение).

Сборка image:

```bash
docker build -t api-test .
```

Запуск тестов в контейнере:

```bash
docker run --rm api-test
```

## CI / CD

Конфигурация: [`.github/workflows/ci.yml`](.github/workflows/ci.yml)

Pipeline запускается на **push** и **pull_request** и выполняет цепочку:

`checkout` → `docker build -t api-test .` → `docker run --rm api-test`
