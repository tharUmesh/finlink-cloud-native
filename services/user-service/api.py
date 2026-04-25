# app/api.py
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
import schemas, models, security
from database import get_db

router = APIRouter()

@router.post("/register", response_model=schemas.UserResponse, status_code=status.HTTP_201_CREATED)
def register_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    # 1. Check for duplicates (Email or NIC)
    if db.query(models.User).filter(models.User.email == user.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    if db.query(models.User).filter(models.User.nic == user.nic).first():
        raise HTTPException(status_code=400, detail="NIC already registered")

    # 2. Hash password and save
    new_user = models.User(
        email=user.email,
        hashed_password=security.get_password_hash(user.password),
        full_name=user.full_name,
        nic=user.nic,
        phone_number=user.phone_number
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # 3. ASYNC COMMUNICATION PLACEHOLDER: 
    # TODO: Publish 'UserRegistered' event to Azure Service Bus here.
    # The Wallet Service will listen for this to create the user's initial wallet.

    return new_user

@router.post("/login", response_model=schemas.Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == form_data.username).first()
    if not user or not security.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Incorrect email or password")
    
    access_token = security.create_access_token(data={"sub": user.email, "id": str(user.id)})
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=schemas.UserResponse)
def get_my_profile(current_user: models.User = Depends(security.get_current_user)):
    # This route is protected. Only users with a valid JWT can access it.
    return current_user