# Generate a unique name for ACR (globally unique)
resource "random_string" "acr_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = "${replace(var.name_prefix, "-", "")}acr${random_string.acr_suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  
  sku = "Premium"  # Required for private endpoints
  
  # Disable public access
  public_network_access_enabled = false
  
  # Security settings
  admin_enabled = false
  
  tags = var.tags
}

# Private Endpoint for ACR
resource "azurerm_private_endpoint" "acr_pe" {
  name                = "${var.name_prefix}-acr-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name_prefix}-acr-psc"
    private_connection_resource_id = azurerm_container_registry.main.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }

  tags = var.tags
}