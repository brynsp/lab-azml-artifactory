module "pe_kv" {
  source  = "Azure/avm-res-network-privateendpoint/azurerm"
  version = ">= 0.1.0"

  name                            = "pe-kv"
  location                        = var.location
  resource_group_name             = var.rg_name
  subnet_resource_id              = azurerm_subnet.snet_ml_pe.id
  network_interface_name          = "nic-pe-kv"
  private_connection_resource_id  = module.kv.resource_id
  private_service_connection_name = "pe-kv-conn"
  subresource_names               = ["vault"]
  private_dns_zone_resource_ids   = [azurerm_private_dns_zone.pdz_kv.id]
  private_dns_zone_group_name     = "pe-kv-dzg"
  enable_telemetry                = false
}

module "pe_stml_blob" {
  source  = "Azure/avm-res-network-privateendpoint/azurerm"
  version = ">= 0.1.0"

  name                            = "pe-stml-blob"
  location                        = var.location
  resource_group_name             = var.rg_name
  subnet_resource_id              = azurerm_subnet.snet_ml_pe.id
  network_interface_name          = "nic-pe-stml-blob"
  private_connection_resource_id  = module.st_ml.resource_id
  private_service_connection_name = "pe-stml-blob-conn"
  subresource_names               = ["blob"]
  private_dns_zone_resource_ids   = [azurerm_private_dns_zone.pdz_blob.id]
  private_dns_zone_group_name     = "pe-stml-blob-dzg"
  enable_telemetry                = false
}

module "pe_stml_file" {
  source  = "Azure/avm-res-network-privateendpoint/azurerm"
  version = ">= 0.1.0"

  name                            = "pe-stml-file"
  location                        = var.location
  resource_group_name             = var.rg_name
  subnet_resource_id              = azurerm_subnet.snet_ml_pe.id
  network_interface_name          = "nic-pe-stml-file"
  private_connection_resource_id  = module.st_ml.resource_id
  private_service_connection_name = "pe-stml-file-conn"
  subresource_names               = ["file"]
  private_dns_zone_resource_ids   = [azurerm_private_dns_zone.pdz_file.id]
  private_dns_zone_group_name     = "pe-stml-file-dzg"
  enable_telemetry                = false
}

module "pe_adls_dfs" {
  source  = "Azure/avm-res-network-privateendpoint/azurerm"
  version = ">= 0.1.0"

  name                            = "pe-adls-dfs"
  location                        = var.location
  resource_group_name             = var.rg_name
  subnet_resource_id              = azurerm_subnet.snet_ml_pe.id
  network_interface_name          = "nic-pe-adls-dfs"
  private_connection_resource_id  = module.st_adls.resource_id
  private_service_connection_name = "pe-adls-dfs-conn"
  subresource_names               = ["dfs"]
  private_dns_zone_resource_ids   = [azurerm_private_dns_zone.pdz_dfs.id]
  private_dns_zone_group_name     = "pe-adls-dfs-dzg"
  enable_telemetry                = false
}

module "pe_adls_blob" {
  source  = "Azure/avm-res-network-privateendpoint/azurerm"
  version = ">= 0.1.0"

  name                            = "pe-adls-blob"
  location                        = var.location
  resource_group_name             = var.rg_name
  subnet_resource_id              = azurerm_subnet.snet_ml_pe.id
  network_interface_name          = "nic-pe-adls-blob"
  private_connection_resource_id  = module.st_adls.resource_id
  private_service_connection_name = "pe-adls-blob-conn"
  subresource_names               = ["blob"]
  private_dns_zone_resource_ids   = [azurerm_private_dns_zone.pdz_blob.id]
  private_dns_zone_group_name     = "pe-adls-blob-dzg"
  enable_telemetry                = false
}

module "pe_starti_file" {
  source  = "Azure/avm-res-network-privateendpoint/azurerm"
  version = ">= 0.1.0"

  name                            = "pe-starti-file"
  location                        = var.location
  resource_group_name             = var.rg_name
  subnet_resource_id              = azurerm_subnet.snet_arti_pe.id
  network_interface_name          = "nic-pe-starti-file"
  private_connection_resource_id  = module.st_arti.resource_id
  private_service_connection_name = "pe-starti-file-conn"
  subresource_names               = ["file"]
  private_dns_zone_resource_ids   = [azurerm_private_dns_zone.pdz_file.id]
  private_dns_zone_group_name     = "pe-starti-file-dzg"
  enable_telemetry                = false
}
