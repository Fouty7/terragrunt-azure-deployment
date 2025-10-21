output "kube_config" {
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  description = "Raw kubeconfig for the AKS cluster"
  sensitive   = true
}

output "cluster_name" {
  value       = azurerm_kubernetes_cluster.aks.name
  description = "Name of the AKS cluster"
}

output "resource_group_name" {
  value       = azurerm_kubernetes_cluster.aks.resource_group_name
  description = "Resource group of the AKS cluster"
}
