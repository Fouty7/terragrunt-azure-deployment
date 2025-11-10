# terraform/live/test/terragrunt.hcl
locals {
  env                  = "test"
  location             = "westus2"
  resource_group_name  = "test-rg"
  storage_account_name = "tfbackend2967"
  container_name       = "tfstate"

  # Kubernetes specific variables. Node pool defaults used by child modules
  node_count          = 1
  vm_size             = "Standard_B2s"
  enable_auto_scaling = false
  min_count           = 1
  max_count           = 2
}

# Tell Terragrunt to configure Terraform backend for this environment
remote_state {
  backend = "azurerm"
  config = {
    resource_group_name  = local.resource_group_name
    storage_account_name = local.storage_account_name
    container_name       = local.container_name
    key                  = "${path_relative_to_include()}/terraform.tfstate"
  }
}

# Generate provider configurations for all child modules
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.3.0"
  
  backend "azurerm" {}
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
EOF
}

# Inputs that child modules will receive automatically
inputs = {
  env                 = local.env
  location            = local.location
  resource_group_name = local.resource_group_name

  # defaults for node pool - child modules can override if needed
  node_count          = local.node_count
  vm_size             = local.vm_size
  enable_auto_scaling = local.enable_auto_scaling
  min_count           = local.min_count
  max_count           = local.max_count
}
