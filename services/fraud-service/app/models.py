import uuid
import enum
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Enum, JSON, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base


class FraudSeverity(str, enum.Enum):
    low = "low"
    medium = "medium"
    high = "high"


class FraudFlag(Base):
    __tablename__ = "fraud_flags"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    transaction_id = Column(UUID(as_uuid=True), nullable=False, unique=True, index=True)
    user_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    reason = Column(String(255), nullable=False)
    severity = Column(Enum(FraudSeverity), nullable=False, default=FraudSeverity.medium)
    resolved = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)


class FraudOutboxEvent(Base):
    __tablename__ = "fraud_outbox_events"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    event_type = Column(String(50), nullable=False)
    payload = Column(JSON, nullable=False)
    published = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    # One result event per transaction — prevents duplicate processing
    transaction_id = Column(UUID(as_uuid=True), nullable=True, unique=True, index=True)