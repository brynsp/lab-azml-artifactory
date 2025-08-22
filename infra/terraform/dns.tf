resource "azurerm_private_dns_zone" "pdz_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pdz_blob_ml" {
  name                  = "blob-link-ml"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.pdz_blob.name
  virtual_network_id    = azurerm_virtual_network.vnet_ml.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone" "pdz_file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pdz_file_ml" {
  name                  = "file-link-ml"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.pdz_file.name
  virtual_network_id    = azurerm_virtual_network.vnet_ml.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "pdz_file_arti" {
  name                  = "file-link-arti"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.pdz_file.name
  virtual_network_id    = azurerm_virtual_network.vnet_arti.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone" "pdz_dfs" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pdz_dfs_ml" {
  name                  = "dfs-link-ml"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.pdz_dfs.name
  virtual_network_id    = azurerm_virtual_network.vnet_ml.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone" "pdz_kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pdz_kv_ml" {
  name                  = "kv-link-ml"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.pdz_kv.name
  virtual_network_id    = azurerm_virtual_network.vnet_ml.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone" "pdz_aml_api" {
  name                = "privatelink.api.azureml.ms"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pdz_aml_api_ml" {
  name                  = "amlapi-link-ml"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.pdz_aml_api.name
  virtual_network_id    = azurerm_virtual_network.vnet_ml.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone" "pdz_aml_nb" {
  name                = "privatelink.notebooks.azure.net"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pdz_aml_nb_ml" {
  name                  = "amlnb-link-ml"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.pdz_aml_nb.name
  virtual_network_id    = azurerm_virtual_network.vnet_ml.id
  registration_enabled  = false
}
