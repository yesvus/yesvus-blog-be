from pydantic import BaseModel, Field


class MediaPresignRequest(BaseModel):
    filename: str = Field(min_length=1, max_length=255)
    content_type: str = Field(min_length=1, max_length=100)
    content_length: int | None = Field(default=None, ge=1)


class MediaPresignResponse(BaseModel):
    upload_url: str
    key: str
    image_url: str
    expires_in: int
