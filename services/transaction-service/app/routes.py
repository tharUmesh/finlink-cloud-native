import uuid
import json
from decimal import Decimal
from datetime import datetime, timezone
from typing import Optional

import httpx
from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Transaction, OutboxEvent, TransactionType, TransactionStatus
from app.schemas import TransferRequest, DepositRequest, TransactionResponse, TransactionListResponse
from app.auth import get_current_user
from app.config import settings

router = APIRouter()

WALLET_SERVICE_URL = settings.WALLET_SERVICE_URL
USER_SERVICE_URL   = settings.USER_SERVICE_URL


# ─── Helper: look up wallet by user phone number ───────────────────────────────

async def get_wallet_by_phone(phone: str) -> dict:
    """Asks user-service for the user, then wallet-service for their wallet."""
    async with httpx.AsyncClient(timeout=5.0) as client:
        # Step 1 — find user by phone (we'll add this endpoint to user-service shortly)
        user_res = await client.get(f"{USER_SERVICE_URL}/users/by-phone/{phone}")
        if user_res.status_code != 200:
            raise HTTPException(status_code=404, detail=f"User with phone {phone} not found")
        user = user_res.json()

        # Step 2 — get their wallet
        wallet_res = await client.get(f"{WALLET_SERVICE_URL}/wallets/user/{user['id']}")
        if wallet_res.status_code != 200:
            raise HTTPException(status_code=404, detail="Receiver wallet not found")
        return wallet_res.json()


# ─── POST /transfer ────────────────────────────────────────────────────────────

@router.post("/transfer", response_model=TransactionResponse, status_code=201)
async def transfer(
    payload: TransferRequest,
    db: Session = Depends(get_db),
    token_data: dict = Depends(get_current_user),
    idempotency_key: Optional[str] = Header(None, alias="Idempotency-Key")
):
    """
    P2P transfer from logged-in user to receiver (by phone number).
    Idempotency-Key header prevents duplicate transfers on retry.
    """

    # ① Idempotency check
    if idempotency_key:
        existing = db.query(Transaction).filter(
            Transaction.idempotency_key == idempotency_key
        ).first()
        if existing:
            # Already processed — return original result, don't charge again
            return existing

    sender_wallet_id = token_data.get("wallet_id")
    if not sender_wallet_id:
        raise HTTPException(status_code=400, detail="No wallet associated with your account")

    # ② Look up receiver wallet
    receiver_wallet = await get_wallet_by_phone(payload.receiver_phone)
    receiver_wallet_id = receiver_wallet["id"]

    if str(sender_wallet_id) == receiver_wallet_id:
        raise HTTPException(status_code=400, detail="Cannot transfer to yourself")

    if receiver_wallet["is_frozen"] == "frozen":
        raise HTTPException(status_code=400, detail="Receiver wallet is frozen")

    amount = Decimal(str(payload.amount))

    # ③ Debit sender — wallet-service validates sufficient funds
    async with httpx.AsyncClient(timeout=5.0) as client:
        debit_res = await client.put(
            f"{WALLET_SERVICE_URL}/wallets/{sender_wallet_id}/balance",
            json={"amount": str(amount), "operation": "debit"}
        )
        if debit_res.status_code != 200:
            error_detail = debit_res.json().get("detail", "Insufficient funds")
            raise HTTPException(status_code=400, detail=error_detail)

        # ④ Credit receiver
        credit_res = await client.put(
            f"{WALLET_SERVICE_URL}/wallets/{receiver_wallet_id}/balance",
            json={"amount": str(amount), "operation": "credit"}
        )
        if credit_res.status_code != 200:
            # Credit failed — refund the debit (compensating transaction)
            await client.put(
                f"{WALLET_SERVICE_URL}/wallets/{sender_wallet_id}/balance",
                json={"amount": str(amount), "operation": "credit"}
            )
            raise HTTPException(status_code=500, detail="Transfer failed — your money has been refunded")

    # ⑤ Write Transaction + OutboxEvent in the SAME DB transaction
    transaction_id = uuid.uuid4()
    event_payload = {
        "transaction_id": str(transaction_id),
        "sender_wallet_id": str(sender_wallet_id),
        "receiver_wallet_id": receiver_wallet_id,
        "amount": str(amount),
        "currency": "LKR",
        "sender_user_id": token_data["user_id"],
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "meta": {"note": payload.note, "receiver_phone": payload.receiver_phone}
    }

    new_transaction = Transaction(
        id=transaction_id,
        sender_wallet_id=uuid.UUID(sender_wallet_id),
        receiver_wallet_id=uuid.UUID(receiver_wallet_id),
        amount=amount,
        transaction_type=TransactionType.transfer,
        status=TransactionStatus.pending,
        idempotency_key=idempotency_key,
        meta={"note": payload.note, "receiver_phone": payload.receiver_phone}
    )

    outbox_event = OutboxEvent(
        event_type="Transaction_Pending",
        payload=event_payload,
        published=False
    )

    db.add(new_transaction)
    db.add(outbox_event)
    db.commit()       # both rows committed atomically
    db.refresh(new_transaction)

    return new_transaction


