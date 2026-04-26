# wallet-service/app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api import router as wallet_router

app = FastAPI(
    title="FinLink Wallet Service",
    description="High-speed NoSQL wallet balance management.",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(wallet_router, prefix="/api/wallets", tags=["Wallets"])

@app.get("/health", tags=["System"])
def health_check():
    return {"status": "Wallet Service is running optimally"}