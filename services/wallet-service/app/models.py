import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Numeric, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base


class Wallet(Base):
    __tablename__ = "wallets"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    # References users.id — but no FK constraint across services (correct microservice pattern)
    # Each service trusts the user_id from the JWT, not a DB-level foreign key
    user_id = Column(UUID(as_uuid=True), nullable=False, unique=True, index=True)
    balance = Column(Numeric(precision=12, scale=2), nullable=False, default=0)
    currency = Column(String(3), nullable=False, default="LKR")
    is_frozen = Column(String(20), nullable=False, default="active")  # active | frozen
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)