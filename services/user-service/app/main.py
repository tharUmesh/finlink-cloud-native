from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.database import engine, Base
from app import models  # noqa: F401


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    print("✅ user-service: database tables ready")
    yield


app = FastAPI(
    title="FinLink — User Service",
    version="1.0.0",
    lifespan=lifespan
)

# Wire in routes
from app.routes import router
app.include_router(router, tags=["Users"])


@app.get("/health")
def health():
    return {"status": "ok", "service": "user-service"}