# ─── POST /deposit ─────────────────────────────────────────────────────────────

@router.post("/deposit", response_model=TransactionResponse, status_code=201)
async def deposit(
    payload: DepositRequest,
    db: Session = Depends(get_db),
    token_data: dict = Depends(get_current_user)
):
    """Simulated deposit — represents money coming in from outside."""
    amount = Decimal(str(payload.amount))

    async with httpx.AsyncClient(timeout=5.0) as client:
        res = await client.put(
            f"{WALLET_SERVICE_URL}/wallets/{payload.wallet_id}/balance",
            json={"amount": str(amount), "operation": "credit"}
        )
        if res.status_code != 200:
            raise HTTPException(status_code=400, detail="Deposit failed")

    transaction_id = uuid.uuid4()
    new_transaction = Transaction(
        id=transaction_id,
        sender_wallet_id=None,
        receiver_wallet_id=payload.wallet_id,
        amount=amount,
        transaction_type=TransactionType.deposit,
        status=TransactionStatus.approved,   # deposits skip fraud check
        meta={"source": "simulated_deposit"}
    )

    outbox_event = OutboxEvent(
        event_type="Transaction_Approved",
        payload={
            "transaction_id": str(transaction_id),
            "receiver_wallet_id": str(payload.wallet_id),
            "amount": str(amount),
            "type": "deposit",
            "timestamp": datetime.now(timezone.utc).isoformat()
        },
        published=False
    )

    db.add(new_transaction)
    db.add(outbox_event)
    db.commit()
    db.refresh(new_transaction)
    return new_transaction


# ─── GET /transactions ─────────────────────────────────────────────────────────

@router.get("/transactions", response_model=TransactionListResponse)
def get_my_transactions(
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db),
    token_data: dict = Depends(get_current_user)
):
    """Returns paginated transaction history for the logged-in user's wallet."""
    wallet_id_str = token_data.get("wallet_id")
    if not wallet_id_str:
        return TransactionListResponse(transactions=[], total=0)

    wallet_id = uuid.UUID(wallet_id_str)

    query = db.query(Transaction).filter(
        (Transaction.sender_wallet_id == wallet_id) |
        (Transaction.receiver_wallet_id == wallet_id)
    ).order_by(Transaction.created_at.desc())

    total = query.count()
    transactions = query.offset(skip).limit(limit).all()

    return TransactionListResponse(transactions=transactions, total=total)


# ─── GET /transactions/{transaction_id} ────────────────────────────────────────

@router.get("/transactions/{transaction_id}", response_model=TransactionResponse)
def get_transaction(
    transaction_id: uuid.UUID,
    db: Session = Depends(get_db),
    token_data: dict = Depends(get_current_user)
):
    """Get a single transaction by ID."""
    txn = db.query(Transaction).filter(Transaction.id == transaction_id).first()
    if not txn:
        raise HTTPException(status_code=404, detail="Transaction not found")
    return txn