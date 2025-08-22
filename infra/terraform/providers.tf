terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.10, < 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  # Use Azure AD for Storage data-plane operations (avoid shared-key access)
  storage_use_azuread = true
  # Optionally pin subscription/tenant. If left empty, provider will use default Azure auth (e.g., Azure CLI).
  subscription_id = var.subscription_id != "" ? var.subscription_id : null
  tenant_id       = var.tenant_id != "" ? var.tenant_id : null
}

data "azurerm_client_config" "current" {}
