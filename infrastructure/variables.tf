variable "subscription_id" {
  description = "Your Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure region for all resources"
  default     = "eastasia"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "finlink-rg"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "finlink"
}


variable "acr_name" {
  description = "Azure Container Registry name (must be globally unique, alphanumeric only)"
  type        = string
  default     = "finlinkacr"
}

variable "postgresql_admin_username" {
  description = "PostgreSQL administrator username"
  type        = string
  default     = "finlinkadmin"
}

variable "postgresql_admin_password" {
  description = "PostgreSQL administrator password"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "JWT secret key — must be identical across all 6 services"
  type        = string
  sensitive   = true
}

variable "cosmosdb_account_name" {
  description = "Cosmos DB account name (must be globally unique)"
  type        = string
  default     = "finlink-cosmos-dev"
}

variable "cosmosdb_location" {
  description = "Region for Cosmos DB — may differ from main location due to capacity"
  type        = string
  default     = "Southeast Asia"
}

variable "apim_publisher_email" {
  description = "Email for APIM publisher — use your email"
  type        = string
  default     = "your-email@example.com"
}