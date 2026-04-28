import uuid
from datetime import datetime
from decimal import Decimal
from typing import Optional
from pydantic import BaseModel, field_validator


class TransferRequest(BaseModel):
    receiver_phone: str          # Ravi types the phone number, not a wallet ID
    amount: Decimal
    note: Optional[str] = None   # e.g. "For seeds"

    @field_validator("amount")
    @classmethod
    def amount_must_be_positive(cls, v):
        if v <= 0:
            raise ValueError("Amount must be greater than zero")
        if v > 500000:
            raise ValueError("Single transfer limit is LKR 500,000")
        return v


class DepositRequest(BaseModel):
    wallet_id: uuid.UUID
    amount: Decimal

    @field_validator("amount")
    @classmethod
    def amount_must_be_positive(cls, v):
        if v <= 0:
            raise ValueError("Amount must be greater than zero")
        return v


class TransactionResponse(BaseModel):
    id: uuid.UUID
    sender_wallet_id: Optional[uuid.UUID]
    receiver_wallet_id: uuid.UUID
    amount: Decimal
    currency: str
    transaction_type: str
    status: str
    idempotency_key: Optional[str]
    meta: Optional[dict]
    created_at: datetime

    model_config = {"from_attributes": True}


class TransactionListResponse(BaseModel):
    transactions: list[TransactionResponse]
    total: int