output "resource_group_name" {
  description = "Resource group that contains everything."
  value       = azurerm_resource_group.this.name
}

output "web_app_url" {
  description = "Public HTTPS address of the web app."
  value       = "https://${module.webapp.default_hostname}"
}

output "key_vault_name" {
  description = "Name of the Key Vault (needed to set the secret)."
  value       = module.keyvault.name
}

output "set_secret_command" {
  description = "Command to store the secret after deployment."
  value       = "az keyvault secret set --vault-name ${module.keyvault.name} --name ${var.secret_name} --value <your-value>"
}
