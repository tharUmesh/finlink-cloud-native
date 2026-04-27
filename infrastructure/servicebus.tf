resource "azurerm_servicebus_namespace" "finlink" {
  name                = "${var.project_name}-sb-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Main queue — transaction-service publishes here with subject filtering
# fraud-service and notification-service will consume from here
resource "azurerm_servicebus_queue" "transactions" {
  name         = "transactions"
  namespace_id = azurerm_servicebus_namespace.finlink.id
}

# Separate queue for loan events
resource "azurerm_servicebus_queue" "loan_events" {
  name         = "loan-events"
  namespace_id = azurerm_servicebus_namespace.finlink.id
}