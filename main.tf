# Generate random password for VMs if not provided
resource "random_password" "vm_admin_password" {
  count   = var.admin_password == null ? 1 : 0
  length  = 16
  special = true
}

# Main resource group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Networking module
module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name_prefix         = local.name_prefix

  ml_vnet_address_space      = local.ml_vnet_address_space
  compute_vnet_address_space = local.compute_vnet_address_space
  ml_subnets                 = local.ml_subnets
  compute_subnets            = local.compute_subnets
  private_dns_zones          = local.private_dns_zones
  enable_nat_gateway         = var.enable_nat_gateway

  tags = local.common_tags
}

# Key Vault module
module "key_vault" {
  source = "./modules/key_vault"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name_prefix         = local.name_prefix

  private_endpoint_subnet_id = module.networking.compute_pe_subnet_id
  private_dns_zone_id        = module.networking.key_vault_dns_zone_id

  tags = local.common_tags

  depends_on = [module.networking]
}

# Storage module
module "storage" {
  source = "./modules/storage"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name_prefix         = local.name_prefix

  private_endpoint_subnet_id = module.networking.ml_pe_subnet_id
  blob_dns_zone_id           = module.networking.blob_storage_dns_zone_id
  file_dns_zone_id           = module.networking.file_storage_dns_zone_id

  tags = local.common_tags

  depends_on = [module.networking]
}

# Azure Container Registry module
module "acr" {
  source = "./modules/acr"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name_prefix         = local.name_prefix

  private_endpoint_subnet_id = module.networking.ml_pe_subnet_id
  private_dns_zone_id        = module.networking.acr_dns_zone_id

  tags = local.common_tags

  depends_on = [module.networking]
}

# Azure ML workspace module
module "aml" {
  source = "./modules/aml"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name_prefix         = local.name_prefix

  key_vault_id               = module.key_vault.id
  storage_account_id         = module.storage.id
  container_registry_id      = module.acr.id
  private_endpoint_subnet_id = module.networking.ml_pe_subnet_id
  api_dns_zone_id            = module.networking.ml_api_dns_zone_id
  notebooks_dns_zone_id      = module.networking.ml_notebooks_dns_zone_id

  tags = local.common_tags

  depends_on = [module.key_vault, module.storage, module.acr, module.networking]
}

# Compute module (VMs, Bastion)
module "compute" {
  source = "./modules/compute"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name_prefix         = local.name_prefix

  compute_subnet_id = module.networking.compute_subnet_id
  bastion_subnet_id = module.networking.bastion_subnet_id
  key_vault_id      = module.key_vault.id

  admin_username            = var.admin_username
  admin_password            = var.admin_password != null ? var.admin_password : random_password.vm_admin_password[0].result
  artifactory_username      = var.artifactory_username
  artifactory_password      = var.artifactory_password
  enable_bastion            = var.enable_bastion
  windows_setup_rerun_token = var.windows_setup_rerun_token

  tags = local.common_tags

  depends_on = [module.networking, module.key_vault]
}
