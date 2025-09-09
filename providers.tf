terraform {
  required_version = ">= 1.3"
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # Upgrade for shared_access_key_enabled support
      version = ">= 3.80.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 1.13.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "azapi" {}

provider "azurerm" {
  subscription_id = var.subscription_id != null ? var.subscription_id : null
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}
