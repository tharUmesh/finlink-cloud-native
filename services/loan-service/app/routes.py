import uuid
import httpx
from datetime import datetime, timedelta, timezone
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Loan, LoanOutboxEvent, LoanStatus
from app.schemas import (
    LoanApplicationRequest, LoanApplicationResponse,
    LoanResponse, FundLoanRequest
)
from app.auth import get_current_user
from app.scoring import calculate_credit_score, calculate_interest_rate
from app.config import settings

from slowapi import Limiter
from slowapi.util import get_remote_address
from starlette.requests import Request

limiter = Limiter(key_func=get_remote_address)

router = APIRouter()


# ─── POST /loans/apply ────────────────────────────────────────────────────────

@router.post("/loans/apply", response_model=LoanApplicationResponse, status_code=201)
@limiter.limit("5/minute")
async def apply_for_loan(
    request: Request,
    payload: LoanApplicationRequest,
    db: Session = Depends(get_db),
    token_data: dict = Depends(get_current_user)
):
    """
    Ravi's flow: submit loan application, get instant decision.
    Credit score calculated synchronously — response includes approve/reject.
    """
    applicant_user_id = uuid.UUID(token_data["user_id"])
    wallet_id = token_data.get("wallet_id")

    if not wallet_id:
        raise HTTPException(status_code=400, detail="No wallet found on your account")

    # ── Gather data for credit scoring ────────────────────────────────────────
    wallet_created_at = datetime.now(timezone.utc)  # fallback
    current_balance = Decimal("0")
    transaction_count = 0

    async with httpx.AsyncClient(timeout=5.0) as client:
        # Get wallet info (balance + age)
        wallet_res = await client.get(
            f"{settings.WALLET_SERVICE_URL}/wallets/{wallet_id}"
        )
        if wallet_res.status_code == 200:
            wallet_data = wallet_res.json()
            current_balance = Decimal(str(wallet_data["balance"]))
            wallet_created_at = datetime.fromisoformat(wallet_data["created_at"])

    # Count transactions in our own DB
    from app.database import engine
    from sqlalchemy import text
    with engine.connect() as conn:
        # Check transaction-service's transactions table
        try:
            result = conn.execute(
                text("SELECT COUNT(*) FROM transactions WHERE sender_wallet_id = :wid OR receiver_wallet_id = :wid"),
                {"wid": uuid.UUID(wallet_id)}
            )
            transaction_count = result.scalar() or 0
        except Exception:
            transaction_count = 0  # table might not exist yet

    # Check for existing active loan
    has_active_loan = db.query(Loan).filter(
        Loan.applicant_user_id == applicant_user_id,
        Loan.status == LoanStatus.active
    ).first() is not None

    # ── Run credit scoring (synchronous — instant result) ─────────────────────
    score, reasons = calculate_credit_score(
        wallet_created_at=wallet_created_at,
        current_balance=current_balance,
        transaction_count=transaction_count,
        has_active_loan=has_active_loan,
        requested_amount=payload.amount,
    )

    interest_rate = calculate_interest_rate(score, payload.term_weeks)
    approved = score >= 60

    # ── Write loan record ──────────────────────────────────────────────────────
    now = datetime.now(timezone.utc)
    loan_id = uuid.uuid4() 
    loan = Loan(
        id=loan_id,
        applicant_user_id=applicant_user_id,
        amount=payload.amount,
        interest_rate=interest_rate,
        term_weeks=payload.term_weeks,
        purpose=payload.purpose,
        credit_score=score,
        status=LoanStatus.approved if approved else LoanStatus.rejected,
        approved_at=now if approved else None,
        rejection_reason=None if approved else f"Credit score too low ({score}/100). " + " | ".join(
            [r for r in reasons if r.startswith("✗")]
        ),
        due_date=now + timedelta(weeks=payload.term_weeks) if approved else None,
    )
    db.add(loan)

    # ── Write outbox event (same DB transaction) ───────────────────────────────
    event_type = "Loan_Approved" if approved else "Loan_Rejected"
    outbox = LoanOutboxEvent(
        event_type=event_type,
        payload={
            "loan_id": str(loan_id),
            "applicant_user_id": str(applicant_user_id),
            "amount": str(payload.amount),
            "status": loan.status.value,
            "credit_score": score,
            "interest_rate": str(interest_rate),
            "term_weeks": payload.term_weeks,
            "purpose": payload.purpose,
            "timestamp": now.isoformat(),
        }
    )
    db.add(outbox)
    db.commit()
    db.refresh(loan)

    return LoanApplicationResponse(
        loan=LoanResponse.model_validate(loan),
        decision="approved" if approved else "rejected",
        credit_score=score,
        message=(
            f"Loan approved! LKR {payload.amount} at {interest_rate}% interest. "
            f"Repay within {payload.term_weeks} weeks."
            if approved else
            f"Loan rejected (score: {score}/100). Reasons: " +
            ", ".join([r for r in reasons if r.startswith("✗")])
        )
    )


