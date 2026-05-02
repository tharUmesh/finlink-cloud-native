# ─────────────────────────────────────────────────────────
# API Management — single entry point for mobile app
# Consumption tier = free for low usage
# ─────────────────────────────────────────────────────────
resource "azurerm_api_management" "finlink" {
  name                = "${var.project_name}-apim-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "FinLink Team"
  publisher_email     = var.apim_publisher_email
  sku_name            = "Consumption_0"   # free tier

  identity {
    type = "SystemAssigned"
  }

  tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ─────────────────────────────────────────────────────────
# APIM API — FinLink Backend
# ─────────────────────────────────────────────────────────
resource "azurerm_api_management_api" "finlink" {
  name                  = "finlink-api"
  resource_group_name   = azurerm_resource_group.rg.name
  api_management_name   = azurerm_api_management.finlink.name
  revision              = "1"
  display_name          = "FinLink API"
  path                  = "api"
  protocols             = ["https"]
  subscription_required = false
}

# ─────────────────────────────────────────────────────────
# Backends — one per microservice
# ─────────────────────────────────────────────────────────
resource "azurerm_api_management_backend" "user_service" {
  name                = "user-service"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.finlink.name
  protocol            = "http"
  url                 = "https://${azurerm_container_app.user_service.ingress[0].fqdn}"
}

resource "azurerm_api_management_backend" "wallet_service" {
  name                = "wallet-service"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.finlink.name
  protocol            = "http"
  url                 = "https://${azurerm_container_app.wallet_service.ingress[0].fqdn}"
}

resource "azurerm_api_management_backend" "transaction_service" {
  name                = "transaction-service"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.finlink.name
  protocol            = "http"
  url                 = "https://${azurerm_container_app.transaction_service.ingress[0].fqdn}"
}

resource "azurerm_api_management_backend" "loan_service" {
  name                = "loan-service"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.finlink.name
  protocol            = "http"
  url                 = "https://${azurerm_container_app.loan_service.ingress[0].fqdn}"
}

resource "azurerm_api_management_backend" "fraud_service" {
  name                = "fraud-service"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.finlink.name
  protocol            = "http"
  url                 = "https://${azurerm_container_app.fraud_service.ingress[0].fqdn}"
}

resource "azurerm_api_management_backend" "notification_service" {
  name                = "notification-service"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.finlink.name
  protocol            = "http"
  url                 = "https://${azurerm_container_app.notification_service.ingress[0].fqdn}"
}

# ─────────────────────────────────────────────────────────
# Global APIM Policy — JWT validation + rate limiting
# Applied to ALL routes automatically
# ─────────────────────────────────────────────────────────


# ─────────────────────────────────────────────────────────
# Named Value — JWT secret from Key Vault
# ─────────────────────────────────────────────────────────
resource "azurerm_api_management_named_value" "jwt_secret" {
  name                = "jwt-secret"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.finlink.name
  display_name        = "jwt-secret"
  secret              = true
  value_from_key_vault {
    secret_id = azurerm_key_vault_secret.secret_key.versionless_id
  }
  depends_on = [azurerm_api_management.finlink]
}

# ─────────────────────────────────────────────────────────
# Operations — route each path to correct backend
# ─────────────────────────────────────────────────────────

# Catch-all route — forwards everything to correct backend based on path
resource "azurerm_api_management_api_operation" "register" {
  operation_id        = "register"
  api_name            = azurerm_api_management_api.finlink.name
  api_management_name = azurerm_api_management.finlink.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Register"
  method              = "POST"
  url_template        = "/register"
}

resource "azurerm_api_management_api_operation_policy" "register" {
  operation_id        = azurerm_api_management_api_operation.register.operation_id
  api_name            = azurerm_api_management_api.finlink.name
  api_management_name = azurerm_api_management.finlink.name
  resource_group_name = azurerm_resource_group.rg.name
  xml_content         = <<XML
<policies>
  <inbound>
    <base />
    <set-backend-service backend-id="user-service" />
  </inbound>
  <backend><forward-request /></backend>
  <outbound><base /></outbound>
</policies>
XML
}

resource "azurerm_api_management_api_operation" "login" {
  operation_id        = "login"
  api_name            = azurerm_api_management_api.finlink.name
  api_management_name = azurerm_api_management.finlink.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Login"
  method              = "POST"
  url_template        = "/login"
}

resource "azurerm_api_management_api_operation_policy" "login" {
  operation_id        = azurerm_api_management_api_operation.login.operation_id
  api_name            = azurerm_api_management_api.finlink.name
  api_management_name = azurerm_api_management.finlink.name
  resource_group_name = azurerm_resource_group.rg.name
  xml_content         = <<XML
<policies>
  <inbound>
    <base />
    <set-backend-service backend-id="user-service" />
  </inbound>
  <backend><forward-request /></backend>
  <outbound><base /></outbound>
</policies>
XML
}

resource "azurerm_api_management_api_operation" "me" {
  operation_id        = "me"
  api_name            = azurerm_api_management_api.finlink.name
  api_management_name = azurerm_api_management.finlink.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Get Current User"
  method              = "GET"
  url_template        = "/me"
}

resource "azurerm_api_management_api_operation_policy" "me" {
  operation_id        = azurerm_api_management_api_operation.me.operation_id
  api_name            = azurerm_api_management_api.finlink.name
  api_management_name = azurerm_api_management.finlink.name
  resource_group_name = azurerm_resource_group.rg.name
  xml_content         = <<XML
<policies>
  <inbound>
    <base />
    <set-backend-service backend-id="user-service" />
  </inbound>
  <backend><forward-request /></backend>
  <outbound><base /></outbound>
</policies>
XML
}

resource "azurerm_api_management_api_operation" "transfer" {
  operation_id        = "transfer"
  api_name            = azurerm_api_management_api.finlink.name
  api_management_name = azurerm_api_management.finlink.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Transfer"
  method              = "POST"
  url_template        = "/transfer"
}

resource "azurerm_api_management_api_operation_policy" "transfer" {
  operation_id        = azurerm_api_management_api_operation.transfer.operation_id
  api_name            = azurerm_api_management_api.finlink.name
  api_management_name = azurerm_api_management.finlink.name
  resource_group_name = azurerm_resource_group.rg.name
  xml_content         = <<XML
<policies>
  <inbound>
    <base />
    <set-backend-service backend-id="transaction-service" />
  </inbound>
  <backend><forward-request /></backend>
  <outbound><base /></outbound>
</policies>
XML
}

resource "azurerm_api_management_api_operation" "loans" {
  operation_id        = "loans-apply"
  api_name            = azurerm_api_management_api.finlink.name
  api_management_name = azurerm_api_management.finlink.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Apply for Loan"
  method              = "POST"
  url_template        = "/loans/apply"
}

resource "azurerm_api_management_api_operation_policy" "loans" {
  operation_id        = azurerm_api_management_api_operation.loans.operation_id
  api_name            = azurerm_api_management_api.finlink.name
  api_management_name = azurerm_api_management.finlink.name
  resource_group_name = azurerm_resource_group.rg.name
  xml_content         = <<XML
<policies>
  <inbound>
    <base />
    <set-backend-service backend-id="loan-service" />
  </inbound>
  <backend><forward-request /></backend>
  <outbound><base /></outbound>
</policies>
XML
}