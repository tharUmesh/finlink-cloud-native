"""
Rule-based fraud detection.
Each rule returns (is_suspicious, reason, severity).
All rules are checked — the worst severity wins.
"""
from decimal import Decimal
from datetime import datetime, timezone


def check_large_amount(amount: Decimal) -> tuple[bool, str, str]:
    """Flag unusually large transfers."""
    if amount >= 100000:
        return True, f"Very large transfer: LKR {amount}", "high"
    if amount >= 50000:
        return True, f"Large transfer: LKR {amount}", "medium"
    return False, "", "low"


def check_round_number(amount: Decimal) -> tuple[bool, str, str]:
    """
    Exact round numbers (e.g. 10000.00, 50000.00) are sometimes
    used in structuring attacks. Flag as low severity.
    """
    if amount >= 10000 and amount % 5000 == 0:
        return True, f"Suspicious round amount: LKR {amount}", "low"
    return False, "", "low"


def check_off_hours(timestamp: str) -> tuple[bool, str, str]:
    """Flag transfers between midnight and 4am Sri Lanka time (UTC+5:30)."""
    try:
        dt = datetime.fromisoformat(timestamp)
        # Convert to Sri Lanka time
        sl_hour = (dt.hour + 5) % 24  # simplified UTC+5 offset
        if 0 <= sl_hour < 4:
            return True, f"Off-hours transfer at {sl_hour:02d}:00 SL time", "medium"
    except Exception:
        pass
    return False, "", "low"


SEVERITY_RANK = {"low": 1, "medium": 2, "high": 3}


def evaluate_transaction(payload: dict) -> tuple[bool, str, str]:
    """
    Run all rules against a transaction payload.
    Returns (is_fraud, combined_reason, highest_severity).
    """
    amount = Decimal(str(payload.get("amount", "0")))
    timestamp = payload.get("timestamp", datetime.now(timezone.utc).isoformat())

    rules = [
        check_large_amount(amount),
        check_round_number(amount),
        check_off_hours(timestamp),
    ]

    triggered = [(reason, sev) for suspicious, reason, sev in rules if suspicious]

    if not triggered:
        return False, "", "low"

    # Combine all triggered reasons
    combined_reason = " | ".join(r for r, _ in triggered)
    highest_severity = max((s for _, s in triggered), key=lambda s: SEVERITY_RANK[s])

    return True, combined_reason, highest_severity