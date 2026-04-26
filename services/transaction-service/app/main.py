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
from app.outbox import outbox_poller

logging.basicConfig(level=logging.INFO)

# Rate limiter — identifies clients by IP address
limiter = Limiter(key_func=get_remote_address)


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    print("✅ transaction-service: database tables ready")
    task = asyncio.create_task(outbox_poller())
    print("✅ transaction-service: outbox poller started")
    yield
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

# Attach rate limiter to app
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS — allows mobile app to call this service
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten this in production
    allow_methods=["*"],
    allow_headers=["*"],
)

from app.routes import router
app.include_router(router, tags=["Transactions"])

from app.loadtest import load_router
app.include_router(load_router)


@app.get("/health")
def health():
    return {"status": "ok", "service": "transaction-service"}


@app.post("/load-test/transfer")
async def load_test(db=None):
    """
    Endpoint for Person 3's ACA auto-scaling demo.
    Simulates rapid incoming requests to trigger scale-out.
    """
    import asyncio
    await asyncio.sleep(0.1)  # simulate processing time
    return {"status": "ok", "message": "load test hit"}