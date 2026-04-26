from datetime import datetime, timezone
import uuid

# This dictionary acts as our Cosmos DB container for local testing.
# Key: user_id, Value: Wallet Document
fake_cosmos_db = {}

def create_wallet_document(user_id: str) -> dict:
    if user_id in fake_cosmos_db:
        return fake_cosmos_db[user_id]
        
    wallet_doc = {
        "wallet_id": str(uuid.uuid4()),
        "user_id": user_id,
        "balance": 0.0,
        "currency": "LKR",
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc)
    }
    fake_cosmos_db[user_id] = wallet_doc
    return wallet_doc

def get_wallet_document(user_id: str) -> dict | None:
    return fake_cosmos_db.get(user_id)

def update_wallet_balance(user_id: str, amount: float) -> dict | None:
    wallet = fake_cosmos_db.get(user_id)
    if not wallet:
        return None
    
    # Business Logic: Prevent negative balances
    if wallet["balance"] + amount < 0:
        raise ValueError("Insufficient funds")
        
    wallet["balance"] += amount
    wallet["updated_at"] = datetime.now(timezone.utc)
    fake_cosmos_db[user_id] = wallet
    return wallet