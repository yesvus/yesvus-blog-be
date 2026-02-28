from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from uuid import uuid4

import boto3
from botocore.client import BaseClient
from fastapi import HTTPException, status

from app.core.config import settings


@dataclass
class PresignedUpload:
    upload_url: str
    key: str
    image_url: str
    expires_in: int


def _allowed_types() -> set[str]:
    return {item.strip().lower() for item in settings.allowed_image_types.split(",") if item.strip()}


def validate_content_type(content_type: str) -> str:
    normalized = content_type.strip().lower()
    if normalized not in _allowed_types():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported image content type: {content_type}",
        )
    return normalized


def validate_content_length(content_length: int | None) -> None:
    if content_length is None:
        return
    if content_length > settings.max_upload_size_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Image exceeds max allowed size of {settings.max_upload_size_bytes} bytes",
        )


def build_object_key(filename: str) -> str:
    suffix = Path(filename).suffix.lower()
    extension = suffix if suffix in {".jpg", ".jpeg", ".png", ".webp"} else ""
    now = datetime.now(UTC)
    return f"posts/{now.year:04d}/{now.month:02d}/{uuid4().hex}{extension}"


def _public_image_url(key: str) -> str:
    if settings.cloudfront_domain:
        host = settings.cloudfront_domain.rstrip("/")
        return f"https://{host}/{key}"
    return f"https://{settings.s3_bucket_name}.s3.{settings.aws_region}.amazonaws.com/{key}"


def _s3_client() -> BaseClient:
    return boto3.client("s3", region_name=settings.aws_region)


def create_presigned_upload(
    filename: str,
    content_type: str,
    content_length: int | None = None,
) -> PresignedUpload:
    normalized_content_type = validate_content_type(content_type)
    validate_content_length(content_length)
    key = build_object_key(filename)

    client = _s3_client()
    upload_url = client.generate_presigned_url(
        "put_object",
        Params={
            "Bucket": settings.s3_bucket_name,
            "Key": key,
            "ContentType": normalized_content_type,
        },
        ExpiresIn=settings.media_presign_expire_seconds,
    )

    return PresignedUpload(
        upload_url=upload_url,
        key=key,
        image_url=_public_image_url(key),
        expires_in=settings.media_presign_expire_seconds,
    )


def delete_object(key: str) -> None:
    client = _s3_client()
    client.delete_object(Bucket=settings.s3_bucket_name, Key=key)
