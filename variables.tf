variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "canadacentral"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-lab-azml-artifactory"
}

variable "environment" {
  description = "Environment name for resource naming"
  type        = string
  default     = "lab"
}

variable "project" {
  description = "Project name for resource naming"
  type        = string
  default     = "azml-artifactory"
}

variable "subscription_id" {
  description = "Azure subscription ID to deploy resources into (optional if set via ARM_SUBSCRIPTION_ID env var)"
  type        = string
  default     = null
}

variable "admin_username" {
  description = "Administrator username for VMs"
  type        = string
  default     = "labadmin"
}

variable "admin_password" {
  description = "Administrator password for VMs"
  type        = string
  sensitive   = true
  default     = null
}

variable "artifactory_username" {
  description = "Username for Artifactory authentication"
  type        = string
  default     = "admin"
}

variable "artifactory_password" {
  description = "Password for Artifactory authentication"
  type        = string
  sensitive   = true
  default     = "password"
}

variable "enable_bastion" {
  description = "Enable Azure Bastion for secure VM access"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Lab"
    Project     = "AzureML-Artifactory"
    Purpose     = "Testing container deployment"
    Owner       = "Contoso"
  }
}

variable "windows_setup_rerun_token" {
  description = "Change to force the Windows setup extension to re-run (propagates a hash change)."
  type        = string
  default     = "initial"
}

variable "enable_nat_gateway" {
  description = "Deploy a NAT Gateway for explicit outbound egress (replaces default system outbound)."
  type        = bool
  default     = false
}
