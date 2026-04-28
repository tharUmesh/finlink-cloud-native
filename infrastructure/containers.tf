# ─────────────────────────────────────────────────────────
# Local values — internal FQDNs for inter-service calls
# Format: https://<app-name>.internal.<env-domain>
# ─────────────────────────────────────────────────────────
locals {
  wallet_service_url = "https://wallet-service.internal.${azurerm_container_app_environment.finlink.default_domain}"
  user_service_url   = "https://user-service.internal.${azurerm_container_app_environment.finlink.default_domain}"
}

# ─────────────────────────────────────────────────────────
# user-service
# ─────────────────────────────────────────────────────────
resource "azurerm_container_app" "user_service" {
  name                         = "user-service"
  container_app_environment_id = azurerm_container_app_environment.finlink.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca_identity.id]
  }

  registry {
    server   = azurerm_container_registry.finlink.login_server
    identity = azurerm_user_assigned_identity.aca_identity.id
  }

  secret {
    name                = "secret-key"
    key_vault_secret_id = azurerm_key_vault_secret.secret_key.versionless_id
    identity            = azurerm_user_assigned_identity.aca_identity.id
  }
  secret {
    name                = "database-url"
    key_vault_secret_id = azurerm_key_vault_secret.db_url_users.versionless_id
    identity            = azurerm_user_assigned_identity.aca_identity.id
  }
  secret {
    name                = "sb-connection-string"
    key_vault_secret_id = azurerm_key_vault_secret.servicebus_connection_string.versionless_id
    identity            = azurerm_user_assigned_identity.aca_identity.id
  }

  template {
    min_replicas = 1
    max_replicas = 5

    container {
      name   = "user-service"
      image  = "${azurerm_container_registry.finlink.login_server}/user-service:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name        = "SECRET_KEY"
        secret_name = "secret-key"
      }
      env {
        name        = "DATABASE_URL"
        secret_name = "database-url"
      }
      env {
        name        = "SERVICE_BUS_CONNECTION_STRING"
        secret_name = "sb-connection-string"
      }
      env {
        name  = "SERVICE_BUS_QUEUE_NAME"
        value = "transactions"
      }
      env {
        name  = "WALLET_SERVICE_URL"
        value = local.wallet_service_url
      }

      liveness_probe {
        transport = "HTTP"
        path      = "/health"
        port      = 8000
      }
    }
  }

  ingress {
    external_enabled = false
    target_port      = 8000
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = { project = var.project_name, environment = var.environment }
}

# ─────────────────────────────────────────────────────────
# wallet-service
# ─────────────────────────────────────────────────────────
resource "azurerm_container_app" "wallet_service" {
  name                         = "wallet-service"
  container_app_environment_id = azurerm_container_app_environment.finlink.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca_identity.id]
  }

  registry {
    server   = azurerm_container_registry.finlink.login_server
    identity = azurerm_user_assigned_identity.aca_identity.id
  }

  secret {
    name                = "secret-key"
    key_vault_secret_id = azurerm_key_vault_secret.secret_key.versionless_id
    identity            = azurerm_user_assigned_identity.aca_identity.id
  }
  secret {
    name                = "database-url"
    key_vault_secret_id = azurerm_key_vault_secret.db_url_wallets.versionless_id
    identity            = azurerm_user_assigned_identity.aca_identity.id
  }
  secret {
    name                = "sb-connection-string"
    key_vault_secret_id = azurerm_key_vault_secret.servicebus_connection_string.versionless_id
    identity            = azurerm_user_assigned_identity.aca_identity.id
  }

  template {
    min_replicas = 0
    max_replicas = 5

    container {
      name   = "wallet-service"
      image  = "${azurerm_container_registry.finlink.login_server}/wallet-service:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name        = "SECRET_KEY"
        secret_name = "secret-key"
      }
      env {
        name        = "DATABASE_URL"
        secret_name = "database-url"
      }
      env {
        name        = "SERVICE_BUS_CONNECTION_STRING"
        secret_name = "sb-connection-string"
      }

      liveness_probe {
        transport = "HTTP"
        path      = "/health"
        port      = 8000
      }
    }
  }

  ingress {
    external_enabled = false
    target_port      = 8000
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = { project = var.project_name, environment = var.environment }
}

