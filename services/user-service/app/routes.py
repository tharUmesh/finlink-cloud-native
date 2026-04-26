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

    # 3. Create wallet via wallet-service (inter-service HTTP call)
    wallet_id = None
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.post(
                f"{WALLET_SERVICE_URL}/wallets",
                json={"user_id": str(new_user.id)}
            )
            if response.status_code == 201:
                wallet_id = response.json().get("id")
    except httpx.RequestError:
        # Wallet service is unreachable — user is still created, wallet created later
        # In production this would trigger a retry/saga, but for MVP we log and continue
        print(f"⚠️  Could not reach wallet-service for user {new_user.id} — wallet not created")

    return RegisterResponse(
        message="Registration successful",
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