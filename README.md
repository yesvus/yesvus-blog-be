# FastAPI Blog Backend

Backend-only blog API with async PostgreSQL access, JWT auth, and AWS-ready media upload flow.

## Tech Stack

- FastAPI
- PostgreSQL
- SQLAlchemy 2.x (async)
- Alembic
- JWT (`python-jose`) + password hashing (`passlib[bcrypt]`)
- S3 presigned uploads + CloudFront image delivery
- Terraform for AWS infrastructure
- GitHub Actions for CI/CD

## API Overview

### Auth

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`

### Posts

- `POST /api/v1/posts` (auth required)
- `PUT /api/v1/posts/{post_id}` (auth required)
- `GET /api/v1/posts`

`Post` now supports optional image metadata:

- `image_key`
- `image_url`
- `image_alt`

### Media

- `POST /api/v1/media/presign-upload` (auth required)
  - input: `filename`, `content_type`, optional `content_length`
  - output: `upload_url`, `key`, `image_url`, `expires_in`
- `DELETE /api/v1/media/{key}` (auth required)

### Health Endpoints

- `GET /health`
- `GET /ready` (checks DB connectivity)

## Upload Flow

1. Client calls `POST /api/v1/media/presign-upload`.
2. Client uploads file directly to S3 using returned `upload_url`.
3. Client sends `image_key`/`image_url` in post create or update payload.
4. Public image is served through CloudFront.

## Configuration

Copy `.env.example` to `.env` and update values.

New AWS/media settings:

- `AWS_REGION`
- `S3_BUCKET_NAME`
- `CLOUDFRONT_DOMAIN`
- `MEDIA_PRESIGN_EXPIRE_SECONDS`
- `MAX_UPLOAD_SIZE_BYTES`
- `ALLOWED_IMAGE_TYPES`

## Local Development

1. `cp .env.example .env`
2. `uv venv --python 3.12`
3. `uv sync --group dev`
4. `uv run alembic upgrade head`
5. `uv run uvicorn app.main:app --reload`

## Tests

```bash
uv run pytest
```

## Docker

```bash
docker compose up --build
```

## Terraform Deployment

See [`infra/README.md`](infra/README.md) for `dev`/`prod` environment details.

## CI/CD

GitHub Actions workflow: `.github/workflows/ci-cd.yml`

- Runs tests
- Builds and pushes image to ECR
- Applies Terraform
- Runs Alembic migration as one-off ECS task
- Scales ECS service to target desired count
