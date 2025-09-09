# Generate a unique name for Storage Account (globally unique)
resource "random_string" "storage_suffix" {
  # Shorter suffix to keep storage account name within 24 char global limit
  length  = 6
  special = false
  upper   = false
}

# Storage Account
resource "azurerm_storage_account" "main" {
  # Storage account must be 3-24 chars, only lowercase letters & numbers
  # Use first 14 chars of cleaned prefix + 'st' + 6 rand => max 22
  name                = "${substr(replace(var.name_prefix, "-", ""), 0, 14)}st${random_string.storage_suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind            = "StorageV2"
  
  # Disable public access
  public_network_access_enabled = false
  
  # Security settings
  min_tls_version                = "TLS1_2"
  allow_nested_items_to_be_public = false
  
  tags = var.tags
}

# Private Endpoint for Blob storage
resource "azurerm_private_endpoint" "blob_pe" {
  name                = "${var.name_prefix}-st-blob-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name_prefix}-st-blob-psc"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.blob_dns_zone_id]
  }

  tags = var.tags
}

# Private Endpoint for File storage
resource "azurerm_private_endpoint" "file_pe" {
  name                = "${var.name_prefix}-st-file-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name_prefix}-st-file-psc"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.file_dns_zone_id]
  }

  tags = var.tags
}