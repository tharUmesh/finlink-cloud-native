"""
Notification-service processor.
Writes to BOTH PostgreSQL (source of truth) and Cosmos DB (fast mobile reads).
Cosmos DB write is fire-and-forget — failure does not affect PostgreSQL write.
"""
import asyncio
import logging
from datetime import datetime, timezone

from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models import NotificationEvent
from app.cosmos_client import write_to_cosmos

logger = logging.getLogger(__name__)

# Cosmos container — set during startup in main.py
cosmos_container = None


def set_cosmos_container(container):
    global cosmos_container
    cosmos_container = container


def build_notification(event_type: str, payload: dict) -> dict | None:
    if event_type == "Transaction_Approved":
        return {
            "user_id": payload.get("sender_user_id"),
            "title": "Transfer Successful ✅",
            "message": f"Your transfer of LKR {payload.get('amount')} was approved.",
        }
    if event_type == "Fraud_Flagged":
        return {
            "user_id": payload.get("sender_user_id"),
            "title": "⚠️ Suspicious Transaction Flagged",
            "message": f"A transfer of LKR {payload.get('amount')} was flagged: {payload.get('reason')}",
        }
    if event_type == "Loan_Approved":
        return {
            "user_id": payload.get("applicant_user_id"),
            "title": "Loan Approved 🎉",
            "message": f"Your loan of LKR {payload.get('amount')} has been approved at {payload.get('interest_rate')}% interest.",
        }
    if event_type == "Loan_Rejected":
        return {
            "user_id": payload.get("applicant_user_id"),
            "title": "Loan Application Update",
            "message": f"Your loan application for LKR {payload.get('amount')} was not approved.",
        }
    return None


async def process_notifications():
    logger.info("[NOTIFY] 🚀 Notification processor started")

    while True:
        await asyncio.sleep(3)
        db: Session = SessionLocal()

        try:
            fraud_events = []
            loan_events = []

            try:
                fraud_events = db.execute(text("""
                    SELECT foe.id, foe.event_type, foe.payload
                    FROM fraud_outbox_events foe
                    WHERE NOT EXISTS (
                        SELECT 1 FROM notification_events ne
                        WHERE ne.source_event_id = foe.id::text
                    )
                    ORDER BY foe.created_at ASC
                    LIMIT 10
                """)).fetchall()
            except Exception:
                db.rollback()

            try:
                loan_events = db.execute(text("""
                    SELECT loe.id, loe.event_type, loe.payload
                    FROM loan_outbox_events loe
                    WHERE loe.published = true
                      AND NOT EXISTS (
                          SELECT 1 FROM notification_events ne
                          WHERE ne.source_event_id = loe.id::text
                      )
                    ORDER BY loe.created_at ASC
                    LIMIT 10
                """)).fetchall()
            except Exception:
                db.rollback()

            all_events = list(fraud_events) + list(loan_events)

            for row in all_events:
                source_id = str(row[0])
                event_type = row[1]
                payload = row[2]

                if isinstance(payload, str):
                    import json
                    payload = json.loads(payload)

                notif_data = build_notification(event_type, payload)
                if not notif_data or not notif_data.get("user_id"):
                    continue

                try:
                    notif = NotificationEvent(
                        user_id=notif_data["user_id"],
                        event_type=event_type,
                        title=notif_data["title"],
                        message=notif_data["message"],
                        payload=payload,
                        source_event_id=source_id,   # unique column — DB rejects duplicates
                    )
                    db.add(notif)
                    db.commit()
                    db.refresh(notif)

                    write_to_cosmos(cosmos_container, {
                        "id": str(notif.id),
                        "user_id": str(notif.user_id),
                        "event_type": event_type,
                        "title": notif_data["title"],
                        "message": notif_data["message"],
                        "payload": payload,
                        "created_at": datetime.now(timezone.utc).isoformat(),
                    })

                    logger.info(
                        f"[NOTIFY] 📱 Push → user {str(notif_data['user_id'])[:8]}... | "
                        f"{notif_data['title']} | {notif_data['message'][:60]}"
                    )

                except Exception as e:
                    # Unique constraint violation = already processed — skip silently
                    db.rollback()
                    logger.debug(f"[NOTIFY] Skipping already-processed event {source_id}: {e}")

        except Exception as e:
            logger.error(f"[NOTIFY] ❌ Processor error: {e}")
            db.rollback()
        finally:
            db.close()