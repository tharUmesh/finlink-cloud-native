import asyncio
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.database import engine, Base
from app import models  # noqa: F401
from app.processor import process_notifications

logging.basicConfig(level=logging.INFO)


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    print("✅ notification-service: database tables ready")
    task = asyncio.create_task(process_notifications())
    print("✅ notification-service: notification processor started")
    yield
    task.cancel()
    try:
        await task
    except asyncio.CancelledError:
        pass


app = FastAPI(
    title="FinLink — Notification Service",
    version="1.0.0",
    lifespan=lifespan
)

from app.routes import router
app.include_router(router, tags=["Notifications"])


@app.get("/health")
def health():
    return {"status": "ok", "service": "notification-service"}