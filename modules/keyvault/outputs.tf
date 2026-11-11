output "id" {
  description = "Resource ID of the Key Vault."
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "Name of the Key Vault."
  value       = azurerm_key_vault.this.name
}

output "vault_uri" {
  description = "URI of the Key Vault, for example https://kv-name.vault.azure.net/."
  value       = azurerm_key_vault.this.vault_uri
}

output "public_network_access_enabled" {
  description = "Whether the public endpoint of the vault is switched on."
  value       = azurerm_key_vault.this.public_network_access_enabled
}

output "firewall_default_action" {
  description = "What the vault firewall does with traffic that matches no rule."
  value       = azurerm_key_vault.this.network_acls[0].default_action
}

output "rbac_authorization_enabled" {
  description = "Whether access is managed with Azure RBAC."
  value       = azurerm_key_vault.this.rbac_authorization_enabled
}

output "purge_protection_enabled" {
  description = "Whether purge protection is on."
  value       = azurerm_key_vault.this.purge_protection_enabled
}
