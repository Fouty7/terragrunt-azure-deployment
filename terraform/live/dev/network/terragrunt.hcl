terraform {
  source = "../../../modules/network"
}

include "root" {
  path = find_in_parent_folders()
}

# Access parent locals through dependency injection
locals {
  parent_vars = read_terragrunt_config(find_in_parent_folders())
  env                 = local.parent_vars.locals.env
  resource_group_name = local.parent_vars.locals.resource_group_name
  location            = local.parent_vars.locals.location
}

inputs = {
  cluster_name        = "cai-aks-${local.env}"
  resource_group_name = local.resource_group_name
  location            = local.location

  tags = {
    Project     = "CAI-Network"
    Environment = local.env
    ManagedBy   = "Terragrunt"
  }
}