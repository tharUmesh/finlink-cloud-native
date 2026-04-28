from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql://finlink:finlink_local@postgres:5432/finlink_db"
    SECRET_KEY: str = "dev-secret-key-change-in-production"
    SERVICE_BUS_CONNECTION_STRING: str = ""
    SERVICE_NAME: str = "notification-service"

    # Cosmos DB — optional locally, required on Azure
    COSMOS_ENDPOINT: str = ""
    COSMOS_KEY: str = ""
    COSMOS_DATABASE: str = "finlink"
    COSMOS_CONTAINER: str = "notifications"

    model_config = {"env_file": ".env"}

settings = Settings()