import uuid
from datetime import datetime
from pydantic import BaseModel, field_validator, model_validator
import re


# ─── Request bodies (what the client sends) ───────────────────────────────────

class RegisterRequest(BaseModel):
    phone_number: str
    national_id: str
    full_name: str
    password: str

    @model_validator(mode="before")
    @classmethod
    def strip_strings(cls, values):
        """Strip leading/trailing whitespace from all string fields."""
        return {
            k: v.strip() if isinstance(v, str) else v
            for k, v in values.items()
        }

    @field_validator("phone_number")
    @classmethod
    def validate_phone(cls, v):
        if not re.match(r"^\+?[0-9]{9,15}$", v):
            raise ValueError("Invalid phone number format")
        return v

    @field_validator("password")
    @classmethod
    def validate_password(cls, v):
        if len(v) < 6:
            raise ValueError("Password must be at least 6 characters")
        return v

    @field_validator("national_id")
    @classmethod
    def validate_national_id(cls, v):
        if not re.match(r"^([0-9]{9}[VvXx]|[0-9]{12})$", v):
            raise ValueError("Invalid Sri Lankan National ID format")
        return v

    @field_validator("full_name")
    @classmethod
    def validate_full_name(cls, v):
        if len(v) < 2:
            raise ValueError("Full name too short")
        if len(v) > 100:
            raise ValueError("Full name too long")
        return v


class LoginRequest(BaseModel):
    phone_number: str
    password: str


# ─── Response bodies (what the API returns) ───────────────────────────────────

class UserResponse(BaseModel):
    id: uuid.UUID
    phone_number: str
    national_id: str
    full_name: str
    role: str
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}  # lets Pydantic read SQLAlchemy objects


class RegisterResponse(BaseModel):
    message: str
    user: UserResponse
    wallet_id: uuid.UUID | None = None   # None if wallet-service is down (graceful)


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


class TokenData(BaseModel):
    """What lives inside the JWT payload."""
    sub: str           # user_id as string
    role: str
    wallet_id: str | None = None