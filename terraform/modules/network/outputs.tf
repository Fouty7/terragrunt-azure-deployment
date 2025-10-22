output "vnet_id" {
  value       = azurerm_virtual_network.this.id
  description = "The ID of the virtual network"
}

output "vnet_name" {
  value       = azurerm_virtual_network.this.name
  description = "The name of the virtual network"
}

output "aks_subnet_id" {
  value       = azurerm_subnet.aks.id
  description = "The ID of the AKS subnet"
}

output "aks_subnet_name" {
  value       = azurerm_subnet.aks.name
  description = "The name of the AKS subnet"
}

output "nsg_id" {
  value       = azurerm_network_security_group.aks.id
  description = "The ID of the network security group"
}