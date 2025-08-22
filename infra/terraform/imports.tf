import {
  to = module.st_ml.azurerm_storage_account.this
  id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.rg_name}/providers/Microsoft.Storage/storageAccounts/${local.st_ml}"
}

import {
  to = module.st_adls.azurerm_storage_account.this
  id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.rg_name}/providers/Microsoft.Storage/storageAccounts/${local.st_adls}"
}

import {
  to = module.st_arti.azurerm_storage_account.this
  id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.rg_name}/providers/Microsoft.Storage/storageAccounts/${local.st_arti}"
}
