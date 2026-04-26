import uuid
import enum
from datetime import datetime
from sqlalchemy import Column, String, Integer, Boolean, DateTime, Enum, Numeric, JSON
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base


class LoanStatus(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"
    active = "active"
    repaid = "repaid"
    defaulted = "defaulted"


class Loan(Base):
    __tablename__ = "loans"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    applicant_user_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    lender_user_id = Column(UUID(as_uuid=True), nullable=True)
    amount = Column(Numeric(precision=12, scale=2), nullable=False)
    interest_rate = Column(Numeric(precision=5, scale=2), nullable=False)
    term_weeks = Column(Integer, nullable=False)
    status = Column(Enum(LoanStatus), nullable=False, default=LoanStatus.pending)
    credit_score = Column(Integer, nullable=True)
    rejection_reason = Column(String(500), nullable=True)
    purpose = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    approved_at = Column(DateTime, nullable=True)
    due_date = Column(DateTime, nullable=True)


class LoanOutboxEvent(Base):
    __tablename__ = "loan_outbox_events"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    event_type = Column(String(50), nullable=False)
    payload = Column(JSON, nullable=False)
    published = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    published_at = Column(DateTime, nullable=True)