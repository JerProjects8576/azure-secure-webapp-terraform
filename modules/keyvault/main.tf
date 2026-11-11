data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  #checkov:skip=CKV_AZURE_189:Public endpoint is off by default and only opens for explicitly allow-listed IPs
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  tags                = var.tags

  # Access is managed with Azure RBAC (role assignments) instead of the older
  # access policies: one permission model for everything in Azure.
  rbac_authorization_enabled = true

  # Deleted secrets can be recovered, and nobody can skip that safety net.
  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  # Firewall: block everything by default. The public endpoint is only switched
  # on when specific IPs are explicitly allowed (for example to set the secret).
  public_network_access_enabled = length(var.allowed_ips) > 0

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = var.allowed_ips
  }
}

# Private DNS zone: makes the normal vault hostname resolve to the PRIVATE IP
# for everything inside the VNet.
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "link-${var.name}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = var.virtual_network_id
  tags                  = var.tags
}

# Private endpoint: gives the Key Vault a network card with a private IP in our VNet.
resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.name}"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.keyvault]
}

# Audit trail: every read/write on the vault is logged.
resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "diag-to-log-analytics"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
