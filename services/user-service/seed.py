"""
Run after docker compose up to create demo users + wallets.
Command: docker compose exec user-service python seed.py
"""
import sys
import httpx
sys.path.append("/app")

from app.database import SessionLocal, engine, Base
from app import models  # noqa
from app.models import User, UserRole
from app.auth import hash_password

Base.metadata.create_all(bind=engine)

DEMO_USERS = [
    {"phone_number": "+94771000001", "national_id": "199012345678", "full_name": "Ravi Perera",  "role": UserRole.user,   "password": "ravi1234"},
    {"phone_number": "+94771000002", "national_id": "198512345678", "full_name": "Nimal Silva",   "role": UserRole.lender, "password": "nimal1234"},
    {"phone_number": "+94771000003", "national_id": "197512345678", "full_name": "Admin User",    "role": UserRole.admin,  "password": "admin1234"},
]

db = SessionLocal()
created_users = []

# Step 1 — create users
for u in DEMO_USERS:
    exists = db.query(User).filter(User.phone_number == u["phone_number"]).first()
    if not exists:
        user = User(
            phone_number=u["phone_number"],
            national_id=u["national_id"],
            full_name=u["full_name"],
            role=u["role"],
            password_hash=hash_password(u["password"]),
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        created_users.append(user)
        print(f"✅ Created user: {u['full_name']}")
    else:
        created_users.append(exists)
        print(f"⏭️  Already exists: {u['full_name']}")

db.close()

# Step 2 — create wallets via wallet-service
# Also add starting balance for demo (Ravi gets LKR 5,000 to start)
WALLET_SERVICE_URL = "http://wallet-service:8000"

STARTING_BALANCES = {
    "+94771000001": "5000.00",   # Ravi — has some money to send
    "+94771000002": "50000.00",  # Nimal — lender, has money to fund loans
    "+94771000003": "0.00",      # Admin — no wallet needed but create anyway
}

for user in created_users:
    try:
        with httpx.Client(timeout=5.0) as client:
            # Create wallet
            res = client.post(f"{WALLET_SERVICE_URL}/wallets", json={"user_id": str(user.id)})
            if res.status_code in (200, 201):
                wallet = res.json()
                wallet_id = wallet["id"]

                # Set starting balance
                balance = STARTING_BALANCES.get(user.phone_number, "0.00")
                if balance != "0.00":
                    client.put(
                        f"{WALLET_SERVICE_URL}/wallets/{wallet_id}/balance",
                        json={"amount": balance, "operation": "set"}
                    )
                print(f"   💰 Wallet created for {user.full_name} — LKR {balance}")
            else:
                print(f"   ⚠️  Wallet already exists for {user.full_name}")
    except httpx.RequestError as e:
        print(f"   ❌ Could not reach wallet-service: {e}")

print("\n🎉 Seed complete.")