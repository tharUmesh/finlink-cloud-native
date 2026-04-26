from sqlalchemy import Column, String, Float, DateTime, func
import uuid
from database import Base

class Transaction(Base):
    __tablename__ = "transactions"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    sender_wallet_id = Column(String, index=True, nullable=True) # Nullable for deposits
    receiver_wallet_id = Column(String, index=True, nullable=True) # Nullable for withdrawals
    amount = Column(Float, nullable=False)
    transaction_type = Column(String, nullable=False) # 'DEPOSIT', 'WITHDRAWAL', 'TRANSFER'
    status = Column(String, default="PENDING") # 'PENDING', 'COMPLETED', 'FAILED', 'BLOCKED'
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())