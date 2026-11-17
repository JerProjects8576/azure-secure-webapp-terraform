variable "name" {
  description = "Globally unique name of the web app."
  type        = string
}

variable "plan_name" {
  description = "Name of the App Service plan."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy into."
  type        = string
}

variable "sku_name" {
  description = "App Service plan SKU."
  type        = string
  default     = "B1"
}

variable "integration_subnet_id" {
  description = "Subnet used for outbound VNet integration."
  type        = string
}

variable "container_image" {
  description = "Container image (path without registry host)."
  type        = string
}

variable "container_registry_url" {
  description = "Registry URL the image is pulled from."
  type        = string
}

variable "key_vault_uri" {
  description = "URI of the Key Vault that holds the secret."
  type        = string
}

variable "secret_name" {
  description = "Name of the secret to expose to the app."
  type        = string
}

variable "app_insights_connection" {
  description = "Application Insights connection string."
  type        = string
  sensitive   = true
}

variable "log_analytics_workspace_id" {
  description = "Workspace that receives the web app logs."
  type        = string
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}
