output "id" {
  description = "Resource ID of the web app."
  value       = azurerm_linux_web_app.this.id
}

output "default_hostname" {
  description = "Default hostname of the web app."
  value       = azurerm_linux_web_app.this.default_hostname
}

output "principal_id" {
  description = "Object ID of the web app's managed identity."
  value       = azurerm_linux_web_app.this.identity[0].principal_id
}

output "https_only" {
  description = "Whether the web app only accepts HTTPS."
  value       = azurerm_linux_web_app.this.https_only
}

output "minimum_tls_version" {
  description = "Lowest TLS version the web app accepts."
  value       = azurerm_linux_web_app.this.site_config[0].minimum_tls_version
}

output "ftps_state" {
  description = "FTP/FTPS deployment state."
  value       = azurerm_linux_web_app.this.site_config[0].ftps_state
}

output "identity_type" {
  description = "Type of managed identity on the web app."
  value       = azurerm_linux_web_app.this.identity[0].type
}
