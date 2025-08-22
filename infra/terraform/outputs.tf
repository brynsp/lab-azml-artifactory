output "resource_group" { value = module.rg.name }
output "aml_workspace" { value = azurerm_machine_learning_workspace.aml.name }
output "storage_artifactory" { value = module.st_arti.name }
output "container_group_artifactory" { value = azurerm_container_group.arti.name }
