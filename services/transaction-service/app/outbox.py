"""
Outbox Pattern poller.

Runs as a background asyncio task. Every 2 seconds it:
  1. Reads all OutboxEvent rows where published=False
  2. Sends each to Azure Service Bus (or logs if no connection string)
  3. Marks them published=True

This guarantees events are never lost even if Service Bus is
temporarily unavailable when the transfer happens.
"""
import asyncio
import json
import logging
from datetime import datetime, timezone

from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models import OutboxEvent
from app.config import settings

logger = logging.getLogger(__name__)


async def try_publish_to_service_bus(event: OutboxEvent) -> bool:
    """
    Attempts to publish the event to Azure Service Bus.
    Returns True if published, False if failed/not configured.
    """
    if not settings.SERVICE_BUS_CONNECTION_STRING:
        # No connection string — running locally without Azure
        # Just log the event so we can see it in docker compose logs
        logger.info(
            f"[OUTBOX] 📨 Event published (local mode): "
            f"type={event.event_type} | "
            f"transaction_id={event.payload.get('transaction_id')} | "
            f"amount={event.payload.get('amount')} LKR"
        )
        return True

    try:
        from azure.servicebus.aio import ServiceBusClient
        from azure.servicebus import ServiceBusMessage

        async with ServiceBusClient.from_connection_string(
            settings.SERVICE_BUS_CONNECTION_STRING
        ) as client:
            async with client.get_queue_sender(settings.SERVICE_BUS_QUEUE_NAME) as sender:
                message = ServiceBusMessage(
                    json.dumps(event.payload),
                    subject=event.event_type,
                )
                await sender.send_messages(message)
                logger.info(f"[OUTBOX] ✅ Published to Service Bus: {event.event_type}")
                return True

    except Exception as e:
        logger.error(f"[OUTBOX] ❌ Failed to publish to Service Bus: {e}")
        return False


async def outbox_poller():
    """
    Background task that runs forever.
    Polls every 2 seconds for unpublished outbox events.
    """
    logger.info("[OUTBOX] 🚀 Outbox poller started")

    while True:
        await asyncio.sleep(2)

        db: Session = SessionLocal()
        try:
            # Fetch all unpublished events (oldest first)
            pending = (
                db.query(OutboxEvent)
                .filter(OutboxEvent.published == False)  # noqa: E712
                .order_by(OutboxEvent.created_at.asc())
                .limit(10)   # process max 10 at a time
                .all()
            )

            for event in pending:
                success = await try_publish_to_service_bus(event)
                if success:
                    event.published = True
                    event.published_at = datetime.now(timezone.utc)

            if pending:
                db.commit()

        except Exception as e:
            logger.error(f"[OUTBOX] ❌ Poller error: {e}")
            db.rollback()
        finally:
            db.close()