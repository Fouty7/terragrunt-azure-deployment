resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name

  kubernetes_version = var.kubernetes_version
  
  network_profile {
    network_plugin = var.network_plugin
  }

  default_node_pool {
    name                 = "default"
    node_count           = var.enable_auto_scaling ? null : var.node_count
    vm_size              = var.vm_size
    auto_scaling_enabled = var.enable_auto_scaling
    min_count            = var.enable_auto_scaling ? var.min_count : null
    max_count            = var.enable_auto_scaling ? var.max_count : null
  }

  role_based_access_control_enabled = var.enable_rbac

  # Azure Monitor (OMS Agent) is now configured via oms_agent block
  dynamic "oms_agent" {
    for_each = var.enable_monitoring ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}
