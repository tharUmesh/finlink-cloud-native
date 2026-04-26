import uuid
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime
from typing import Optional

from app.database import get_db
from app.models import FraudFlag

router = APIRouter()


class FraudFlagResponse(BaseModel):
    id: uuid.UUID
    transaction_id: uuid.UUID
    user_id: uuid.UUID
    reason: str
    severity: str
    resolved: bool
    created_at: datetime

    model_config = {"from_attributes": True}


@router.get("/fraud/flags", response_model=list[FraudFlagResponse])
def get_fraud_flags(
    resolved: Optional[bool] = None,
    db: Session = Depends(get_db)
):
    """Admin view — list all fraud flags. Filter by resolved status."""
    query = db.query(FraudFlag)
    if resolved is not None:
        query = query.filter(FraudFlag.resolved == resolved)
    return query.order_by(FraudFlag.created_at.desc()).limit(50).all()


@router.post("/fraud/flags/{flag_id}/resolve", response_model=FraudFlagResponse)
def resolve_flag(flag_id: uuid.UUID, db: Session = Depends(get_db)):
    """Mark a fraud flag as resolved (admin clears it)."""
    flag = db.query(FraudFlag).filter(FraudFlag.id == flag_id).first()
    if not flag:
        raise HTTPException(status_code=404, detail="Flag not found")
    flag.resolved = True
    db.commit()
    db.refresh(flag)
    return flag