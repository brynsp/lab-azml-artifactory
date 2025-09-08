output "ml_vnet_id" {
  description = "ID of the ML VNet"
  value       = azurerm_virtual_network.ml_vnet.id
}

output "compute_vnet_id" {
  description = "ID of the Compute VNet"
  value       = azurerm_virtual_network.compute_vnet.id
}

output "ml_subnet_id" {
  description = "ID of the ML subnet"
  value       = azurerm_subnet.ml_subnets["ml_subnet"].id
}

output "ml_pe_subnet_id" {
  description = "ID of the ML private endpoint subnet"
  value       = azurerm_subnet.ml_subnets["ml_pe_subnet"].id
}

output "compute_subnet_id" {
  description = "ID of the Compute subnet"
  value       = azurerm_subnet.compute_subnets["compute_subnet"].id
}

output "compute_pe_subnet_id" {
  description = "ID of the Compute private endpoint subnet"
  value       = azurerm_subnet.compute_subnets["compute_pe_subnet"].id
}

output "bastion_subnet_id" {
  description = "ID of the Bastion subnet"
  value       = azurerm_subnet.compute_subnets["bastion_subnet"].id
}

output "acr_dns_zone_id" {
  description = "ID of the ACR private DNS zone"
  value       = azurerm_private_dns_zone.private_dns_zones["privatelink.azurecr.io"].id
}

output "blob_storage_dns_zone_id" {
  description = "ID of the Blob storage private DNS zone"
  value       = azurerm_private_dns_zone.private_dns_zones["privatelink.blob.core.windows.net"].id
}

output "file_storage_dns_zone_id" {
  description = "ID of the File storage private DNS zone"
  value       = azurerm_private_dns_zone.private_dns_zones["privatelink.file.core.windows.net"].id
}

output "key_vault_dns_zone_id" {
  description = "ID of the Key Vault private DNS zone"
  value       = azurerm_private_dns_zone.private_dns_zones["privatelink.vaultcore.azure.net"].id
}

output "ml_api_dns_zone_id" {
  description = "ID of the ML API private DNS zone"
  value       = azurerm_private_dns_zone.private_dns_zones["privatelink.api.azureml.ms"].id
}

output "ml_notebooks_dns_zone_id" {
  description = "ID of the ML notebooks private DNS zone"
  value       = azurerm_private_dns_zone.private_dns_zones["privatelink.notebooks.azure.net"].id
}