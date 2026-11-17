# Plan-only tests that check the security baseline WITHOUT touching Azure.
# The provider is mocked, so these run in CI without any credentials.
#
#   terraform init -backend=false
#   terraform test

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "00000000-0000-0000-0000-000000000000"
      subscription_id = "00000000-0000-0000-0000-000000000000"
      object_id       = "00000000-0000-0000-0000-000000000000"
    }
  }

  # Realistic resource IDs, so the provider's own ID validation still passes
  # while nothing is created in Azure.
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock"
    }
  }

  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock"
    }
  }

  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock/subnets/snet-mock"
    }
  }

  mock_resource "azurerm_network_security_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/networkSecurityGroups/nsg-mock"
    }
  }

  mock_resource "azurerm_subnet_network_security_group_association" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock/subnets/snet-mock"
    }
  }

  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.OperationalInsights/workspaces/log-mock"
    }
  }

  mock_resource "azurerm_application_insights" {
    defaults = {
      id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Insights/components/appi-mock"
      connection_string = "InstrumentationKey=00000000-0000-0000-0000-000000000000"
    }
  }

  mock_resource "azurerm_key_vault" {
    defaults = {
      id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.KeyVault/vaults/kv-mock"
      vault_uri = "https://kv-mock.vault.azure.net/"
    }
  }

  mock_resource "azurerm_private_dns_zone" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
    }
  }

  mock_resource "azurerm_service_plan" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Web/serverFarms/asp-mock"
    }
  }

  mock_resource "azurerm_linux_web_app" {
    defaults = {
      id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Web/sites/app-mock"
      default_hostname = "app-mock.azurewebsites.net"
    }
  }
}

run "web_app_is_hardened" {
  command = plan

  assert {
    condition     = module.webapp.https_only == true
    error_message = "The web app must only accept HTTPS."
  }

  assert {
    condition     = module.webapp.minimum_tls_version == "1.2"
    error_message = "The web app must require TLS 1.2 or higher."
  }

  assert {
    condition     = module.webapp.ftps_state == "Disabled"
    error_message = "FTP deployments must be disabled."
  }

  assert {
    condition     = module.webapp.identity_type == "SystemAssigned"
    error_message = "The web app must use a managed identity."
  }
}

run "key_vault_is_private_by_default" {
  command = plan

  assert {
    condition     = module.keyvault.public_network_access_enabled == false
    error_message = "Without allowed IPs the Key Vault must not be reachable from the internet."
  }

  assert {
    condition     = module.keyvault.firewall_default_action == "Deny"
    error_message = "The Key Vault firewall must deny by default."
  }

  assert {
    condition     = module.keyvault.rbac_authorization_enabled == true
    error_message = "The Key Vault must use Azure RBAC."
  }

  assert {
    condition     = module.keyvault.purge_protection_enabled == true
    error_message = "Purge protection must be enabled."
  }
}

run "key_vault_opens_only_for_listed_ips" {
  command = plan

  variables {
    key_vault_allowed_ips = ["203.0.113.10"]
  }

  assert {
    condition     = module.keyvault.public_network_access_enabled == true
    error_message = "The public endpoint should be on when IPs are explicitly allowed."
  }

  assert {
    condition     = module.keyvault.firewall_default_action == "Deny"
    error_message = "Even with allowed IPs, everything else must still be denied."
  }
}

run "least_privilege_for_the_app" {
  command = plan

  assert {
    condition     = azurerm_role_assignment.webapp_reads_secrets.role_definition_name == "Key Vault Secrets User"
    error_message = "The web app may only read secrets, nothing more."
  }
}

run "subnets_are_derived_from_the_vnet_range" {
  command = plan

  variables {
    vnet_address_space = "10.50.0.0/16"
  }

  assert {
    condition     = module.network.app_subnet_cidr == "10.50.1.0/24"
    error_message = "App subnet should be the first /24 after the base range."
  }

  assert {
    condition     = module.network.private_endpoint_subnet_cidr == "10.50.2.0/24"
    error_message = "Private endpoint subnet should be the second /24 after the base range."
  }
}

run "rejects_unknown_environment" {
  command = plan

  variables {
    environment = "staging"
  }

  expect_failures = [var.environment]
}
