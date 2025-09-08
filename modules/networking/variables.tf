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

variable "ml_vnet_address_space" {
  description = "Address space for ML VNet"
  type        = list(string)
}

variable "compute_vnet_address_space" {
  description = "Address space for Compute VNet"
  type        = list(string)
}

variable "ml_subnets" {
  description = "ML VNet subnets configuration"
  type = map(object({
    address_prefixes = list(string)
  }))
}

variable "compute_subnets" {
  description = "Compute VNet subnets configuration"
  type = map(object({
    address_prefixes = list(string)
  }))
}

variable "private_dns_zones" {
  description = "List of private DNS zones to create"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}