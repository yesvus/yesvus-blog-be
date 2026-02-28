from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from sqlalchemy.exc import IntegrityError, SQLAlchemyError

from app.api.v1 import api_router
from app.core.config import settings

app = FastAPI(title=settings.app_name)
app.include_router(api_router)


@app.exception_handler(SQLAlchemyError)
async def sqlalchemy_exception_handler(_: Request, exc: SQLAlchemyError) -> JSONResponse:
    status_code = 409 if isinstance(exc, IntegrityError) else 500
    return JSONResponse(
        status_code=status_code,
        content={"detail": "Database operation failed"},
    )


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
