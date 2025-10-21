# live/dev/terragrunt.hcl (or dev/prod)
locals {
  env                 = "dev"                  # Change to dev/prod per environment
  resource_group_name  = "rg-tf-backend-${local.env}"
  location             = "eastus"
  storage_account_name = "tfbackend${local.env}"
}

inputs = {
  resource_group_name = local.resource_group_name
  location            = local.location
}
