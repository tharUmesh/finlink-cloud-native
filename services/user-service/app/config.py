from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql://finlink:finlink_local@postgres:5432/finlink_db"
    SECRET_KEY: str = "dev-secret-key-change-in-production"
    SERVICE_BUS_CONNECTION_STRING: str = ""
    SERVICE_NAME: str = "user-service"
    WALLET_SERVICE_URL: str = "http://wallet-service:8000"  # local default

    model_config = {"env_file": ".env", "extra": "ignore"}

settings = Settings()