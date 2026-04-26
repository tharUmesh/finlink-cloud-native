import uuid
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime
from typing import Optional

from app.database import get_db
from app.models import NotificationEvent

router = APIRouter()


class NotificationResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    event_type: str
    title: str
    message: str
    is_read: bool
    created_at: datetime

    model_config = {"from_attributes": True}


@router.get("/notifications/{user_id}", response_model=list[NotificationResponse])
def get_notifications(
    user_id: uuid.UUID,
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db)
):
    """Returns notification feed for a user — mobile app calls this."""
    return (
        db.query(NotificationEvent)
        .filter(NotificationEvent.user_id == user_id)
        .order_by(NotificationEvent.created_at.desc())
        .offset(skip).limit(limit).all()
    )


@router.post("/notifications/{notification_id}/read", response_model=NotificationResponse)
def mark_read(notification_id: uuid.UUID, db: Session = Depends(get_db)):
    """Mark a notification as read."""
    notif = db.query(NotificationEvent).filter(NotificationEvent.id == notification_id).first()
    if notif:
        notif.is_read = True
        db.commit()
        db.refresh(notif)
    return notif