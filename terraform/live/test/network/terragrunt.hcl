terraform {
  source = "../../../modules/network"
}

include "root" {
  path = find_in_parent_folders()
}

# Access parent locals through dependency injection
locals {
  parent_vars                 = read_terragrunt_config(find_in_parent_folders())
  env                         = local.parent_vars.locals.env
  resource_group_name         = local.parent_vars.locals.resource_group_name
  location                    = local.parent_vars.locals.location
  vnet_address_space          = local.parent_vars.locals.vnet_address_space
  aks_subnet_address_prefixes = local.parent_vars.locals.aks_subnet_address_prefixes
}

inputs = {
  cluster_name                = "cai-aks-${local.env}"
  resource_group_name         = local.resource_group_name
  location                    = local.location
  vnet_address_space          = local.vnet_address_space
  aks_subnet_address_prefixes = local.aks_subnet_address_prefixes

  tags = {
    Project     = "CAI-Network"
    Environment = local.env
    ManagedBy   = "Terragrunt"
  }
}
