from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "FastAPI Blog API"
    app_env: str = "development"
    app_host: str = "0.0.0.0"
    app_port: int = 8000

    database_url: str = "postgresql+asyncpg://postgres:postgres@db:5432/blog"

    secret_key: str = "change-me"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    aws_region: str = "eu-central-1"
    s3_bucket_name: str = "blog-images-dev"
    cloudfront_domain: str = ""
    media_presign_expire_seconds: int = 900
    max_upload_size_bytes: int = 10 * 1024 * 1024
    allowed_image_types: str = "image/jpeg,image/png,image/webp"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", case_sensitive=False)


settings = Settings()