# ─────────────────────────────────────────────────────────
# transaction-service
# ─────────────────────────────────────────────────────────
resource "azurerm_container_app" "transaction_service" {
  name                         = "transaction-service"
  container_app_environment_id = azurerm_container_app_environment.finlink.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca_identity.id]
  }

  registry {
    server   = azurerm_container_registry.finlink.login_server
    identity = azurerm_user_assigned_identity.aca_identity.id
  }

  secret {
    name                = "secret-key"
    key_vault_secret_id = azurerm_key_vault_secret.secret_key.versionless_id
    identity            = azurerm_user_assigned_identity.aca_identity.id
  }
  secret {
    name                = "database-url"
    key_vault_secret_id = azurerm_key_vault_secret.db_url_transactions.versionless_id
    identity            = azurerm_user_assigned_identity.aca_identity.id
  }
  secret {
    name                = "sb-connection-string"
    key_vault_secret_id = azurerm_key_vault_secret.servicebus_connection_string.versionless_id
    identity            = azurerm_user_assigned_identity.aca_identity.id
  }

  template {
    min_replicas = 1
    max_replicas = 10  # highest traffic service

    container {
      name   = "transaction-service"
      image  = "${azurerm_container_registry.finlink.login_server}/transaction-service:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name        = "SECRET_KEY"
        secret_name = "secret-key"
      }
      env {
        name        = "DATABASE_URL"
        secret_name = "database-url"
      }
      env {
        name        = "SERVICE_BUS_CONNECTION_STRING"
        secret_name = "sb-connection-string"
      }
      env {
        name  = "SERVICE_BUS_QUEUE_NAME"
        value = "transactions"
      }
      env {
        name  = "WALLET_SERVICE_URL"
        value = local.wallet_service_url
      }
      env {
        name  = "USER_SERVICE_URL"
        value = local.user_service_url
      }

      liveness_probe {
        transport = "HTTP"
        path      = "/health"
        port      = 8000
      }
    }
  }

  ingress {
    external_enabled = false
    target_port      = 8000
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = { project = var.project_name, environment = var.environment }
}

# ─────────────────────────────────────────────────────────
# loan-service
# ─────────────────────────────────────────────────────────
resource "azurerm_container_app" "loan_service" {
  name                         = "loan-service"
  container_app_environment_id = azurerm_container_app_environment.finlink.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca_identity.id]
  }

  registry {
    server   = azurerm_container_registry.finlink.login_server
    identity = azurerm_user_assigned_identity.aca_identity.id
  }

  secret {
    name                = "secret-key"
    key_vault_secret_id = azurerm_key_vault_secret.secret_key.versionless_id
    identity            = azurerm_user_assigned_identity.aca_identity.id
  }
  secret {
    name                = "database-url"
    key_vault_secret_id = azurerm_key_vault_secret.db_url_loans.versionless_id
    identity            = azurerm_user_assigned_identity.aca_identity.id
  }
  secret {
    name                = "sb-connection-string"
    key_vault_secret_id = azurerm_key_vault_secret.servicebus_connection_string.versionless_id
    identity            = azurerm_user_assigned_identity.aca_identity.id
  }

  template {
    min_replicas = 0
    max_replicas = 5

    container {
      name   = "loan-service"
      image  = "${azurerm_container_registry.finlink.login_server}/loan-service:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name        = "SECRET_KEY"
        secret_name = "secret-key"
      }
      env {
        name        = "DATABASE_URL"
        secret_name = "database-url"
      }
      env {
        name        = "SERVICE_BUS_CONNECTION_STRING"
        secret_name = "sb-connection-string"
      }
      env {
        name  = "SERVICE_BUS_QUEUE_NAME"
        value = "loan-events"
      }
      env {
        name  = "WALLET_SERVICE_URL"
        value = local.wallet_service_url
      }

      liveness_probe {
        transport = "HTTP"
        path      = "/health"
        port      = 8000
      }
    }
  }

  ingress {
    external_enabled = false
    target_port      = 8000
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = { project = var.project_name, environment = var.environment }
}

