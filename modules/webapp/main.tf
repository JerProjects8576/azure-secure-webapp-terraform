resource "azurerm_service_plan" "this" {
  # Accepted for a lab: a single small instance keeps the cost at a few euros.
  # A production plan would use a Premium SKU with 2+ zone-redundant instances.
  #checkov:skip=CKV_AZURE_211:Lab environment uses the smallest SKU that supports VNet integration
  #checkov:skip=CKV_AZURE_212:Single instance is a deliberate cost choice for a lab
  #checkov:skip=CKV_AZURE_225:Zone redundancy requires a Premium SKU
  name                = var.plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_linux_web_app" "this" {
  # This is a public website by design, so visitors do not log in or present
  # a client certificate.
  #checkov:skip=CKV_AZURE_222:Public website - inbound internet access is the purpose
  #checkov:skip=CKV_AZURE_13:Public website without user accounts
  #checkov:skip=CKV_AZURE_17:Client certificates do not apply to a public website
  #checkov:skip=CKV_AZURE_88:Stateless container - no persistent file share needed
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.this.id
  tags                = var.tags

  https_only = true

  # Outbound traffic of the app goes through our VNet, so it can reach the
  # Key Vault on its private IP.
  virtual_network_subnet_id = var.integration_subnet_id

  # Managed identity: Azure gives the app its own identity, so there is no
  # password or connection string to store, leak or rotate.
  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on              = true
    http2_enabled          = true
    minimum_tls_version    = "1.2"
    ftps_state             = "Disabled"
    vnet_route_all_enabled = true

    # Azure pings this path and restarts the app when it stops answering.
    health_check_path                 = "/"
    health_check_eviction_time_in_min = 5

    application_stack {
      docker_image_name   = var.container_image
      docker_registry_url = var.container_registry_url
    }
  }

  logs {
    detailed_error_messages = true
    failed_request_tracing  = true

    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }

  app_settings = {
    # Key Vault reference: the app gets the secret as a normal environment
    # variable, but the value itself lives only in the Key Vault - never in
    # this code, the Terraform state or the Git history.
    APP_SECRET = "@Microsoft.KeyVault(SecretUri=${var.key_vault_uri}secrets/${var.secret_name}/)"

    APPLICATIONINSIGHTS_CONNECTION_STRING = var.app_insights_connection
    WEBSITES_ENABLE_APP_SERVICE_STORAGE   = "false"
  }
}

# Ship the web server and container logs to Log Analytics.
resource "azurerm_monitor_diagnostic_setting" "webapp" {
  name                       = "diag-to-log-analytics"
  target_resource_id         = azurerm_linux_web_app.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_log {
    category = "AppServicePlatformLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
