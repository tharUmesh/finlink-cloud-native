# wallet-service/app/schemas.py
from pydantic import BaseModel, Field
from datetime import datetime
import uuid

class WalletBase(BaseModel):
    user_id: str = Field(..., description="The ID from the User Service")
    balance: float = Field(default=0.0, ge=0.0, description="Cannot be negative")
    currency: str = Field(default="LKR")

class WalletCreate(BaseModel):
    user_id: str

class WalletResponse(WalletBase):
    wallet_id: str
    created_at: datetime
    updated_at: datetime

class BalanceUpdate(BaseModel):
    amount: float = Field(..., description="Amount to add (positive) or deduct (negative)")