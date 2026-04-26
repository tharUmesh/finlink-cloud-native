import uuid
from datetime import datetime
from decimal import Decimal
from typing import Optional
from pydantic import BaseModel, field_validator


class LoanApplicationRequest(BaseModel):
    amount: Decimal
    term_weeks: int
    purpose: Optional[str] = None   # "seeds", "school fees", "medical", etc.

    @field_validator("amount")
    @classmethod
    def validate_amount(cls, v):
        if v < 5000:
            raise ValueError("Minimum loan amount is LKR 5,000")
        if v > 50000:
            raise ValueError("Maximum loan amount is LKR 50,000")
        return v

    @field_validator("term_weeks")
    @classmethod
    def validate_term(cls, v):
        if v < 1:
            raise ValueError("Minimum term is 1 week")
        if v > 52:
            raise ValueError("Maximum term is 52 weeks")
        return v


class LoanResponse(BaseModel):
    id: uuid.UUID
    applicant_user_id: uuid.UUID
    lender_user_id: Optional[uuid.UUID]
    amount: Decimal
    interest_rate: Decimal
    term_weeks: int
    status: str
    credit_score: Optional[int]
    rejection_reason: Optional[str]
    purpose: Optional[str]
    created_at: datetime
    approved_at: Optional[datetime]
    due_date: Optional[datetime]

    model_config = {"from_attributes": True}


class LoanApplicationResponse(BaseModel):
    """Returned immediately after applying — includes the decision."""
    loan: LoanResponse
    decision: str           # "approved" or "rejected"
    credit_score: int
    message: str            # human-readable explanation


class FundLoanRequest(BaseModel):
    """Nimal calls this to fund an open loan."""
    lender_user_id: uuid.UUID