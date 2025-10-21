

terraform {
  source = "../../../modules/keyvault"
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
  name                = "cai-${local.env}-kv"
  location            = local.location
  resource_group_name = local.resource_group_name

  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  enable_rbac_authorization  = true

  default_secrets = {
    "sql-connection-string" = "Server=test-sql.database.windows.net;Database=testdb;User Id=testadmin;Password=${get_env("SQL_ADMIN_PASSWORD", "Default123!")};Encrypt=true;TrustServerCertificate=true;"
    "application-insights-key" = "00000000-0000-0000-0000-000000000000"
    "test-api-key" = "test-api-key-123"
    "redis-connection" = "localhost:6379"
  }

  tags = {
    Project     = "CAI-KeyVault"
    Environment = local.env
    ManagedBy   = "Terragrunt"
  }
}
