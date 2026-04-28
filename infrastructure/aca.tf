# ─────────────────────────────────────────────────────────
# Log Analytics Workspace — collects logs from all services
# ─────────────────────────────────────────────────────────
resource "azurerm_log_analytics_workspace" "finlink" {
  name                = "${var.project_name}-logs-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ─────────────────────────────────────────────────────────
# Container Apps Environment — hosts all 6 microservices
# ─────────────────────────────────────────────────────────
resource "azurerm_container_app_environment" "finlink" {
  name                       = "${var.project_name}-aca-env-${var.environment}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.finlink.id

  lifecycle {
    ignore_changes = [workload_profile]   
  }

  tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}