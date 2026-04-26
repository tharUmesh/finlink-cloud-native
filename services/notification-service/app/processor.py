"""
Notification-service processor.
Polls fraud_outbox_events and loan_outbox_events for unprocessed results.
Writes a NotificationEvent per user and logs a simulated push.
"""
import asyncio
import logging
from datetime import datetime, timezone

from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models import NotificationEvent

logger = logging.getLogger(__name__)


def build_notification(event_type: str, payload: dict) -> dict | None:
    """
    Converts a raw event payload into a user-facing notification.
    Returns None if we don't handle this event type.
    """
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
            # Read from fraud_outbox_events (Transaction_Approved, Fraud_Flagged)
            fraud_events = db.execute(text("""
                SELECT id, event_type, payload
                FROM fraud_outbox_events
                WHERE id NOT IN (
                    SELECT (payload->>'source_event_id')::uuid
                    FROM notification_events
                    WHERE payload->>'source_event_id' IS NOT NULL
                )
                ORDER BY created_at ASC
                LIMIT 10
            """)).fetchall()

            # Read from loan_outbox_events (Loan_Approved, Loan_Rejected)
            loan_events = db.execute(text("""
                SELECT id, event_type, payload
                FROM loan_outbox_events
                WHERE published = true
                  AND id NOT IN (
                      SELECT (payload->>'source_event_id')::uuid
                      FROM notification_events
                      WHERE payload->>'source_event_id' IS NOT NULL
                  )
                ORDER BY created_at ASC
                LIMIT 10
            """)).fetchall()

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

                notif = NotificationEvent(
                    user_id=notif_data["user_id"],
                    event_type=event_type,
                    title=notif_data["title"],
                    message=notif_data["message"],
                    payload={**payload, "source_event_id": source_id},
                )
                db.add(notif)

                # Simulated push notification log
                logger.info(
                    f"[NOTIFY] 📱 Push → user {notif_data['user_id'][:8]}... | "
                    f"{notif_data['title']} | {notif_data['message'][:60]}"
                )

            if all_events:
                db.commit()

        except Exception as e:
            logger.error(f"[NOTIFY] ❌ Processor error: {e}")
            db.rollback()
        finally:
            db.close()