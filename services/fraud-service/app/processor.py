"""
Fraud-service event processor.
Polls outbox_events table for Transaction_Pending events.
Evaluates each one, writes results, updates transaction status.
"""
import asyncio
import uuid
import logging
from datetime import datetime, timezone

from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models import FraudFlag, FraudOutboxEvent, FraudSeverity
from app.rules import evaluate_transaction

logger = logging.getLogger(__name__)


async def process_pending_transactions():
    """
    Background task — polls every 3 seconds.
    Reads Transaction_Pending events from outbox_events.
    Writes fraud results back to the DB.
    """
    logger.info("[FRAUD] 🚀 Fraud processor started")

    while True:
        await asyncio.sleep(3)
        db: Session = SessionLocal()

        try:
            # Read unprocessed Transaction_Pending events
            # We mark them as "processed" by setting a processed flag
            # Using raw SQL to read from transaction-service's outbox table
            result = db.execute(text("""
                SELECT id, event_type, payload, created_at
                FROM outbox_events
                WHERE event_type = 'Transaction_Pending'
                  AND published = true
                  AND id NOT IN (
                      SELECT (payload->>'outbox_event_id')::uuid
                      FROM fraud_outbox_events
                      WHERE payload->>'outbox_event_id' IS NOT NULL
                  )
                ORDER BY created_at ASC
                LIMIT 10
            """))
            rows = result.fetchall()

            for row in rows:
                event_id = row[0]
                payload = row[2]

                if isinstance(payload, str):
                    import json
                    payload = json.loads(payload)

                transaction_id = payload.get("transaction_id")
                sender_user_id = payload.get("sender_user_id")
                amount = payload.get("amount")

                logger.info(f"[FRAUD] 🔍 Evaluating transaction {transaction_id} — LKR {amount}")

                is_fraud, reason, severity = evaluate_transaction(payload)

                if is_fraud:
                    # Write fraud flag
                    flag = FraudFlag(
                        transaction_id=uuid.UUID(transaction_id),
                        user_id=uuid.UUID(sender_user_id),
                        reason=reason,
                        severity=FraudSeverity(severity),
                    )
                    db.add(flag)

                    # Update transaction status to flagged
                    db.execute(text("""
                        UPDATE transactions
                        SET status = 'flagged', updated_at = NOW()
                        WHERE id = :txn_id
                    """), {"txn_id": uuid.UUID(transaction_id)})

                    event_type = "Fraud_Flagged"
                    logger.warning(f"[FRAUD] 🚨 FRAUD FLAGGED: {transaction_id} — {reason}")
                else:
                    # Update transaction status to approved
                    db.execute(text("""
                        UPDATE transactions
                        SET status = 'approved', updated_at = NOW()
                        WHERE id = :txn_id
                    """), {"txn_id": uuid.UUID(transaction_id)})

                    event_type = "Transaction_Approved"
                    logger.info(f"[FRAUD] ✅ Transaction approved: {transaction_id}")

                # Write result to fraud_outbox_events for notification-service
                result_event = FraudOutboxEvent(
                    event_type=event_type,
                    payload={
                        "outbox_event_id": str(event_id),
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

            if rows:
                db.commit()

        except Exception as e:
            logger.error(f"[FRAUD] ❌ Processor error: {e}")
            db.rollback()
        finally:
            db.close()