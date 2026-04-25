import uuid
import enum
from datetime import datetime
from sqlalchemy import Column, String, Integer, DateTime, Enum, Numeric
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base


class LoanStatus(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"
    active = "active"       # disbursed, repayment ongoing
    repaid = "repaid"
    defaulted = "defaulted"


class Loan(Base):
    __tablename__ = "loans"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    applicant_user_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    lender_user_id = Column(UUID(as_uuid=True), nullable=True)   # set when a lender funds it
    amount = Column(Numeric(precision=12, scale=2), nullable=False)
    interest_rate = Column(Numeric(precision=5, scale=2), nullable=False)  # e.g. 12.50 = 12.5%
    term_weeks = Column(Integer, nullable=False)
    status = Column(Enum(LoanStatus), nullable=False, default=LoanStatus.pending)
    credit_score = Column(Integer, nullable=True)       # 0–100 score from our model
    rejection_reason = Column(String(255), nullable=True)
    purpose = Column(String(255), nullable=True)        # "seeds", "school fees", etc.
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    approved_at = Column(DateTime, nullable=True)
    due_date = Column(DateTime, nullable=True)