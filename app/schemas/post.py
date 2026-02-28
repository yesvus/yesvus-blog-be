from datetime import datetime

from pydantic import BaseModel, ConfigDict


class PostCreate(BaseModel):
    title: str
    content: str
    image_key: str | None = None
    image_url: str | None = None
    image_alt: str | None = None


class PostUpdate(BaseModel):
    title: str | None = None
    content: str | None = None
    image_key: str | None = None
    image_url: str | None = None
    image_alt: str | None = None


class PostRead(BaseModel):
    id: int
    title: str
    content: str
    image_key: str | None = None
    image_url: str | None = None
    image_alt: str | None = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
