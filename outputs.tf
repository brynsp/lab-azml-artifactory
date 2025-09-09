output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "ml_vnet_id" {
  description = "ID of the ML VNet"
  value       = module.networking.ml_vnet_id
}

output "compute_vnet_id" {
  description = "ID of the Compute VNet"
  value       = module.networking.compute_vnet_id
}

output "artifactory_vm_private_ip" {
  description = "Private IP address of the Artifactory VM"
  value       = module.compute.artifactory_vm_private_ip
}

output "jumpbox_vm_private_ip" {
  description = "Private IP address of the Jumpbox VM"
  value       = module.compute.jumpbox_vm_private_ip
}

output "bastion_fqdn" {
  description = "FQDN of the Azure Bastion"
  value       = var.enable_bastion ? module.compute.bastion_fqdn : null
}

output "acr_login_server" {
  description = "Login server URL for the Azure Container Registry"
  value       = module.acr.login_server
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = module.acr.name
}

output "ml_workspace_name" {
  description = "Name of the Azure ML workspace"
  value       = module.aml.workspace_name
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = module.key_vault.name
}

output "artifactory_url" {
  description = "URL for accessing Artifactory"
  value       = "http://${module.compute.artifactory_vm_private_ip}:8082"
}

output "setup_instructions" {
  description = "Instructions for setting up the lab environment"
  value       = <<-EOT
    1. Connect to the Jumpbox VM via Azure Bastion: ${var.enable_bastion ? module.compute.bastion_fqdn : "Bastion not enabled"}
    2. Access Artifactory at: http://${module.compute.artifactory_vm_private_ip}:8082
    3. Use the PAT generation script to create authentication tokens
    4. Configure Azure ML workspace to pull images from ACR: ${module.acr.login_server}
    5. Run image sync scripts to move containers from Artifactory to ACR
    
    For detailed instructions, see the README.md file.
  EOT
}
