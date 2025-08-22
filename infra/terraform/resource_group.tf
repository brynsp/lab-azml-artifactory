module "rg" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = ">= 0.1.0"

  name             = var.rg_name
  location         = var.location
  enable_telemetry = false
}
