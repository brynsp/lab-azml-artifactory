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