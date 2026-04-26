import uuid
import enum
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Enum
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base


class UserRole(str, enum.Enum):
    user = "user"
    admin = "admin"
    lender = "lender"


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    phone_number = Column(String(20), unique=True, nullable=False, index=True)
    national_id = Column(String(20), unique=True, nullable=False)
    full_name = Column(String(100), nullable=False)
    role = Column(Enum(UserRole), nullable=False, default=UserRole.user)
    password_hash = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # No wallet relationship here — wallet-service owns that data