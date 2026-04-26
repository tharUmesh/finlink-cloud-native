from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.database import engine, Base
from app import models  # noqa: F401


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    print("✅ wallet-service: database tables ready")
    yield


app = FastAPI(
    title="FinLink — Wallet Service",
    version="1.0.0",
    lifespan=lifespan
)

from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

from app.routes import router
app.include_router(router, tags=["Wallets"])


@app.get("/health")
def health():
    return {"status": "ok", "service": "wallet-service"}