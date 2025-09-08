output "id" {
  description = "ID of the Storage Account"
  value       = azurerm_storage_account.main.id
}

output "name" {
  description = "Name of the Storage Account"
  value       = azurerm_storage_account.main.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}