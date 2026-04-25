import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, JSON
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base


class NotificationEvent(Base):
    """
    Locally stored in PostgreSQL. On Azure, this moves to Cosmos DB
    for faster reads on the mobile transaction history feed.
    """
    __tablename__ = "notification_events"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    event_type = Column(String(50), nullable=False)   # "Transaction_Approved", "Fraud_Flagged", etc.
    title = Column(String(100), nullable=False)
    message = Column(String(500), nullable=False)
    payload = Column(JSON, nullable=True)             # full event data for mobile
    is_read = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)