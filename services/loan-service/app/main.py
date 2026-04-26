import asyncio
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from app.database import engine, Base
from app import models  # noqa: F401
from app.outbox import loan_outbox_poller

logging.basicConfig(level=logging.INFO)

limiter = Limiter(key_func=get_remote_address)


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

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

from app.routes import router
app.include_router(router, tags=["Loans"])


@app.get("/health")
def health():
    return {"status": "ok", "service": "loan-service"}