# ─────────────────────────────────────────────────────────
# fraud-service
# ─────────────────────────────────────────────────────────
resource "azurerm_container_app" "fraud_service" {
  name                         = "fraud-service"
  container_app_environment_id = azurerm_container_app_environment.finlink.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca_identity.id]
  }

  registry {
    server   = azurerm_container_registry.finlink.login_server
    identity = azurerm_user_assigned_identity.aca_identity.id
  }

  secret {
    name                = "secret-key"
    key_vault_secret_id = azurerm_key_vault_secret.secret_key.versionless_id
    identity            = azurerm_user_assigned_identity.aca_identity.id
  }
  secret {
    name                = "database-url"
    key_vault_secret_id = azurerm_key_vault_secret.db_url_fraud.versionless_id
    identity            = azurerm_user_assigned_identity.aca_identity.id
  }
  secret {
    name                = "sb-connection-string"
    key_vault_secret_id = azurerm_key_vault_secret.servicebus_connection_string.versionless_id
    identity            = azurerm_user_assigned_identity.aca_identity.id
  }

  template {
    min_replicas = 0
    max_replicas = 5

    container {
      name   = "fraud-service"
      image  = "${azurerm_container_registry.finlink.login_server}/fraud-service:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name        = "SECRET_KEY"
        secret_name = "secret-key"
      }
      env {
        name        = "DATABASE_URL"
        secret_name = "database-url"
      }
      env {
        name        = "SERVICE_BUS_CONNECTION_STRING"
        secret_name = "sb-connection-string"
      }
      env {
        name  = "SERVICE_BUS_QUEUE_NAME"
        value = "transactions"
      }

      liveness_probe {
        transport = "HTTP"
        path      = "/health"
        port      = 8000
      }
    }
  }

  ingress {
    external_enabled = false
    target_port      = 8000
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = { project = var.project_name, environment = var.environment }
}

# ─────────────────────────────────────────────────────────
# notification-service
# ─────────────────────────────────────────────────────────
resource "azurerm_container_app" "notification_service" {
  name                         = "notification-service"
  container_app_environment_id = azurerm_container_app_environment.finlink.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca_identity.id]
  }

  registry {
    server   = azurerm_container_registry.finlink.login_server
    identity = azurerm_user_assigned_identity.aca_identity.id
  }

  secret {
    name                = "secret-key"
    key_vault_secret_id = azurerm_key_vault_secret.secret_key.versionless_id
    identity            = azurerm_user_assigned_identity.aca_identity.id
  }
  secret {
    name                = "database-url"
    key_vault_secret_id = azurerm_key_vault_secret.db_url_notifications.versionless_id
    identity            = azurerm_user_assigned_identity.aca_identity.id
  }
  secret {
    name                = "sb-connection-string"
    key_vault_secret_id = azurerm_key_vault_secret.servicebus_connection_string.versionless_id
    identity            = azurerm_user_assigned_identity.aca_identity.id
  }
  secret {
    name                = "cosmos-key"
    key_vault_secret_id = azurerm_key_vault_secret.cosmos_key.versionless_id
    identity            = azurerm_user_assigned_identity.aca_identity.id
  }

  template {
    min_replicas = 0
    max_replicas = 5

    container {
      name   = "notification-service"
      image  = "${azurerm_container_registry.finlink.login_server}/notification-service:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name        = "SECRET_KEY"
        secret_name = "secret-key"
      }
      env {
        name        = "DATABASE_URL"
        secret_name = "database-url"
      }
      env {
        name        = "SERVICE_BUS_CONNECTION_STRING"
        secret_name = "sb-connection-string"
      }
      env {
        name  = "COSMOS_ENDPOINT"
        value = "https://finlink-cosmos-dev.documents.azure.com:443/"
      }
      env {
        name        = "COSMOS_KEY"
        secret_name = "cosmos-key"
      }

      liveness_probe {
        transport = "HTTP"
        path      = "/health"
        port      = 8000
      }
    }
  }

  ingress {
    external_enabled = false
    target_port      = 8000
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = { project = var.project_name, environment = var.environment }
}