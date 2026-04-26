import uuid
from datetime import datetime
from decimal import Decimal
from pydantic import BaseModel, field_validator
from typing import Literal


class CreateWalletRequest(BaseModel):
    user_id: uuid.UUID


class WalletResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    balance: Decimal
    currency: str
    is_frozen: str
    created_at: datetime
    updated_at: datetime | None = None

    model_config = {"from_attributes": True}


class BalanceUpdateRequest(BaseModel):
    """
    Used internally by transaction-service and the seed script.
    operation:
      'credit' = add amount to balance (receiving money)
      'debit'  = subtract amount from balance (sending money)
      'set'    = set balance to exact amount (seed only)
    """
    amount: Decimal
    operation: Literal["credit", "debit", "set"]

    @field_validator("amount")
    @classmethod
    def must_be_positive(cls, v):
        if v <= 0:
            raise ValueError("Amount must be positive")
        return v


class WalletSummary(BaseModel):
    """Lightweight response for listing wallets (admin view)."""
    id: uuid.UUID
    user_id: uuid.UUID
    balance: Decimal
    currency: str
    is_frozen: str
    created_at: datetime

    model_config = {"from_attributes": True}