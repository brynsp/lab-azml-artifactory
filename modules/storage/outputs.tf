output "id" {
  description = "ID of the Storage Account"
  value       = azapi_resource.storage.id
}

output "name" {
  description = "Name of the Storage Account"
  value       = azapi_resource.storage.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = "https://${azapi_resource.storage.name}.blob.core.windows.net/"
}
