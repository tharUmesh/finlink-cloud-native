import asyncio
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.database import engine, Base
from app import models  # noqa: F401
from app.outbox import loan_outbox_poller

logging.basicConfig(level=logging.INFO)


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    print("✅ loan-service: database tables ready")
    task = asyncio.create_task(loan_outbox_poller())
    print("✅ loan-service: outbox poller started")
    yield
    task.cancel()
    try:
        await task
    except asyncio.CancelledError:
        pass


app = FastAPI(
    title="FinLink — Loan Service",
    version="1.0.0",
    lifespan=lifespan
)

from app.routes import router
app.include_router(router, tags=["Loans"])


@app.get("/health")
def health():
    return {"status": "ok", "service": "loan-service"}