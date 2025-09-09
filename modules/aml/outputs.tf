output "workspace_id" {
  description = "ID of the ML workspace"
  value       = azurerm_machine_learning_workspace.main.id
}

output "workspace_name" {
  description = "Name of the ML workspace"
  value       = azurerm_machine_learning_workspace.main.name
}

output "principal_id" {
  description = "Principal ID of the ML workspace managed identity"
  value       = azurerm_machine_learning_workspace.main.identity[0].principal_id
}

output "application_insights_id" {
  description = "ID of the Application Insights instance"
  value       = azurerm_application_insights.main.id
}