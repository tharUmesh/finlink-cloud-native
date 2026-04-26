import asyncio
import json
import logging
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models import LoanOutboxEvent
from app.config import settings

logger = logging.getLogger(__name__)


async def try_publish(event: LoanOutboxEvent) -> bool:
    if not settings.SERVICE_BUS_CONNECTION_STRING:
        logger.info(
            f"[LOAN OUTBOX] 📨 Event (local mode): "
            f"type={event.event_type} | loan_id={event.payload.get('loan_id')} | "
            f"decision={event.payload.get('status')}"
        )
        return True

    try:
        from azure.servicebus.aio import ServiceBusClient
        from azure.servicebus import ServiceBusMessage

        async with ServiceBusClient.from_connection_string(
            settings.SERVICE_BUS_CONNECTION_STRING
        ) as client:
            async with client.get_queue_sender(settings.SERVICE_BUS_QUEUE_NAME) as sender:
                await sender.send_messages(
                    ServiceBusMessage(json.dumps(event.payload), subject=event.event_type)
                )
                return True
    except Exception as e:
        logger.error(f"[LOAN OUTBOX] ❌ Publish failed: {e}")
        return False


async def loan_outbox_poller():
    logger.info("[LOAN OUTBOX] 🚀 Poller started")
    while True:
        await asyncio.sleep(2)
        db: Session = SessionLocal()
        try:
            pending = (
                db.query(LoanOutboxEvent)
                .filter(LoanOutboxEvent.published == False)  # noqa: E712
                .order_by(LoanOutboxEvent.created_at.asc())
                .limit(10)
                .all()
            )
            for event in pending:
                if await try_publish(event):
                    event.published = True
                    event.published_at = datetime.now(timezone.utc)
            if pending:
                db.commit()
        except Exception as e:
            logger.error(f"[LOAN OUTBOX] ❌ Poller error: {e}")
            db.rollback()
        finally:
            db.close()