resource "random_string" "suffix" {
  length  = 5
  lower   = true
  numeric = true
  upper   = false
  special = false
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_suffix}"
  location = var.location
  tags     = local.tags
}

# 1. Network: one VNet with a subnet for the app and a subnet for private endpoints.
module "network" {
  source = "./modules/network"

  name_suffix         = local.name_suffix
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.vnet_address_space
  tags                = local.tags
}

# 2. Monitoring: central place where logs and metrics end up.
module "monitoring" {
  source = "./modules/monitoring"

  name_suffix         = local.name_suffix
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  retention_days      = var.log_retention_days
  tags                = local.tags
}

# 3. Key Vault: stores the secret, only reachable through a private endpoint.
module "keyvault" {
  source = "./modules/keyvault"

  name                       = "kv-${local.name_suffix}-${local.unique_suffix}"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  virtual_network_id         = module.network.vnet_id
  private_endpoint_subnet_id = module.network.private_endpoint_subnet_id
  allowed_ips                = var.key_vault_allowed_ips
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = local.tags
}

# 4. Web app: runs the container, talks to the Key Vault over the VNet.
module "webapp" {
  source = "./modules/webapp"

  name                       = "app-${local.name_suffix}-${local.unique_suffix}"
  plan_name                  = "asp-${local.name_suffix}"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  sku_name                   = var.app_service_sku
  integration_subnet_id      = module.network.app_subnet_id
  container_image            = var.container_image
  container_registry_url     = var.container_registry_url
  key_vault_uri              = module.keyvault.vault_uri
  secret_name                = var.secret_name
  app_insights_connection    = module.monitoring.app_insights_connection_string
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = local.tags
}

# 5. Access: the web app's managed identity may only READ secrets (least privilege).
#    Lives in the root module because it connects two modules to each other.
resource "azurerm_role_assignment" "webapp_reads_secrets" {
  scope                = module.keyvault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.webapp.principal_id
}

# Optional: people or groups that may create and rotate secrets.
resource "azurerm_role_assignment" "secret_admins" {
  for_each = toset(var.key_vault_admin_object_ids)

  scope                = module.keyvault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = each.value
}
