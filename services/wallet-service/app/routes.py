import uuid
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Wallet
from app.schemas import CreateWalletRequest, WalletResponse

router = APIRouter()


@router.post("/wallets", response_model=WalletResponse, status_code=201)
def create_wallet(payload: CreateWalletRequest, db: Session = Depends(get_db)):
    """Called by user-service after a new user registers."""
    # Check wallet doesn't already exist for this user
    existing = db.query(Wallet).filter(Wallet.user_id == payload.user_id).first()
    if existing:
        return existing  # idempotent — return existing wallet if called twice

    wallet = Wallet(user_id=payload.user_id)
    db.add(wallet)
    db.commit()
    db.refresh(wallet)
    return wallet


@router.get("/wallets/user/{user_id}", response_model=WalletResponse)
def get_wallet_by_user(user_id: uuid.UUID, db: Session = Depends(get_db)):
    """Called by user-service during login to get wallet_id for JWT."""
    wallet = db.query(Wallet).filter(Wallet.user_id == user_id).first()
    if not wallet:
        raise HTTPException(status_code=404, detail="Wallet not found")
    return wallet


@router.get("/wallets/me", response_model=WalletResponse)
def get_my_wallet(wallet_id: str, db: Session = Depends(get_db)):
    """Public endpoint — will add JWT auth in Day 2."""
    wallet = db.query(Wallet).filter(Wallet.id == uuid.UUID(wallet_id)).first()
    if not wallet:
        raise HTTPException(status_code=404, detail="Wallet not found")
    return wallet