variable "project" {
  description = "Short project name, used in every resource name."
  type        = string
  default     = "secweb"

  validation {
    condition     = can(regex("^[a-z0-9]{3,10}$", var.project))
    error_message = "project must be 3-10 lowercase letters or digits."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, prod."
  }
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "westeurope"
}

variable "vnet_address_space" {
  description = "Address space of the virtual network."
  type        = string
  default     = "10.10.0.0/16"

  validation {
    condition     = can(cidrhost(var.vnet_address_space, 0))
    error_message = "vnet_address_space must be a valid CIDR block, for example 10.10.0.0/16."
  }
}

variable "app_service_sku" {
  description = "App Service plan SKU. B1 is the smallest SKU that supports VNet integration."
  type        = string
  default     = "B1"
}

variable "container_image" {
  description = "Container image the web app runs (registry path without the host)."
  type        = string
  default     = "appsvc/staticsite:latest"
}

variable "container_registry_url" {
  description = "Registry the container image is pulled from."
  type        = string
  default     = "https://mcr.microsoft.com"
}

variable "secret_name" {
  description = "Name of the Key Vault secret the web app reads at runtime."
  type        = string
  default     = "app-secret"
}

variable "key_vault_allowed_ips" {
  description = "Public IP addresses allowed through the Key Vault firewall (for example your own IP, to set the secret). Empty means private access only."
  type        = list(string)
  default     = []
}

variable "key_vault_admin_object_ids" {
  description = "Entra ID object IDs (users or groups) that may manage secrets in the Key Vault."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "How long logs are kept in Log Analytics."
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "log_retention_days must be between 30 and 730."
  }
}

variable "extra_tags" {
  description = "Additional tags to put on every resource."
  type        = map(string)
  default     = {}
}
