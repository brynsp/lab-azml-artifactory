module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.4.0"
  # Deterministic suffix; disable module's random unique
  suffix        = [local.uniq]
  unique-length = 0
}

# Separate naming contexts for resources that need multiple instances of the same type
module "naming_st_ml" {
  source        = "Azure/naming/azurerm"
  version       = "~> 0.4.0"
  prefix        = ["stml"]
  suffix        = [local.uniq]
  unique-length = 0
}

module "naming_st_adls" {
  source        = "Azure/naming/azurerm"
  version       = "~> 0.4.0"
  prefix        = ["stadls"]
  suffix        = [local.uniq]
  unique-length = 0
}

module "naming_st_arti" {
  source        = "Azure/naming/azurerm"
  version       = "~> 0.4.0"
  prefix        = ["starti"]
  suffix        = [local.uniq]
  unique-length = 0
}

module "naming_pip_nat" {
  source        = "Azure/naming/azurerm"
  version       = "~> 0.4.0"
  prefix        = ["pip", "nat"]
  suffix        = [local.uniq]
  unique-length = 0
}

module "naming_pip_bastion" {
  source        = "Azure/naming/azurerm"
  version       = "~> 0.4.0"
  prefix        = ["pip", "bastion"]
  suffix        = [local.uniq]
  unique-length = 0
}

# Key Vault naming with purpose in name
module "naming_kv" {
  source        = "Azure/naming/azurerm"
  version       = "~> 0.4.0"
  prefix        = ["kv", "lab"]
  suffix        = [local.uniq]
  unique-length = 0
}

# Jump VM naming with purpose in name
module "naming_vm_jump" {
  source        = "Azure/naming/azurerm"
  version       = "~> 0.4.0"
  prefix        = ["vm", "jump"]
  suffix        = [local.uniq]
  unique-length = 0
}
