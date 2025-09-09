terraform {
  required_providers {
    azapi = {
      source = "azure/azapi"
    }
  }
}

# Generate a unique name for Storage Account (globally unique)
resource "random_string" "storage_suffix" {
  # Shorter suffix to keep storage account name within 24 char global limit
  length  = 6
  special = false
  upper   = false
}

data "azurerm_client_config" "current" {}

# Create Storage Account directly via AzAPI with shared key access disabled at creation
resource "azapi_resource" "storage" {
  type      = "Microsoft.Storage/storageAccounts@2023-01-01"
  name      = "${substr(replace(var.name_prefix, "-", ""), 0, 14)}st${random_string.storage_suffix.result}"
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  location  = var.location
  tags      = var.tags
  body = {
    kind = "StorageV2"
    sku = {
      name = "Standard_LRS"
    }
    properties = {
      allowSharedKeyAccess = false
      minimumTlsVersion    = "TLS1_2"
      publicNetworkAccess  = "Disabled"
    }
  }
}

# Private Endpoint for Blob storage
resource "azurerm_private_endpoint" "blob_pe" {
  name                = "${var.name_prefix}-st-blob-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name_prefix}-st-blob-psc"
    private_connection_resource_id = azapi_resource.storage.id
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
    private_connection_resource_id = azapi_resource.storage.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.file_dns_zone_id]
  }

  tags = var.tags
}
