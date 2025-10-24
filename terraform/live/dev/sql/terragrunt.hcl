
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
  cluster_name        = "cai-aks-${local.env}"
  resource_group_name = local.resource_group_name
  location            = local.location

  admin_username = "testadmin"
  # Password from environment variable - set SQL_ADMIN_PASSWORD before running
  # For GitHub Actions: Add SQL_ADMIN_PASSWORD to repository secrets
  # For local dev: Set $env:SQL_ADMIN_PASSWORD or export SQL_ADMIN_PASSWORD
  admin_password = get_env("SQL_ADMIN_PASSWORD", "DefaultTestPassword123!")  # Default for local testing only

  tags = {
    Project     = "CAI-Database"
    Environment = local.env
    Purpose     = "Integration-Testing"
  }
}
