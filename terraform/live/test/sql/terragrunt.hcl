
terraform {
  source = "../../../modules/sql"
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
  cluster_name        = "cai-aks-${local.env}-v2"
  resource_group_name = local.resource_group_name
  location            = local.location

  admin_username = "testadmin"
  admin_password = "YourStrong!Passw0rd" # < ---- for real use, inject via environment variable or secrets backend

  tags = {
    Project     = "CAI-Database"
    Environment = local.env
    Purpose     = "Integration-Testing"
  }
}
