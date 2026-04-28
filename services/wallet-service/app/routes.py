import uuid
from decimal import Decimal
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Wallet
from app.schemas import (
    CreateWalletRequest, WalletResponse,
    BalanceUpdateRequest, WalletSummary
)
from app.auth import get_current_wallet_owner, require_admin_role

router = APIRouter()


# ─── POST /wallets ─────────────────────────────────────────────────────────────
# Called by user-service after registration. No JWT needed (internal call).

@router.post("/wallets", response_model=WalletResponse, status_code=201)
def create_wallet(payload: CreateWalletRequest, db: Session = Depends(get_db)):
    """Creates a wallet for a user. Idempotent — returns existing if already created."""
    existing = db.query(Wallet).filter(Wallet.user_id == payload.user_id).first()
    if existing:
        return existing

    wallet = Wallet(user_id=payload.user_id)
    db.add(wallet)
    db.commit()
    db.refresh(wallet)
    return wallet


# ─── GET /wallets/me ───────────────────────────────────────────────────────────
# The mobile app calls this to show the balance on the home screen.

@router.get("/wallets/me", response_model=WalletResponse)
def get_my_wallet(
    db: Session = Depends(get_db),
    token_data: dict = Depends(get_current_wallet_owner)
):
    """Returns the wallet of whoever is logged in."""
    user_id = uuid.UUID(token_data["user_id"])
    wallet = db.query(Wallet).filter(Wallet.user_id == user_id).first()
    if not wallet:
        raise HTTPException(status_code=404, detail="Wallet not found. Please contact support.")
    return wallet


# ─── GET /wallets/user/{user_id} ───────────────────────────────────────────────
# Called by user-service during login to fetch wallet_id for the JWT.
# Also used by transaction-service to look up the receiver's wallet.

@router.get("/wallets/user/{user_id}", response_model=WalletResponse)
def get_wallet_by_user(user_id: uuid.UUID, db: Session = Depends(get_db)):
    """Fetch wallet by user_id. No auth — internal service-to-service call."""
    wallet = db.query(Wallet).filter(Wallet.user_id == user_id).first()
    if not wallet:
        raise HTTPException(status_code=404, detail="Wallet not found")
    return wallet

@router.get("/wallets/{wallet_id}", response_model=WalletResponse)
def get_wallet_by_id(wallet_id: uuid.UUID, db: Session = Depends(get_db)):
    """Fetch wallet by wallet_id directly. Internal service-to-service call."""
    wallet = db.query(Wallet).filter(Wallet.id == wallet_id).first()
    if not wallet:
        raise HTTPException(status_code=404, detail="Wallet not found")
    return wallet


# ─── PUT /wallets/{wallet_id}/balance ──────────────────────────────────────────
# INTERNAL ONLY — called by transaction-service and seed script.
# Not exposed to mobile app. In production this would require a service token.

@router.put("/wallets/{wallet_id}/balance", response_model=WalletResponse)
def update_balance(
    wallet_id: uuid.UUID,
    payload: BalanceUpdateRequest,
    db: Session = Depends(get_db)
):
    """
    Credits, debits, or sets a wallet balance.
    Called internally by transaction-service — not a public endpoint.
    """
    wallet = db.query(Wallet).filter(Wallet.id == wallet_id).first()
    if not wallet:
        raise HTTPException(status_code=404, detail="Wallet not found")

    if wallet.is_frozen == "frozen":
        raise HTTPException(status_code=403, detail="Wallet is frozen")

    current_balance = Decimal(str(wallet.balance))
    amount = Decimal(str(payload.amount))

    if payload.operation == "credit":
        wallet.balance = current_balance + amount

    elif payload.operation == "debit":
        if current_balance < amount:
            raise HTTPException(
                status_code=400,
                detail=f"Insufficient funds. Balance: {current_balance} LKR, Required: {amount} LKR"
            )
        wallet.balance = current_balance - amount

    elif payload.operation == "set":
        wallet.balance = amount

    db.commit()
    db.refresh(wallet)
    return wallet


# ─── POST /wallets/{wallet_id}/freeze ──────────────────────────────────────────
# Admin freezes a suspicious wallet.

@router.post("/wallets/{wallet_id}/freeze", response_model=WalletResponse)
def freeze_wallet(
    wallet_id: uuid.UUID,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin_role)
):
    """Freeze a wallet. Admin only."""
    wallet = db.query(Wallet).filter(Wallet.id == wallet_id).first()
    if not wallet:
        raise HTTPException(status_code=404, detail="Wallet not found")

    wallet.is_frozen = "frozen"
    db.commit()
    db.refresh(wallet)
    return wallet


# ─── POST /wallets/{wallet_id}/unfreeze ────────────────────────────────────────

@router.post("/wallets/{wallet_id}/unfreeze", response_model=WalletResponse)
def unfreeze_wallet(
    wallet_id: uuid.UUID,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin_role)
):
    """Unfreeze a wallet. Admin only."""
    wallet = db.query(Wallet).filter(Wallet.id == wallet_id).first()
    if not wallet:
        raise HTTPException(status_code=404, detail="Wallet not found")

    wallet.is_frozen = "active"
    db.commit()
    db.refresh(wallet)
    return wallet


# ─── GET /wallets — admin: list all wallets ────────────────────────────────────

@router.get("/wallets", response_model=list[WalletSummary])
def list_all_wallets(
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin_role)
):
    """List all wallets. Admin only — used for the dashboard."""
    return db.query(Wallet).all()