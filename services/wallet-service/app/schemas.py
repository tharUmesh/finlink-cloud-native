import uuid
from datetime import datetime
from decimal import Decimal
from pydantic import BaseModel


class CreateWalletRequest(BaseModel):
    user_id: uuid.UUID


class WalletResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    balance: Decimal
    currency: str
    is_frozen: str
    created_at: datetime

    model_config = {"from_attributes": True}