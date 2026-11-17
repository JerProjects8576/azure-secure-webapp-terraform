variable "name" {
  description = "Globally unique Key Vault name (3-24 characters)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.name))
    error_message = "Key Vault name must be 3-24 characters: letters, digits and hyphens."
  }
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy into."
  type        = string
}

variable "virtual_network_id" {
  description = "VNet that must be able to resolve the private endpoint."
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "Subnet the private endpoint is placed in."
  type        = string
}

variable "allowed_ips" {
  description = "Public IPs allowed through the firewall. Empty = private access only."
  type        = list(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "Workspace that receives the audit logs."
  type        = string
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}
