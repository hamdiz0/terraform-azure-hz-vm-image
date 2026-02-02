output "custom_image_id" {
  value       = azurerm_image.custom_image.id
  description = "The id of the custom image"
}

output "custom_image_name" {
  value       = azurerm_image.custom_image.name
  description = "The name of the custom image"
}

output "custom_image_location" {
  value       = azurerm_image.custom_image.location
  description = "The location of the custom image"
}

output "custom_image_resource_group" {
  value       = azurerm_image.custom_image.resource_group_name
  description = "The resource group of the custom image"
}
