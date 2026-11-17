locals {
  # Subnets are calculated from the VNet range, so changing the address space
  # never leads to overlapping or hand-typed subnets.
  app_subnet_cidr = cidrsubnet(var.address_space, 8, 1) # e.g. 10.10.1.0/24
  pe_subnet_cidr  = cidrsubnet(var.address_space, 8, 2) # e.g. 10.10.2.0/24
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.address_space]
  tags                = var.tags
}

# Subnet the web app uses for its OUTBOUND traffic (VNet integration).
resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.app_subnet_cidr]

  delegation {
    name = "app-service"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# The app subnet only carries traffic that LEAVES the web app. Nothing should
# ever connect into it, so all inbound traffic is denied.
resource "azurerm_network_security_group" "app" {
  name                = "nsg-app-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

# Subnet that holds the private endpoints (the private "front door" of PaaS services).
resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.pe_subnet_cidr]

  # Needed so the NSG rules below also apply to private endpoints.
  private_endpoint_network_policies = "Enabled"
}

resource "azurerm_network_security_group" "private_endpoints" {
  name                = "nsg-private-endpoints-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Only the app subnet may reach the private endpoints, and only over HTTPS.
  security_rule {
    name                       = "allow-app-subnet-https"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = local.app_subnet_cidr
    source_port_range          = "*"
    destination_address_prefix = local.pe_subnet_cidr
    destination_port_range     = "443"
  }

  # Everything else from inside the VNet is blocked (default would allow it).
  security_rule {
    name                       = "deny-all-other-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoints.id
}
