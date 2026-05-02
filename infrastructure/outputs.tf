output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "aca_environment_name" {
  value = azurerm_container_app_environment.finlink.name
}

output "acr_login_server" {
  description = "Share with Person 2 — push Docker images here"
  value       = azurerm_container_registry.finlink.login_server
}

output "postgres_host" {
  description = "PostgreSQL server hostname"
  value       = azurerm_postgresql_flexible_server.finlink.fqdn
}

output "postgres_user_db_url" {
  description = "DATABASE_URL for user-service"
  value       = "postgresql://${var.postgresql_admin_username}:${local.pg_password_encoded}@${azurerm_postgresql_flexible_server.finlink.fqdn}:5432/finlink_users"
  sensitive   = true
}

output "postgres_wallet_db_url" {
  value     = "postgresql://${var.postgresql_admin_username}:${local.pg_password_encoded}@${azurerm_postgresql_flexible_server.finlink.fqdn}:5432/finlink_wallets"
  sensitive = true
}

output "postgres_transaction_db_url" {
  value     = "postgresql://${var.postgresql_admin_username}:${local.pg_password_encoded}@${azurerm_postgresql_flexible_server.finlink.fqdn}:5432/finlink_transactions"
  sensitive = true
}

output "postgres_loan_db_url" {
  value     = "postgresql://${var.postgresql_admin_username}:${local.pg_password_encoded}@${azurerm_postgresql_flexible_server.finlink.fqdn}:5432/finlink_loans"
  sensitive = true
}

output "postgres_fraud_db_url" {
  value     = "postgresql://${var.postgresql_admin_username}:${local.pg_password_encoded}@${azurerm_postgresql_flexible_server.finlink.fqdn}:5432/finlink_fraud"
  sensitive = true
}

output "postgres_notifications_db_url" {
  value     = "postgresql://${var.postgresql_admin_username}:${local.pg_password_encoded}@${azurerm_postgresql_flexible_server.finlink.fqdn}:5432/finlink_notifications"
  sensitive = true
}

output "cosmosdb_endpoint" {
  description = "COSMOS_ENDPOINT for notification-service"
  value       = azurerm_cosmosdb_account.finlink.endpoint
}

output "cosmosdb_primary_key" {
  description = "COSMOS_KEY for notification-service"
  value       = azurerm_cosmosdb_account.finlink.primary_key
  sensitive   = true
}

output "servicebus_namespace" {
  value = azurerm_servicebus_namespace.finlink.name
}

output "servicebus_queue_transactions" {
  value = azurerm_servicebus_queue.transactions.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.finlink.vault_uri
}

output "subscription_id" {
  value     = var.subscription_id
  sensitive = true
}

output "internal_fqdn_user_service" {
  value = "https://user-service.internal.${azurerm_container_app_environment.finlink.default_domain}"
}

output "internal_fqdn_wallet_service" {
  value = "https://wallet-service.internal.${azurerm_container_app_environment.finlink.default_domain}"
}

output "internal_fqdn_transaction_service" {
  value = "https://transaction-service.internal.${azurerm_container_app_environment.finlink.default_domain}"
}

output "internal_fqdn_loan_service" {
  value = "https://loan-service.internal.${azurerm_container_app_environment.finlink.default_domain}"
}

output "internal_fqdn_fraud_service" {
  value = "https://fraud-service.internal.${azurerm_container_app_environment.finlink.default_domain}"
}

output "internal_fqdn_notification_service" {
  value = "https://notification-service.internal.${azurerm_container_app_environment.finlink.default_domain}"
}

output "external_url_user_service" {
  value = "https://${azurerm_container_app.user_service.ingress[0].fqdn}"
}

output "external_url_transaction_service" {
  value = "https://${azurerm_container_app.transaction_service.ingress[0].fqdn}"
}

output "external_url_wallet_service" {
  value = "https://${azurerm_container_app.wallet_service.ingress[0].fqdn}"
}

output "external_url_loan_service" {
  value = "https://${azurerm_container_app.loan_service.ingress[0].fqdn}"
}

output "external_url_fraud_service" {
  value = "https://${azurerm_container_app.fraud_service.ingress[0].fqdn}"
}

output "external_url_notification_service" {
  value = "https://${azurerm_container_app.notification_service.ingress[0].fqdn}"
}

output "apim_gateway_url" {
  description = "Share with Person 1 — mobile app base URL"
  value       = "${azurerm_api_management.finlink.gateway_url}/api"
}