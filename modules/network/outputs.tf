output "vnet_id" {
  description = "ID of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "app_subnet_id" {
  description = "ID of the subnet used for App Service VNet integration."
  # Read through the association so the NSG is attached before the app joins.
  value = azurerm_subnet_network_security_group_association.app.subnet_id
}

output "private_endpoint_subnet_id" {
  description = "ID of the subnet that holds private endpoints."
  # Read through the association so the NSG is always attached before a
  # private endpoint is placed in the subnet.
  value = azurerm_subnet_network_security_group_association.private_endpoints.subnet_id
}

output "app_subnet_cidr" {
  description = "Address range of the app subnet."
  value       = local.app_subnet_cidr
}

output "private_endpoint_subnet_cidr" {
  description = "Address range of the private endpoint subnet."
  value       = local.pe_subnet_cidr
}
