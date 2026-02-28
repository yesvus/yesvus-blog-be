# FastAPI Blog Backend

Backend-only blog API with async PostgreSQL access, JWT auth, and Alembic migrations.

## Tech Stack

- FastAPI
- PostgreSQL
- SQLAlchemy 2.x (async)
- Alembic
- Pydantic + pydantic-settings
- JWT (`python-jose`) + password hashing (`passlib[bcrypt]`)
- `uv` for environment and dependency management
- Docker + Docker Compose

## Project Structure

```text
app/
  api/
    deps.py            # shared API dependencies (current user resolver)
    v1/
      auth.py          # register/login routes
      posts.py         # post create/list routes
  core/
    config.py          # .env-driven settings
    security.py        # hashing + JWT create/decode
  db/
    base.py            # SQLAlchemy declarative base
    session.py         # async engine/session + get_db dependency
  models/              # SQLAlchemy models (User, Post)
  schemas/             # API contracts (Pydantic)
  main.py              # app entrypoint + global DB exception handler
migrations/
  env.py               # Alembic config + model metadata registration
  versions/            # migration files
```

## Architecture Flow

1. Request enters FastAPI route in `app/api/v1/*`.
2. Route validates payload with `schemas/*`.
3. Route gets `AsyncSession` from `get_db` dependency (`app/db/session.py`).
4. Route executes ORM queries on `models/*`.
5. Response is serialized with response schema contracts.

## Auth Flow (OAuth2 Password + JWT)

1. `POST /api/v1/auth/register` creates user with bcrypt-hashed password.
2. `POST /api/v1/auth/login` validates credentials and returns JWT access token.
3. Protected routes use `OAuth2PasswordBearer` token extraction.
4. `get_current_user` decodes JWT, resolves user from DB, and injects it.

## Database & Migrations

- Models are imported in `migrations/env.py`, so Alembic autogenerate can detect schema changes.
- Initial migration exists in `migrations/versions/20260228_0001_init.py`.

Common commands:

```bash
uv run alembic revision --autogenerate -m "message"
uv run alembic upgrade head
uv run alembic downgrade -1
```

## Local Development

1. Copy env file: `cp .env.example .env`
2. Use supported Python (`3.12` or `3.13`)
3. Create venv: `uv venv --python 3.12`
4. Install deps: `uv sync`
5. Run migrations: `uv run alembic upgrade head`
6. Start API: `uv run uvicorn app.main:app --reload`

Health check: `GET /health`

## Docker

Run full stack:

```bash
docker compose up --build
```

- API: `http://localhost:8000`
- DB: `localhost:5432`

Container uses a non-root user for runtime security.

## Smoke Test

After the API is running:

```bash
./scripts/smoke_test.sh
```

Optional custom base URL:

```bash
./scripts/smoke_test.sh http://localhost:8000
```
