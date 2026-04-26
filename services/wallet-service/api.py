from fastapi import APIRouter, HTTPException, status
import schemas, database

router = APIRouter()

@router.post("/", response_model=schemas.WalletResponse, status_code=status.HTTP_201_CREATED)
def create_wallet(request: schemas.WalletCreate):
    # In the future, this won't be an HTTP POST. 
    # It will be triggered automatically via an Azure Service Bus event.
    if database.get_wallet_document(request.user_id):
        raise HTTPException(status_code=400, detail="Wallet already exists for this user")
        
    wallet = database.create_wallet_document(request.user_id)
    return wallet

@router.get("/{user_id}", response_model=schemas.WalletResponse)
def get_wallet(user_id: str):
    wallet = database.get_wallet_document(user_id)
    if not wallet:
        raise HTTPException(status_code=404, detail="Wallet not found")
    return wallet

@router.post("/{user_id}/update-balance", response_model=schemas.WalletResponse)
def update_balance(user_id: str, update: schemas.BalanceUpdate):
    try:
        wallet = database.update_wallet_balance(user_id, update.amount)
        if not wallet:
            raise HTTPException(status_code=404, detail="Wallet not found")
        return wallet
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    
@router.get("/debug/all", tags=["Debug"])
def get_all_fake_wallets():
    return database.fake_cosmos_db