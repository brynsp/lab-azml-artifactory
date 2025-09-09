# Get current client configuration
data "azurerm_client_config" "current" {}

# Generate a unique name for Key Vault (globally unique)
resource "random_string" "key_vault_suffix" {
  length  = 6
  special = false
  upper   = false
}

# Key Vault
resource "azurerm_key_vault" "main" {
  # Ensure name <= 24 chars: (up to 12 from prefix) + '-kv-' (4) + 6 rand = max 22
  name                = "${substr(var.name_prefix, 0, 12)}-kv-${random_string.key_vault_suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  # Disable public network access
  public_network_access_enabled = false

  # Access policy for current user/service principal
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Create", "Delete", "Update", "Purge", "Recover"
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge", "Recover"
    ]

    certificate_permissions = [
      "Get", "List", "Create", "Delete", "Update", "Purge", "Recover"
    ]
  }

  tags = var.tags
}

# Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "key_vault_pe" {
  name                = "${var.name_prefix}-kv-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name_prefix}-kv-psc"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }

  tags = var.tags
}

// Placeholder secret creation removed: with public access disabled and policy enforcement,
// Terraform cannot set a secret until access via private endpoint is available from the runner.
// Provide the PAT manually or via a separate, network-integrated pipeline once PE DNS resolves locally.
