# transaction-service/app/api.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import httpx
import schemas, models
from database import get_db
import os

router = APIRouter()

# In production, this comes from .env. For local testing, it points to your Wallet Service.
WALLET_SERVICE_URL = os.getenv("WALLET_SERVICE_URL", "http://127.0.0.1:8001/api/wallets")

async def mock_fraud_check(sender_id: str, amount: float) -> bool:
    """Mock adapter for the future AI Fraud Service"""
    # For MVP testing, automatically block abnormally large transfers
    if amount > 500000:
        return False 
    return True

@router.post("/transfer", response_model=schemas.TransactionResponse)
async def p2p_transfer(request: schemas.TransferRequest, db: Session = Depends(get_db)):
    # 1. Create PENDING ledger entry
    transaction = models.Transaction(
        sender_wallet_id=request.sender_wallet_id,
        receiver_wallet_id=request.receiver_wallet_id,
        amount=request.amount,
        transaction_type="TRANSFER",
        status="PENDING"
    )
    db.add(transaction)
    db.commit()
    db.refresh(transaction)

    # 2. Synchronous Fraud Check
    is_safe = await mock_fraud_check(request.sender_wallet_id, request.amount)
    if not is_safe:
        transaction.status = "BLOCKED"
        db.commit()
        raise HTTPException(status_code=403, detail="Transaction flagged by Fraud AI")

    # 3. Synchronous Communication with Wallet Service
    async with httpx.AsyncClient() as client:
        try:
            # Deduct from Sender
            sender_res = await client.post(
                f"{WALLET_SERVICE_URL}/{request.sender_wallet_id}/update-balance",
                json={"amount": -request.amount}
            )
            if sender_res.status_code != 200:
                transaction.status = "FAILED"
                db.commit()
                raise HTTPException(status_code=400, detail="Insufficient funds or invalid sender")

            # Add to Receiver
            receiver_res = await client.post(
                f"{WALLET_SERVICE_URL}/{request.receiver_wallet_id}/update-balance",
                json={"amount": request.amount}
            )
            if receiver_res.status_code != 200:
                # CRITICAL: In a real system, we must trigger a rollback here (Saga pattern).
                # For this assignment's MVP, we log the failure.
                transaction.status = "FAILED_PARTIAL"
                db.commit()
                raise HTTPException(status_code=500, detail="Failed to credit receiver")

        except httpx.RequestError:
            transaction.status = "FAILED"
            db.commit()
            raise HTTPException(status_code=503, detail="Wallet Service unavailable")

    # 4. Finalize Transaction
    transaction.status = "COMPLETED"
    db.commit()
    db.refresh(transaction)

    # TODO: Publish 'TransactionCompleted' to Azure Service Bus for Notifications/Loans
    
    return transaction