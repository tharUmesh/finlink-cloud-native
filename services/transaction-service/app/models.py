import uuid
import enum
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Enum, Numeric, JSON
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base


class TransactionType(str, enum.Enum):
    transfer = "transfer"
    deposit = "deposit"
    withdrawal = "withdrawal"


class TransactionStatus(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    flagged = "flagged"
    failed = "failed"


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    sender_wallet_id = Column(UUID(as_uuid=True), nullable=True)
    receiver_wallet_id = Column(UUID(as_uuid=True), nullable=False)
    amount = Column(Numeric(precision=12, scale=2), nullable=False)
    currency = Column(String(3), nullable=False, default="LKR")
    transaction_type = Column(Enum(TransactionType), nullable=False)
    status = Column(Enum(TransactionStatus), nullable=False, default=TransactionStatus.pending)
    idempotency_key = Column(String(255), unique=True, nullable=True, index=True)
    meta = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class OutboxEvent(Base):
    __tablename__ = "outbox_events"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    event_type = Column(String(50), nullable=False)
    payload = Column(JSON, nullable=False)
    published = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    published_at = Column(DateTime, nullable=True)