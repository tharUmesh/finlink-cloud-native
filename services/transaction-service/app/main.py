import asyncio
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.database import engine, Base
from app import models  # noqa: F401
from app.outbox import outbox_poller

logging.basicConfig(level=logging.INFO)


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    print("✅ transaction-service: database tables ready")

    # Start outbox poller as background task
    task = asyncio.create_task(outbox_poller())
    print("✅ transaction-service: outbox poller started")

    yield

    # Shutdown — cancel the poller cleanly
    task.cancel()
    try:
        await task
    except asyncio.CancelledError:
        pass


app = FastAPI(
    title="FinLink — Transaction Service",
    version="1.0.0",
    lifespan=lifespan
)

from app.routes import router
app.include_router(router, tags=["Transactions"])


@app.get("/health")
def health():
    return {"status": "ok", "service": "transaction-service"}