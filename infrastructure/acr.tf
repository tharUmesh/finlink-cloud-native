# ─────────────────────────────────────────────────────────
# Azure Container Registry — stores all Docker images
# ─────────────────────────────────────────────────────────
resource "azurerm_container_registry" "finlink" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false  # we use Managed Identity instead

  tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ─────────────────────────────────────────────────────────
# Managed Identity — lets ACA pull images from ACR securely
# No passwords needed!
# ─────────────────────────────────────────────────────────
resource "azurerm_user_assigned_identity" "aca_identity" {
  name                = "${var.project_name}-aca-identity-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# Give the identity permission to pull images from ACR
resource "azurerm_role_assignment" "aca_acr_pull" {
  scope                = azurerm_container_registry.finlink.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aca_identity.principal_id
}