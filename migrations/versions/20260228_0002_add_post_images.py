"""add post image metadata

Revision ID: 20260228_0002
Revises: 20260228_0001
Create Date: 2026-02-28 00:15:00
"""

from alembic import op
import sqlalchemy as sa


revision = "20260228_0002"
down_revision = "20260228_0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("posts", sa.Column("image_key", sa.String(length=1024), nullable=True))
    op.add_column("posts", sa.Column("image_url", sa.String(length=2048), nullable=True))
    op.add_column("posts", sa.Column("image_alt", sa.String(length=255), nullable=True))


def downgrade() -> None:
    op.drop_column("posts", "image_alt")
    op.drop_column("posts", "image_url")
    op.drop_column("posts", "image_key")
