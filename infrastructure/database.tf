locals {
  pg_password_encoded = replace(var.postgresql_admin_password, "@", "%40")
}
# ─────────────────────────────────────────────────────────
# PostgreSQL Flexible Server — one server, 6 databases
# ─────────────────────────────────────────────────────────
resource "azurerm_postgresql_flexible_server" "finlink" {
  name                         = "${var.project_name}-postgres-${var.environment}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "16"
  administrator_login          = var.postgresql_admin_username
  administrator_password       = var.postgresql_admin_password
  storage_mb                   = 32768
  sku_name                     = "B_Standard_B1ms"
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  lifecycle {
    ignore_changes = [zone]   
  }

  tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Allow Azure services to connect
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure" {
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.finlink.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# 6 separate databases — one per microservice
resource "azurerm_postgresql_flexible_server_database" "users" {
  name      = "finlink_users"
  server_id = azurerm_postgresql_flexible_server.finlink.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_postgresql_flexible_server_database" "wallets" {
  name      = "finlink_wallets"
  server_id = azurerm_postgresql_flexible_server.finlink.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_postgresql_flexible_server_database" "transactions" {
  name      = "finlink_transactions"
  server_id = azurerm_postgresql_flexible_server.finlink.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_postgresql_flexible_server_database" "loans" {
  name      = "finlink_loans"
  server_id = azurerm_postgresql_flexible_server.finlink.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_postgresql_flexible_server_database" "fraud" {
  name      = "finlink_fraud"
  server_id = azurerm_postgresql_flexible_server.finlink.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_postgresql_flexible_server_database" "notifications" {
  name      = "finlink_notifications"
  server_id = azurerm_postgresql_flexible_server.finlink.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# ─────────────────────────────────────────────────────────
# Cosmos DB — for notification-service transaction feed
# Free tier: 1000 RU/s + 25 GB free
# ─────────────────────────────────────────────────────────
resource "azurerm_cosmosdb_account" "finlink" {
  name                = var.cosmosdb_account_name
  location            = var.cosmosdb_location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  free_tier_enabled   = true        # ← correct attribute name for azurerm 4.x

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.cosmosdb_location
    failover_priority = 0
  }

  tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Cosmos DB database
resource "azurerm_cosmosdb_sql_database" "finlink" {
  name                = "finlink"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.finlink.name
}

# notifications container — partition key /user_id
resource "azurerm_cosmosdb_sql_container" "notifications" {
  name                = "notifications"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.finlink.name
  database_name       = azurerm_cosmosdb_sql_database.finlink.name
  partition_key_paths = ["/user_id"]

  throughput = 400   # minimum — stays well within free tier
}