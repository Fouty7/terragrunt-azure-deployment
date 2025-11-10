# live/test/aks/terragrunt.hcl
include "root" {
  # find nearest parent terragrunt.hcl (this should be terraform/live/test/terragrunt.hcl)
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/aks"
}

# Access parent locals through dependency injection
locals {
  parent_vars = read_terragrunt_config(find_in_parent_folders())
  env                 = local.parent_vars.locals.env
  resource_group_name = local.parent_vars.locals.resource_group_name
  location            = local.parent_vars.locals.location
  node_count          = local.parent_vars.locals.node_count
  vm_size             = local.parent_vars.locals.vm_size
  enable_auto_scaling = local.parent_vars.locals.enable_auto_scaling
  min_count           = local.parent_vars.locals.min_count
  max_count           = local.parent_vars.locals.max_count
}

# Dependencies
dependencies {
  paths = ["../monitoring", "../network"]
}

dependency "monitoring" {
  config_path = "../monitoring"
  mock_outputs = {
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.OperationalInsights/workspaces/mock-workspace"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "network" {
  config_path = "../network"
  mock_outputs = {
    aks_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/mock-subnet"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  cluster_name        = "cai-aks-${local.env}"
  resource_group_name = local.resource_group_name
  location            = local.location
  kubernetes_version  = "1.33.3"

  # inherit from parent environment locals
  node_count          = local.node_count
  vm_size             = local.vm_size
  enable_auto_scaling = local.enable_auto_scaling
  min_count           = local.min_count
  max_count           = local.max_count

  enable_monitoring = true
  enable_rbac       = true
  network_plugin    = "azure"
  network_policy    = "azure"
  
  log_analytics_workspace_id = dependency.monitoring.outputs.log_analytics_workspace_id
  subnet_id = dependency.network.outputs.aks_subnet_id

  tags = {
    Project     = "CAI-Kubernetes"
    Environment = local.env
    ManagedBy   = "Terragrunt"
  }
}
