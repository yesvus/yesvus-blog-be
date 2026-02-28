from fastapi import APIRouter, Depends, status

from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.media import MediaPresignRequest, MediaPresignResponse
from app.services.media import create_presigned_upload, delete_object

router = APIRouter(prefix="/media", tags=["media"])


@router.post("/presign-upload", response_model=MediaPresignResponse)
async def presign_upload(
    payload: MediaPresignRequest,
    _: User = Depends(get_current_user),
) -> MediaPresignResponse:
    data = create_presigned_upload(
        payload.filename,
        payload.content_type,
        payload.content_length,
    )
    return MediaPresignResponse(
        upload_url=data.upload_url,
        key=data.key,
        image_url=data.image_url,
        expires_in=data.expires_in,
    )


@router.delete("/{key:path}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_media(
    key: str,
    _: User = Depends(get_current_user),
) -> None:
    delete_object(key)
