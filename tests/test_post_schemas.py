from app.schemas.post import PostCreate, PostRead


def test_post_create_accepts_optional_image_fields():
    payload = PostCreate(title="t", content="c", image_key="k", image_url="u", image_alt="a")
    assert payload.image_key == "k"
    assert payload.image_url == "u"
    assert payload.image_alt == "a"


def test_post_read_allows_missing_image_fields():
    payload = PostRead(id=1, title="t", content="c", created_at="2026-01-01T00:00:00Z")
    assert payload.image_key is None
    assert payload.image_url is None
    assert payload.image_alt is None
