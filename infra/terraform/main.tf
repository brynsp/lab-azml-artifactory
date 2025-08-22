module "kv" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = ">= 0.1.0"

  name                          = local.kv_name
  location                      = var.location
  resource_group_name           = var.rg_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  public_network_access_enabled = false
  enable_telemetry              = false
  depends_on                    = [module.rg]
}
