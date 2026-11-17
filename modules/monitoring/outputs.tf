output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "app_insights_connection_string" {
  description = "Connection string the app uses to send telemetry."
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}
