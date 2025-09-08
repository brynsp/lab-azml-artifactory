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

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
}

variable "blob_dns_zone_id" {
  description = "Private DNS zone ID for Blob storage"
  type        = string
}

variable "file_dns_zone_id" {
  description = "Private DNS zone ID for File storage"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}