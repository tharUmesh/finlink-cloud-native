import httpx
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.schemas import (
    RegisterRequest, RegisterResponse,
    LoginRequest, LoginResponse,
    UserResponse
)
from app.auth import (
    hash_password, verify_password,
    create_access_token,
    get_current_user, require_admin
)
from app.config import settings

router = APIRouter()

# Wallet service URL — reads from env so it works both locally and on Azure
WALLET_SERVICE_URL = "http://wallet-service:8000"


# ─── POST /register ───────────────────────────────────────────────────────────

@router.post("/register", response_model=RegisterResponse, status_code=201)
async def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    # 1. Check for duplicates
    if db.query(User).filter(User.phone_number == payload.phone_number).first():
        raise HTTPException(status_code=400, detail="Phone number already registered")
    if db.query(User).filter(User.national_id == payload.national_id).first():
        raise HTTPException(status_code=400, detail="National ID already registered")

    # 2. Create user
    new_user = User(
        phone_number=payload.phone_number,
        national_id=payload.national_id,
        full_name=payload.full_name,
        password_hash=hash_password(payload.password),
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    print(f"[USER] ✅ User created: {new_user.id}")

    # 3. Create wallet — failure here must NEVER crash registration
    wallet_id = None
    wallet_url = f"{settings.WALLET_SERVICE_URL}/wallets"
    print(f"[USER] WALLET_SERVICE_URL = {settings.WALLET_SERVICE_URL}")
    print(f"[USER] Calling: POST {wallet_url}")

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(
                wallet_url,
                json={"user_id": str(new_user.id)}
            )
            print(f"[USER] wallet-service status={response.status_code} body={response.text[:200]}")

            if response.status_code in (200, 201):
                data = response.json()
                wallet_id = data.get("id")
                print(f"[USER] ✅ Wallet created: {wallet_id}")
            else:
                print(f"[USER] ⚠️ wallet-service error: {response.status_code} — {response.text[:200]}")

    except httpx.TimeoutException:
        print(f"[USER] ⚠️ Timeout calling wallet-service at {wallet_url}")
    except httpx.ConnectError as e:
        print(f"[USER] ⚠️ Cannot connect to wallet-service at {wallet_url}: {e}")
    except Exception as e:
        print(f"[USER] ⚠️ Unexpected error calling wallet-service: {type(e).__name__}: {e}")

    # 4. Always return success — wallet can be created later if it failed
    return RegisterResponse(
        message="Registration successful" if wallet_id else "Registration successful (wallet creation pending)",
        user=UserResponse.model_validate(new_user),
        wallet_id=wallet_id
    )


# ─── POST /login ──────────────────────────────────────────────────────────────

@router.post("/login", response_model=LoginResponse)
async def login(payload: LoginRequest, db: Session = Depends(get_db)):
    # 1. Find user
    user = db.query(User).filter(User.phone_number == payload.phone_number).first()
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    # 2. Check password
    if not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is deactivated")

    # 3. Get wallet_id from wallet-service
    wallet_id = None
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{WALLET_SERVICE_URL}/wallets/user/{user.id}")
            if response.status_code == 200:
                wallet_id = response.json().get("id")
    except httpx.RequestError:
        pass  # token still issued without wallet_id — wallet service may be starting up

    # 4. Issue JWT
    token = create_access_token(
        user_id=user.id,
        role=user.role.value,
        wallet_id=wallet_id
    )

    return LoginResponse(
        access_token=token,
        user=UserResponse.model_validate(user)
    )


# ─── GET /me ──────────────────────────────────────────────────────────────────

@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    """Returns the profile of whoever is logged in. Requires valid JWT."""
    return UserResponse.model_validate(current_user)


# ─── GET /users/{user_id} — admin only ───────────────────────────────────────

@router.get("/users/{user_id}", response_model=UserResponse)
def get_user(user_id: str, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    """Look up any user by ID. Requires admin JWT."""
    import uuid as _uuid
    user = db.query(User).filter(User.id == _uuid.UUID(user_id)).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return UserResponse.model_validate(user)

# ─── GET /users/by-phone/{phone} — internal service-to-service ────────────────

@router.get("/users/by-phone/{phone_number}")
def get_user_by_phone(phone_number: str, db: Session = Depends(get_db)):
    """
    Internal endpoint — called by transaction-service to resolve
    a phone number to a user_id before looking up their wallet.
    """
    user = db.query(User).filter(User.phone_number == phone_number).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return UserResponse.model_validate(user)