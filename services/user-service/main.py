# app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import models
from database import engine
from api import router as user_router

# Auto-generate database tables (ideal for fast prototyping)
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="FinLink User Service",
    description="Handles identity, authentication, and user profiles.",
    version="1.0.0"
)

# Standard Security: Allow frontend to communicate with API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, restrict this to your frontend domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(user_router, prefix="/api/users", tags=["Users"])

@app.get("/health", tags=["System"])
def health_check():
    return {"status": "User Service is running optimally"}