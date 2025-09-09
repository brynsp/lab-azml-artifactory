# ML VNet
resource "azurerm_virtual_network" "ml_vnet" {
  name                = "${var.name_prefix}-ml-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.ml_vnet_address_space
  tags                = var.tags
}

# ML VNet Subnets
resource "azurerm_subnet" "ml_subnets" {
  for_each = var.ml_subnets

  name                 = "${var.name_prefix}-ml-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.ml_vnet.name
  address_prefixes     = each.value.address_prefixes

  # Disable private endpoint network policies on pe subnet
  private_endpoint_network_policies = endswith(each.key, "pe_subnet") ? "Disabled" : "Enabled"

}

# Compute VNet
resource "azurerm_virtual_network" "compute_vnet" {
  name                = "${var.name_prefix}-compute-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.compute_vnet_address_space
  tags                = var.tags
}

# Compute VNet Subnets
resource "azurerm_subnet" "compute_subnets" {
  for_each = var.compute_subnets

  name                 = each.key == "bastion_subnet" ? "AzureBastionSubnet" : "${var.name_prefix}-compute-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.compute_vnet.name
  address_prefixes     = each.value.address_prefixes

  # Disable private endpoint network policies on pe subnet
  private_endpoint_network_policies = endswith(each.key, "pe_subnet") ? "Disabled" : "Enabled"
}

# VNet Peering: ML to Compute
resource "azurerm_virtual_network_peering" "ml_to_compute" {
  name                      = "${var.name_prefix}-ml-to-compute"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.ml_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.compute_vnet.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}

# VNet Peering: Compute to ML
resource "azurerm_virtual_network_peering" "compute_to_ml" {
  name                      = "${var.name_prefix}-compute-to-ml"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.compute_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.ml_vnet.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}

# Private DNS Zones
resource "azurerm_private_dns_zone" "private_dns_zones" {
  for_each = toset(var.private_dns_zones)

  name                = each.value
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link Private DNS Zones to ML VNet
resource "azurerm_private_dns_zone_virtual_network_link" "ml_vnet_links" {
  for_each = toset(var.private_dns_zones)

  name                  = "${var.name_prefix}-ml-vnet-link-${replace(each.value, ".", "-")}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zones[each.value].name
  virtual_network_id    = azurerm_virtual_network.ml_vnet.id
  registration_enabled  = false
  tags                  = var.tags
}

# Link Private DNS Zones to Compute VNet
resource "azurerm_private_dns_zone_virtual_network_link" "compute_vnet_links" {
  for_each = toset(var.private_dns_zones)

  name                  = "${var.name_prefix}-compute-vnet-link-${replace(each.value, ".", "-")}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zones[each.value].name
  virtual_network_id    = azurerm_virtual_network.compute_vnet.id
  registration_enabled  = false
  tags                  = var.tags
}
