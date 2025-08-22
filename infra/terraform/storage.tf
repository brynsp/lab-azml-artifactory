module "st_ml" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = ">= 0.1.0"

  name                = local.st_ml
  resource_group_name = var.rg_name
  location            = var.location

  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false
  enable_telemetry                = false
  # Avoid data-plane queue property calls when AAD-only is enforced
  queue_properties = {}
  depends_on       = [module.rg]
}

module "st_adls" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = ">= 0.1.0"

  name                = local.st_adls
  resource_group_name = var.rg_name
  location            = var.location

  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  is_hns_enabled                  = true
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false
  enable_telemetry                = false
  queue_properties                = {}
  depends_on                      = [module.rg]
}

module "st_arti" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = ">= 0.1.0"

  name                = local.st_arti
  resource_group_name = var.rg_name
  location            = var.location

  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false
  enable_telemetry                = false
  # Required for ACI to mount Azure Files (uses storage account key)
  shared_access_key_enabled = true
  # Ensure key-based auth is permitted for this account (not OAuth-only)
  default_to_oauth_authentication = false
  queue_properties                = {}
  depends_on                      = [module.rg]
}

resource "azurerm_storage_share" "arti" {
  name               = var.arti_share
  storage_account_id = module.st_arti.resource_id
  quota              = 100
  enabled_protocol   = "SMB"
}
