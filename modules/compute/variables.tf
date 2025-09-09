variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "compute_subnet_id" {
  description = "Subnet ID for compute resources"
  type        = string
}

variable "bastion_subnet_id" {
  description = "Subnet ID for Azure Bastion"
  type        = string
}

variable "key_vault_id" {
  description = "ID of the Key Vault"
  type        = string
}

variable "admin_username" {
  description = "Administrator username for VMs"
  type        = string
}

variable "admin_password" {
  description = "Administrator password for VMs"
  type        = string
  sensitive   = true
}

variable "artifactory_username" {
  description = "Username for Artifactory"
  type        = string
}

variable "artifactory_password" {
  description = "Password for Artifactory"
  type        = string
  sensitive   = true
}

variable "enable_bastion" {
  description = "Enable Azure Bastion"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "windows_setup_rerun_token" {
  description = "Change this token (e.g. timestamp or increment) to force the Windows setup extension to re-run even if script content unchanged."
  type        = string
  default     = "initial"
}
