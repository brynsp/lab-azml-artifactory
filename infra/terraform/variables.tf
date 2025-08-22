variable "location" {
  type    = string
  default = "canadacentral"
}
variable "subscription_id" {
  description = "Azure subscription ID to use. If empty, the Azure CLI default will be used."
  type        = string
  default     = ""
}
variable "tenant_id" {
  description = "Azure tenant ID to use. If empty, the Azure CLI default will be used."
  type        = string
  default     = ""
}
variable "rg_name" {
  type    = string
  default = "rg-8451artifactorylab"
}

# Address spaces and subnets
variable "vnet_ml_name" {
  type    = string
  default = "vnet-ml"
}
variable "vnet_arti_name" {
  type    = string
  default = "vnet-arti"
}
variable "addr_ml" {
  type    = string
  default = "10.10.0.0/16"
}
variable "addr_arti" {
  type    = string
  default = "10.20.0.0/16"
}
variable "snet_ml_pe" {
  type    = string
  default = "snet-ml-pe"
}
variable "pfx_ml_pe" {
  type    = string
  default = "10.10.1.0/24"
}
variable "snet_arti_aci" {
  type    = string
  default = "snet-arti-aci"
}
variable "pfx_arti_aci" {
  type    = string
  default = "10.20.1.0/24"
}
variable "snet_arti_pe" {
  type    = string
  default = "snet-arti-pe"
}
variable "pfx_arti_pe" {
  type    = string
  default = "10.20.2.0/24"
}

# Bastion / Jumpbox
variable "snet_bastion" {
  type    = string
  default = "AzureBastionSubnet"
}
variable "pfx_bastion" {
  type    = string
  default = "10.10.0.0/26"
}
variable "snet_jump" {
  type    = string
  default = "snet-jump"
}
variable "pfx_jump" {
  type    = string
  default = "10.10.0.64/26"
}
variable "vm_jump_size" {
  type    = string
  default = "Standard_B1s"
}
variable "vm_jump_admin" {
  type    = string
  default = "labadmin"
}

# Artifactory
variable "arti_image" {
  type    = string
  default = "releases-docker.jfrog.io/jfrog/artifactory-oss:latest"
}
variable "arti_cg" {
  type    = string
  default = "aci-artifactory"
}
variable "arti_share" {
  type    = string
  default = "artidata"
}
variable "arti_cpu" {
  type    = number
  default = 2
}
variable "arti_mem" {
  type    = number
  default = 4
}
