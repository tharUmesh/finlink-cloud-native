import uuid
from jose import JWTError, jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.config import settings

ALGORITHM = "HS256"
bearer_scheme = HTTPBearer()


def get_current_wallet_owner(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme)
) -> dict:
    """
    Reads the JWT and returns the payload dict.
    Does NOT query the database — trusts the signed token.
    Returns: { "user_id": str, "role": str, "wallet_id": str | None }
    """
    try:
        payload = jwt.decode(
            credentials.credentials,
            settings.SECRET_KEY,
            algorithms=[ALGORITHM]
        )
        user_id = payload.get("sub")
        role = payload.get("role")
        wallet_id = payload.get("wallet_id")

        if user_id is None or role is None:
            raise HTTPException(status_code=401, detail="Invalid token")

        return {"user_id": user_id, "role": role, "wallet_id": wallet_id}

    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token"
        )


def require_admin_role(token_data: dict = Depends(get_current_wallet_owner)) -> dict:
    if token_data["role"] != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    return token_data