"""
Credit scoring engine.
Takes wallet and transaction data, returns a score (0-100) and explanation.
Runs synchronously — result returned in the same HTTP request.
"""
from decimal import Decimal
from datetime import datetime, timezone


def calculate_credit_score(
    wallet_created_at: datetime,
    current_balance: Decimal,
    transaction_count: int,
    has_active_loan: bool,
    requested_amount: Decimal,
) -> tuple[int, list[str]]:
    """
    Returns (score, reasons_list).
    score >= 60 → approve
    score <  60 → reject
    """
    score = 50
    reasons = []

    # + 20 points: wallet age (proves they're an established user)
    now = datetime.now(timezone.utc)
    wallet_age = now - wallet_created_at.replace(tzinfo=timezone.utc)
    if wallet_age.days >= 7:
        score += 20
        reasons.append(f"✓ Established wallet ({wallet_age.days} days old)")
    else:
        reasons.append(f"✗ New wallet (only {wallet_age.days} days old)")

    # + 15 points: healthy balance
    if current_balance >= 1000:
        score += 15
        reasons.append(f"✓ Healthy balance (LKR {current_balance})")
    else:
        reasons.append(f"✗ Low balance (LKR {current_balance})")

    # + 15 points: transaction history (proves active usage)
    if transaction_count >= 1:
        score += 15
        reasons.append(f"✓ Active transaction history ({transaction_count} transactions)")
    else:
        reasons.append("✗ No transaction history")

    # - 30 points: already has an unpaid loan (risk indicator)
    if has_active_loan:
        score -= 30
        reasons.append("✗ Existing active loan")
    else:
        reasons.append("✓ No existing loans")

    # - 20 points: large loan relative to typical profile
    if requested_amount > 40000:
        score -= 20
        reasons.append(f"✗ High loan amount (LKR {requested_amount})")
    else:
        reasons.append(f"✓ Reasonable loan amount (LKR {requested_amount})")

    # Clamp to 0-100
    score = max(0, min(100, score))
    return score, reasons


def calculate_interest_rate(score: int, term_weeks: int) -> Decimal:
    """
    Higher score = lower interest rate.
    Longer term = slightly higher rate.
    """
    if score >= 80:
        base_rate = Decimal("8.0")
    elif score >= 60:
        base_rate = Decimal("12.0")
    else:
        base_rate = Decimal("18.0")   # won't be used if rejected, but here for completeness

    # Add 0.5% per 4 weeks beyond the first month
    extra_weeks = max(0, term_weeks - 4)
    term_premium = Decimal(str(extra_weeks // 4)) * Decimal("0.5")

    return (base_rate + term_premium).quantize(Decimal("0.01"))