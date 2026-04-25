from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.database import engine, Base
from app import models  # noqa: F401 — import triggers model registration


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Runs once when the service starts — creates all tables if they don't exist
    Base.metadata.create_all(bind=engine)
    print("✅ loan-service: database tables ready")
    yield
    # Runs on shutdown — nothing to clean up yet


app = FastAPI(
    title="FinLink — Loan Service",
    version="1.0.0",
    lifespan=lifespan
)


@app.get("/health")
def health():
    return {"status": "ok", "service": "loan-service"}