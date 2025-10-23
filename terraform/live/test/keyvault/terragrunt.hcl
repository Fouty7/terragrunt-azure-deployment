terraform {
  source = "../../../modules/keyvault"
}

# Dependencies
dependencies {
  paths = ["../sql", "../monitoring"]
}

dependency "sql" {
  config_path = "../sql"
  mock_outputs = {
    sql_connection_string = "mock-connection-string"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "monitoring" {
  config_path = "../monitoring"
  mock_outputs = {
    application_insights_instrumentation_key = "mock-insights-key"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
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
    "sql-connection-string" = dependency.sql.outputs.sql_connection_string
    "application-insights-key" = dependency.monitoring.outputs.application_insights_instrumentation_key
    "test-api-key" = "test-api-key-123"
    "redis-connection" = "localhost:6379"
  }

  tags = {
    Project     = "CAI-KeyVault"
    Environment = local.env
    ManagedBy   = "Terragrunt"
  }
}
