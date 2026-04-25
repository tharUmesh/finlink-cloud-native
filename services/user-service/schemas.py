from pydantic import BaseModel, EmailStr, Field
from uuid import UUID
from datetime import datetime

# 1. What the frontend sends to register
class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8, description="Must be at least 8 characters")
    full_name: str = Field(..., min_length=2)
    nic: str = Field(..., min_length=10, description="National Identity Card number")
    phone_number: str = Field(..., min_length=10)

# 2. What we send back to the frontend (Notice: NO PASSWORD HERE)
class UserResponse(BaseModel):
    id: UUID
    email: EmailStr
    full_name: str
    kyc_verified: bool
    created_at: datetime

    class Config:
        from_attributes = True # Tells Pydantic to read SQLAlchemy models

# 3. JWT Token Schema for Login
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


