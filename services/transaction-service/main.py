from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import models
from database import engine
from api import router as tx_router

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="FinLink Transaction Service", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(tx_router, prefix="/api/transactions", tags=["Transactions"])

@app.get("/health")
def health_check():
    return {"status": "Transaction Service is routing funds successfully"}