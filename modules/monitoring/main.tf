# One workspace where all logs come together, so you can query them in one place.
resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_days
  tags                = var.tags
}

# Application performance monitoring (requests, failures, response times).
resource "azurerm_application_insights" "this" {
  name                = "appi-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  tags                = var.tags
}
