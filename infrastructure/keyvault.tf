# ─────────────────────────────────────────────────────────
# Key Vault — stores all secrets (DB passwords, API keys)
# Microservices read secrets from here, never hardcoded
# ─────────────────────────────────────────────────────────

# We need your Azure AD tenant ID for Key Vault access policy
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "finlink" {
  name                = "${var.project_name}-kv-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Allow your own account full access (so you can add secrets)
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge", "Recover"
    ]
  }

  # Allow the ACA Managed Identity to read secrets
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.aca_identity.principal_id

    secret_permissions = [
      "Get", "List"
    ]
  }

  tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Store PostgreSQL password in Key Vault
resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-admin-password"
  value        = var.postgresql_admin_password
  key_vault_id = azurerm_key_vault.finlink.id
}

# SECRET_KEY — shared JWT secret across all 6 services
resource "azurerm_key_vault_secret" "secret_key" {
  name         = "secret-key"
  value        = var.secret_key
  key_vault_id = azurerm_key_vault.finlink.id
}

# Service Bus connection string — services read this to connect
resource "azurerm_key_vault_secret" "servicebus_connection_string" {
  name         = "servicebus-connection-string"
  value        = azurerm_servicebus_namespace.finlink.default_primary_connection_string
  key_vault_id = azurerm_key_vault.finlink.id
}