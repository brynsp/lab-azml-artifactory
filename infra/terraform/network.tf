resource "azurerm_virtual_network" "vnet_ml" {
  name                = var.vnet_ml_name
  address_space       = [var.addr_ml]
  location            = var.location
  resource_group_name = var.rg_name
}

resource "azurerm_subnet" "snet_ml_pe" {
  name                              = var.snet_ml_pe
  resource_group_name               = var.rg_name
  virtual_network_name              = azurerm_virtual_network.vnet_ml.name
  address_prefixes                  = [var.pfx_ml_pe]
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_subnet" "snet_bastion" {
  name                 = var.snet_bastion
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet_ml.name
  address_prefixes     = [var.pfx_bastion]
}

resource "azurerm_subnet" "snet_jump" {
  name                 = var.snet_jump
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet_ml.name
  address_prefixes     = [var.pfx_jump]
}

resource "azurerm_virtual_network" "vnet_arti" {
  name                = var.vnet_arti_name
  address_space       = [var.addr_arti]
  location            = var.location
  resource_group_name = var.rg_name
}

resource "azurerm_subnet" "snet_arti_aci" {
  name                 = var.snet_arti_aci
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet_arti.name
  address_prefixes     = [var.pfx_arti_aci]
  delegation {
    name = "aci-delegation"
    service_delegation {
      name = "Microsoft.ContainerInstance/containerGroups"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
}

resource "azurerm_subnet" "snet_arti_pe" {
  name                              = var.snet_arti_pe
  resource_group_name               = var.rg_name
  virtual_network_name              = azurerm_virtual_network.vnet_arti.name
  address_prefixes                  = [var.pfx_arti_pe]
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_virtual_network_peering" "ml_to_arti" {
  name                         = "p-${var.vnet_ml_name}-to-${var.vnet_arti_name}"
  resource_group_name          = var.rg_name
  virtual_network_name         = azurerm_virtual_network.vnet_ml.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet_arti.id
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "arti_to_ml" {
  name                         = "p-${var.vnet_arti_name}-to-${var.vnet_ml_name}"
  resource_group_name          = var.rg_name
  virtual_network_name         = azurerm_virtual_network.vnet_arti.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet_ml.id
  allow_virtual_network_access = true
}

// NAT Gateway (with module-managed Public IP)

module "ngw" {
  source  = "Azure/avm-res-network-natgateway/azurerm"
  version = ">= 0.1.0"

  name                = local.ngw_name
  location            = var.location
  resource_group_name = var.rg_name
  sku_name            = "Standard"
  public_ips = {
    ip1 = { name = local.pip_nat }
  }
  public_ip_configuration = {
    allocation_method = "Static"
    sku               = "Standard"
    zones             = ["1", "2", "3"]
  }
  enable_telemetry = false
}

resource "azurerm_subnet_nat_gateway_association" "ngw_assoc" {
  subnet_id      = azurerm_subnet.snet_arti_aci.id
  nat_gateway_id = module.ngw.resource_id
}

// Bastion Host (module can create its own Public IP)
module "bastion" {
  source  = "Azure/avm-res-network-bastionhost/azurerm"
  version = ">= 0.1.0"

  name                = local.bastion
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "Basic"
  ip_configuration = {
    subnet_id              = azurerm_subnet.snet_bastion.id
    create_public_ip       = true
    public_ip_address_name = local.pip_bastion
  }
  enable_telemetry = false
}

resource "azurerm_network_interface" "nic_jump" {
  name                = "nic-${local.vm_jump}"
  location            = var.location
  resource_group_name = var.rg_name
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.snet_jump.id
    private_ip_address_allocation = "Dynamic"
  }
}
