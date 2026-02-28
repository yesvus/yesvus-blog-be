from app.services import media
import pytest
from fastapi import HTTPException


class FakeS3Client:
    def generate_presigned_url(self, _operation, Params, ExpiresIn):  # noqa: N803
        return f"https://upload.example/{Params['Key']}?expires={ExpiresIn}"


class FakeFactory:
    def __call__(self, _service_name, region_name):
        assert region_name
        return FakeS3Client()


def test_build_object_key_format():
    key = media.build_object_key("cover.jpg")
    assert key.startswith("posts/")
    assert key.endswith(".jpg")


def test_presigned_upload_uses_allowed_type(monkeypatch):
    monkeypatch.setattr(media, "boto3", type("Boto3", (), {"client": FakeFactory()})())
    monkeypatch.setattr(media.settings, "cloudfront_domain", "cdn.example.com")
    monkeypatch.setattr(media.settings, "s3_bucket_name", "bucket")
    monkeypatch.setattr(media.settings, "aws_region", "eu-central-1")
    monkeypatch.setattr(media.settings, "media_presign_expire_seconds", 300)

    result = media.create_presigned_upload("hero.webp", "image/webp")

    assert result.upload_url.startswith("https://upload.example/")
    assert result.key.startswith("posts/")
    assert result.image_url.startswith("https://cdn.example.com/")
    assert result.expires_in == 300


def test_presigned_upload_rejects_large_file():
    with pytest.raises(HTTPException):
        media.validate_content_length(media.settings.max_upload_size_bytes + 1)
