import asyncio
import uuid
import logging
from datetime import datetime, timezone

from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models import FraudFlag, FraudOutboxEvent, FraudSeverity
from app.rules import evaluate_transaction
from app.config import settings

logger = logging.getLogger(__name__)


async def process_single_event(payload: dict, db: Session):
    transaction_id = payload.get("transaction_id")
    sender_user_id = payload.get("sender_user_id")
    amount = payload.get("amount")

    if not transaction_id or not sender_user_id:
        return

    txn_uuid = uuid.UUID(transaction_id)

    # Check if we already processed this transaction — unique constraint backup
    existing = db.query(FraudOutboxEvent).filter(
        FraudOutboxEvent.transaction_id == txn_uuid
    ).first()
    if existing:
        logger.debug(f"[FRAUD] Skipping already-processed transaction {transaction_id}")
        return

    logger.info(f"[FRAUD] 🔍 Evaluating transaction {transaction_id} — LKR {amount}")

    is_fraud, reason, severity = evaluate_transaction(payload)

    if is_fraud:
        try:
            flag = FraudFlag(
                transaction_id=txn_uuid,
                user_id=uuid.UUID(sender_user_id),
                reason=reason,
                severity=FraudSeverity(severity),
            )
            db.add(flag)
            db.flush()
        except Exception:
            db.rollback()
            # Flag already exists — still write the outbox event

        db.execute(text("""
            UPDATE transactions
            SET status = 'flagged', updated_at = NOW()
            WHERE id = :txn_id
        """), {"txn_id": txn_uuid})
        event_type = "Fraud_Flagged"
        logger.warning(f"[FRAUD] 🚨 FLAGGED: {transaction_id} — {reason}")
    else:
        db.execute(text("""
            UPDATE transactions
            SET status = 'approved', updated_at = NOW()
            WHERE id = :txn_id
        """), {"txn_id": txn_uuid})
        event_type = "Transaction_Approved"
        logger.info(f"[FRAUD] ✅ Approved: {transaction_id}")

    result_event = FraudOutboxEvent(
        event_type=event_type,
        transaction_id=txn_uuid,   # unique column — DB rejects duplicates
        payload={
            "transaction_id": transaction_id,
            "sender_user_id": sender_user_id,
            "amount": amount,
            "is_fraud": is_fraud,
            "reason": reason if is_fraud else "Transaction looks normal",
            "severity": severity,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }
    )
    db.add(result_event)


async def process_via_service_bus():
    from azure.servicebus.aio import ServiceBusClient

    logger.info("[FRAUD] 🚀 Starting Service Bus consumer")

    async with ServiceBusClient.from_connection_string(
        settings.SERVICE_BUS_CONNECTION_STRING
    ) as client:
        async with client.get_queue_receiver(
            settings.SERVICE_BUS_QUEUE_NAME,
            max_wait_time=5
        ) as receiver:
            while True:
                messages = await receiver.receive_messages(max_message_count=10, max_wait_time=5)

                if not messages:
                    await asyncio.sleep(1)
                    continue

                db: Session = SessionLocal()
                try:
                    for msg in messages:
                        import json
                        payload = json.loads(str(msg))
                        if hasattr(msg, 'subject') and msg.subject != "Transaction_Pending":
                            await receiver.complete_message(msg)
                            continue
                        await process_single_event(payload, db)
                        await receiver.complete_message(msg)
                    db.commit()
                except Exception as e:
                    logger.error(f"[FRAUD] ❌ Service Bus error: {e}")
                    db.rollback()
                finally:
                    db.close()


async def process_via_db_poll():
    logger.info("[FRAUD] 🚀 Starting DB poll processor (local mode)")

    while True:
        await asyncio.sleep(3)
        db: Session = SessionLocal()
        try:
            # Simple query — dedup is handled by unique constraint on FraudOutboxEvent.transaction_id
            rows = db.execute(text("""
                SELECT id, event_type, payload, created_at
                FROM outbox_events
                WHERE event_type = 'Transaction_Pending'
                  AND published = true
                ORDER BY created_at ASC
                LIMIT 10
            """)).fetchall()

            for row in rows:
                payload = row[2]
                if isinstance(payload, str):
                    import json
                    payload = json.loads(payload)

                try:
                    await process_single_event(payload, db)
                    db.commit()
                except Exception as e:
                    db.rollback()
                    logger.debug(f"[FRAUD] Skipping duplicate: {e}")

        except Exception as e:
            logger.error(f"[FRAUD] ❌ Processor error: {e}")
            db.rollback()
        finally:
            db.close()


async def process_pending_transactions():
    if settings.SERVICE_BUS_CONNECTION_STRING:
        await process_via_service_bus()
    else:
        await process_via_db_poll()