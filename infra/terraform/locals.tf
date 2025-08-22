locals {
  uniq_seed = sha256("${data.azurerm_client_config.current.subscription_id}-${var.rg_name}")
  uniq      = substr(local.uniq_seed, 0, 7)

  # Descriptive, purpose-first names with a single deterministic suffix
  # Storage accounts (alphanumeric only, <=24 chars)
  st_ml   = "stml${local.uniq}"
  st_adls = "stadls${local.uniq}"
  st_arti = "starti${local.uniq}"

  # Key Vault and other resources (hyphens allowed per service rules)
  kv_name     = "kv-ml-${local.uniq}"
  aml_ws      = "amlws-${local.uniq}"
  pip_nat     = "pip-nat-${local.uniq}"
  ngw_name    = "ngw-aci-${local.uniq}"
  pip_bastion = "pip-bastion-${local.uniq}"
  bastion     = "bastion-${local.uniq}"
  vm_jump     = "vm-jump-${local.uniq}"
  law_name    = "law-${local.uniq}"
  appi_name   = "appi-${local.uniq}"
}
