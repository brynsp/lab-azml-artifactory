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

variable "enable_nat_gateway" {
  description = "If true, deploy a NAT Gateway and associate with primary ML and Compute subnets for explicit outbound access."
  type        = bool
  default     = false
}

variable "nat_gateway_idle_timeout" {
  description = "Idle timeout in minutes for NAT Gateway connections (4-120)."
  type        = number
  default     = 4
}
