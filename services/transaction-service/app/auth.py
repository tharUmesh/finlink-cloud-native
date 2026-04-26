import uuid
from jose import JWTError, jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.config import settings

ALGORITHM = "HS256"
bearer_scheme = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme)
) -> dict:
    """
    Reads JWT, returns payload.
    { "user_id": str, "role": str, "wallet_id": str | None }
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

        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")

        return {"user_id": user_id, "role": role, "wallet_id": wallet_id}

    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token"
        )