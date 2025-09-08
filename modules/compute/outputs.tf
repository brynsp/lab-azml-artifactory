output "artifactory_vm_id" {
  description = "ID of the Artifactory VM"
  value       = azurerm_linux_virtual_machine.artifactory_vm.id
}

output "artifactory_vm_private_ip" {
  description = "Private IP address of the Artifactory VM"
  value       = azurerm_network_interface.artifactory_nic.private_ip_address
}

output "jumpbox_vm_id" {
  description = "ID of the Jumpbox VM"
  value       = azurerm_windows_virtual_machine.jumpbox_vm.id
}

output "jumpbox_vm_private_ip" {
  description = "Private IP address of the Jumpbox VM"
  value       = azurerm_network_interface.windows_nic.private_ip_address
}

output "bastion_id" {
  description = "ID of the Azure Bastion (if enabled)"
  value       = var.enable_bastion ? azurerm_bastion_host.bastion[0].id : null
}

output "bastion_fqdn" {
  description = "FQDN of the Azure Bastion (if enabled)"
  value       = var.enable_bastion ? azurerm_bastion_host.bastion[0].dns_name : null
}