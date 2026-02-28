from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.post import Post
from app.models.user import User
from app.schemas.post import PostCreate, PostRead, PostUpdate

router = APIRouter(prefix="/posts", tags=["posts"])


@router.post("", response_model=PostRead, status_code=status.HTTP_201_CREATED)
async def create_post(
    payload: PostCreate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> Post:
    post = Post(
        title=payload.title,
        content=payload.content,
        image_key=payload.image_key,
        image_url=payload.image_url,
        image_alt=payload.image_alt,
    )
    db.add(post)
    await db.commit()
    await db.refresh(post)
    return post


@router.get("", response_model=list[PostRead])
async def list_posts(db: AsyncSession = Depends(get_db)) -> list[Post]:
    result = await db.execute(select(Post).order_by(Post.created_at.desc()))
    return list(result.scalars().all())


@router.put("/{post_id}", response_model=PostRead)
async def update_post(
    post_id: int,
    payload: PostUpdate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> Post:
    result = await db.execute(select(Post).where(Post.id == post_id))
    post = result.scalar_one_or_none()
    if post is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Post not found")

    for field_name, value in payload.model_dump(exclude_unset=True).items():
        setattr(post, field_name, value)

    await db.commit()
    await db.refresh(post)
    return post
