locals {
  # Naming convention
  name_prefix = "${var.environment}-${var.project}"
  
  # Network configuration
  ml_vnet_address_space      = ["10.0.0.0/16"]
  compute_vnet_address_space = ["10.1.0.0/16"]
  
  ml_subnets = {
    ml_subnet = {
      address_prefixes = ["10.0.1.0/24"]
    }
    ml_pe_subnet = {
      address_prefixes = ["10.0.2.0/24"]
    }
  }
  
  compute_subnets = {
    compute_subnet = {
      address_prefixes = ["10.1.1.0/24"]
    }
    compute_pe_subnet = {
      address_prefixes = ["10.1.2.0/24"]
    }
    bastion_subnet = {
      address_prefixes = ["10.1.3.0/27"]
    }
  }
  
  # Private DNS zones
  private_dns_zones = [
    "privatelink.azurecr.io",
    "privatelink.blob.core.windows.net",
    "privatelink.file.core.windows.net",
    "privatelink.vaultcore.azure.net",
    "privatelink.api.azureml.ms",
    "privatelink.notebooks.azure.net"
  ]
  
  # Common tags
  common_tags = merge(var.tags, {
    Location = var.location
  })
}