# ─── GET /loans — my loan history ─────────────────────────────────────────────

@router.get("/loans", response_model=list[LoanResponse])
def get_my_loans(
    db: Session = Depends(get_db),
    token_data: dict = Depends(get_current_user)
):
    """Returns all loans for the logged-in user."""
    user_id = uuid.UUID(token_data["user_id"])
    return db.query(Loan).filter(
        Loan.applicant_user_id == user_id
    ).order_by(Loan.created_at.desc()).all()


# ─── GET /loans/open — for lenders (Nimal's flow) ─────────────────────────────

@router.get("/loans/open", response_model=list[LoanResponse])
def get_open_loans(
    db: Session = Depends(get_db),
    token_data: dict = Depends(get_current_user)
):
    """
    Nimal's view — lists all approved loans waiting for funding.
    Any authenticated user can browse these.
    """
    return db.query(Loan).filter(
        Loan.status == LoanStatus.approved,
        Loan.lender_user_id == None  # noqa: E711 — not yet funded
    ).order_by(Loan.created_at.desc()).all()


# ─── POST /loans/{loan_id}/fund — Nimal funds a loan ─────────────────────────

@router.post("/loans/{loan_id}/fund", response_model=LoanResponse)
async def fund_loan(
    loan_id: uuid.UUID,
    payload: FundLoanRequest,
    db: Session = Depends(get_db),
    token_data: dict = Depends(get_current_user)
):
    """
    Nimal funds an open loan.
    Transfers the loan amount from Nimal's wallet to Ravi's wallet.
    """
    loan = db.query(Loan).filter(Loan.id == loan_id).first()
    if not loan:
        raise HTTPException(status_code=404, detail="Loan not found")
    if loan.status != LoanStatus.approved:
        raise HTTPException(status_code=400, detail="Loan is not available for funding")
    if loan.lender_user_id is not None:
        raise HTTPException(status_code=400, detail="Loan already funded")

    lender_wallet_id = token_data.get("wallet_id")
    if not lender_wallet_id:
        raise HTTPException(status_code=400, detail="No wallet on lender account")

    # Get borrower's wallet
    async with httpx.AsyncClient(timeout=5.0) as client:
        borrower_wallet_res = await client.get(
            f"{settings.WALLET_SERVICE_URL}/wallets/user/{loan.applicant_user_id}"
        )
        if borrower_wallet_res.status_code != 200:
            raise HTTPException(status_code=404, detail="Borrower wallet not found")
        borrower_wallet_id = borrower_wallet_res.json()["id"]

        # Debit lender
        debit_res = await client.put(
            f"{settings.WALLET_SERVICE_URL}/wallets/{lender_wallet_id}/balance",
            json={"amount": str(loan.amount), "operation": "debit"}
        )
        if debit_res.status_code != 200:
            raise HTTPException(status_code=400, detail="Insufficient funds to fund this loan")

        # Credit borrower
        await client.put(
            f"{settings.WALLET_SERVICE_URL}/wallets/{borrower_wallet_id}/balance",
            json={"amount": str(loan.amount), "operation": "credit"}
        )

    # Update loan status
    loan.lender_user_id = payload.lender_user_id
    loan.status = LoanStatus.active
    db.commit()
    db.refresh(loan)
    return loan


# ─── GET /loans/{loan_id} ─────────────────────────────────────────────────────

@router.get("/loans/{loan_id}", response_model=LoanResponse)
def get_loan(
    loan_id: uuid.UUID,
    db: Session = Depends(get_db),
    token_data: dict = Depends(get_current_user)
):
    loan = db.query(Loan).filter(Loan.id == loan_id).first()
    if not loan:
        raise HTTPException(status_code=404, detail="Loan not found")
    return loan