"""
Cosmos DB client for notification-service.
Writes notification events to Cosmos DB when configured.
Falls back to PostgreSQL-only mode when COSMOS_ENDPOINT is not set (local dev).
"""
import logging
from app.config import settings

logger = logging.getLogger(__name__)


def get_cosmos_container():
    """
    Returns a Cosmos DB container client if configured, None otherwise.
    Called once at startup — result is stored in app state.
    """
    if not settings.COSMOS_ENDPOINT or not settings.COSMOS_KEY:
        logger.info("[COSMOS] No Cosmos DB config found — running in local PostgreSQL-only mode")
        return None

    try:
        from azure.cosmos import CosmosClient, PartitionKey, exceptions

        client = CosmosClient(settings.COSMOS_ENDPOINT, credential=settings.COSMOS_KEY)

        # Get or create database
        database = client.create_database_if_not_exists(id=settings.COSMOS_DATABASE)

        # Get or create container with /user_id as partition key
        container = database.create_container_if_not_exists(
            id=settings.COSMOS_CONTAINER,
            partition_key=PartitionKey(path="/user_id"),
            offer_throughput=400   # minimum — within free tier
        )

        logger.info(f"[COSMOS] ✅ Connected to Cosmos DB container: {settings.COSMOS_CONTAINER}")
        return container

    except Exception as e:
        logger.error(f"[COSMOS] ❌ Failed to connect to Cosmos DB: {e}")
        logger.info("[COSMOS] Falling back to PostgreSQL-only mode")
        return None


def write_to_cosmos(container, notification: dict) -> bool:
    """
    Writes a notification document to Cosmos DB.
    Returns True on success, False on failure.
    Failures are fire-and-forget — PostgreSQL write is always the source of truth.
    """
    if container is None:
        return False

    try:
        # Cosmos DB requires a string 'id' field
        document = {
            "id": str(notification["id"]),
            "user_id": str(notification["user_id"]),
            "event_type": notification["event_type"],
            "title": notification["title"],
            "message": notification["message"],
            "payload": notification.get("payload", {}),
            "is_read": False,
            "created_at": notification["created_at"],
        }

        container.upsert_item(body=document)
        logger.info(f"[COSMOS] ✅ Written to Cosmos: {notification['event_type']} for user {str(notification['user_id'])[:8]}...")
        return True

    except Exception as e:
        # Fire-and-forget — log failure but don't crash the notification flow
        logger.error(f"[COSMOS] ❌ Write failed (PostgreSQL still updated): {e}")
        return False