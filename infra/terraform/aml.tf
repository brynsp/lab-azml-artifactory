resource "azurerm_log_analytics_workspace" "law" {
  name                = local.law_name
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "ai" {
  name                = local.appi_name
  location            = var.location
  resource_group_name = var.rg_name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.law.id
}

resource "azurerm_machine_learning_workspace" "aml" {
  name                          = local.aml_ws
  location                      = var.location
  resource_group_name           = var.rg_name
  sku_name                      = "Basic"
  public_network_access_enabled = false
  storage_account_id            = module.st_ml.resource_id
  key_vault_id                  = module.kv.resource_id
  application_insights_id       = azurerm_application_insights.ai.id
  identity {
    type = "SystemAssigned"
  }
  managed_network {
    isolation_mode = "AllowInternetOutbound"
  }
  depends_on = [module.rg]
}
