from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional

class TransferRequest(BaseModel):
    sender_wallet_id: str
    receiver_wallet_id: str
    amount: float = Field(..., gt=0, description="Amount must be strictly positive")

class DepositWithdrawRequest(BaseModel):
    wallet_id: str
    amount: float = Field(..., gt=0)

class TransactionResponse(BaseModel):
    id: str
    sender_wallet_id: Optional[str] = None
    receiver_wallet_id: Optional[str] = None
    amount: float
    transaction_type: str
    status: str
    created_at: datetime

    class Config:
        from_attributes = True