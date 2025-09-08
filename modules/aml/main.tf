# Azure Machine Learning Workspace
resource "azurerm_machine_learning_workspace" "main" {
  name                = "${var.name_prefix}-ml-workspace"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  key_vault_id                = var.key_vault_id
  storage_account_id          = var.storage_account_id
  container_registry_id       = var.container_registry_id
  
  # Disable public network access
  public_network_access_enabled = false
  
  # Minimal configuration - no Application Insights
  application_insights_id = null
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = var.tags
}

# Private Endpoint for ML Workspace API
resource "azurerm_private_endpoint" "ml_api_pe" {
  name                = "${var.name_prefix}-ml-api-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name_prefix}-ml-api-psc"
    private_connection_resource_id = azurerm_machine_learning_workspace.main.id
    is_manual_connection           = false
    subresource_names              = ["amlworkspace"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.api_dns_zone_id]
  }

  tags = var.tags
}

# Private Endpoint for ML Workspace Notebooks
resource "azurerm_private_endpoint" "ml_notebooks_pe" {
  name                = "${var.name_prefix}-ml-notebooks-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name_prefix}-ml-notebooks-psc"
    private_connection_resource_id = azurerm_machine_learning_workspace.main.id
    is_manual_connection           = false
    subresource_names              = ["amlworkspace"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.notebooks_dns_zone_id]
  }

  tags = var.tags
}

# Get ACR resource to assign role
data "azurerm_container_registry" "acr" {
  name                = split("/", var.container_registry_id)[8]
  resource_group_name = var.resource_group_name
}

# Assign AcrPull role to ML workspace managed identity
resource "azurerm_role_assignment" "ml_acr_pull" {
  scope                = var.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_machine_learning_workspace.main.identity[0].principal_id
}