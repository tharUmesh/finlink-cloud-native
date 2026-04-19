variable "subscription_id" {
  description = "Your Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure region for all resources"
  default = "eastasia"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default = "finlink-rg"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default = "dev"
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "finlink"
}