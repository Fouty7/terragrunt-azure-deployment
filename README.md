# 🏗️ Azure Infrastructure with Terraform & Terragrunt - CI/CD Pipeline

Production-ready, multi-environment Azure infrastructure with automated GitHub Actions CI/CD pipeline.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [GitHub Actions Pipeline Setup](#github-actions-pipeline-setup)
- [Using the Pipeline](#using-the-pipeline)
- [Adding New Environments](#adding-new-environments)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

This project provides a complete Infrastructure as Code (IaC) solution for Azure with:

### Infrastructure Components

| Component | Purpose | Dependencies |
|-----------|---------|--------------|
| **Network** | VNet, subnet, NSG for AKS | None |
| **Monitoring** | Log Analytics + Application Insights | None |
| **SQL Database** | Azure SQL Server + Database | None |
| **KeyVault** | Secrets management with RBAC | SQL, Monitoring |
| **AKS Cluster** | Kubernetes cluster with monitoring | Monitoring, Network |

### CI/CD Pipeline Features

- ✅ **Automatic Planning** - `terraform plan` runs on every PR
- ✅ **Plan Commenting** - Results posted directly to PR
- ✅ **Automatic Apply** - Deploys on merge to `main`
- ✅ **Environment Detection** - Only changed environments are affected
- ✅ **Manual Triggers** - Deploy any environment on-demand
- ✅ **Approval Gates** - Production requires manual approval
- ✅ **Artifact Storage** - Kubeconfig files automatically saved

---

## 🏗️ Architecture

### Project Structure

```
terraform/
├── modules/              # Reusable Terraform modules
│   ├── aks/             # Azure Kubernetes Service
│   ├── keyvault/        # Azure Key Vault
│   ├── monitoring/      # Log Analytics + App Insights
│   ├── network/         # Virtual Network
│   └── sql/             # Azure SQL Database
│
├── live/                # Environment-specific configurations
│   ├── test/            # Test environment
│   │   ├── terragrunt.hcl       # Environment config
│   │   ├── aks/                 # AKS configuration
│   │   ├── keyvault/            # KeyVault configuration
│   │   ├── monitoring/          # Monitoring configuration
│   │   ├── network/             # Network configuration
│   │   └── sql/                 # SQL configuration
│   ├── dev/             # Development environment
│   └── prod/            # Production environment
│
└── scripts/             # Deployment automation scripts
    ├── windows/         # PowerShell scripts
    └── unix/            # Bash scripts

.github/
└── workflows/           # GitHub Actions CI/CD workflows
    ├── terragrunt-plan.yml   # Plan on PR
    └── terragrunt-apply.yml  # Apply on merge
```

### Deployment Dependencies

```
┌─────────────────────────────────────────┐
│  Independent Modules (parallel)         │
│  ┌──────────┐ ┌─────────┐ ┌─────────┐ │
│  │Monitoring│ │ Network │ │   SQL   │ │
│  └────┬─────┘ └────┬────┘ └────┬────┘ │
└───────┼────────────┼──────────┼────────┘
        │            │          │
        └────────┬───┴──────────┘
                 │
                 ▼
        ┌────────────────┐
        │   KeyVault     │  (depends on SQL & Monitoring)
        └────────┬───────┘
                 │
    ┌────────────┴────────────┐
    │                         │
    ▼                         ▼
Monitoring                Network
    │                         │
    └───────────┬─────────────┘
                │
                ▼
        ┌───────────────┐
        │      AKS      │  (depends on Monitoring & Network)
        └───────────────┘
```

---

## 📋 Prerequisites

### Required Tools

- **[Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)** (latest version)
- **[Terraform](https://www.terraform.io/downloads)** >= 1.3.0
- **[Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/)** (latest version)
- **Git** (for version control)
- **GitHub Account** with repository access

### Azure Requirements

- Active Azure subscription
- Permissions to create resources and service principals
- Resource quotas for AKS, SQL, and other services

---

## 🚀 Initial Setup

### Step 1: Clone Repository

```bash
git clone <your-repo-url>
cd Azure-Environment-Terraform
```

### Step 2: Azure Authentication

```bash
# Login to Azure
az login

# Verify subscription
az account show

# Set subscription if needed
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### Step 3: Create Service Principal for GitHub Actions

```bash
# Create service principal with Contributor role
az ad sp create-for-rbac \
  --name "github-actions-terraform-sp" \
  --role="Contributor" \
  --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"

# Output will be like:
# {
#   "appId": "xxx",        # → ARM_CLIENT_ID
#   "password": "xxx",     # → ARM_CLIENT_SECRET
#   "tenant": "xxx"        # → ARM_TENANT_ID
# }
```

**⚠️ Important: Save this output securely - you'll need it for GitHub Secrets!**

Grant additional permissions for KeyVault role assignments:

```bash
az role assignment create \
  --assignee "YOUR_CLIENT_ID_FROM_ABOVE" \
  --role "User Access Administrator" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID"
```

### Step 4: Create Azure Backend Storage

This storage account will hold Terraform state files.

```bash
# Set variables (customize as needed)
$ResourceGroupName = "test-rg"
$StorageAccountName = "tfbackend$(Get-Random)"  # Must be globally unique
$Location = "westus2"

# Create resource group
az group create --name $ResourceGroupName --location $Location

# Register storage provider
az provider register --namespace Microsoft.Storage

# Create storage account
az storage account create `
  --name $StorageAccountName `
  --resource-group $ResourceGroupName `
  --location $Location `
  --sku Standard_LRS `
  --kind StorageV2 `
  --encryption-services blob

# Create container for Terraform state
az storage container create `
  --name "tfstate" `
  --account-name $StorageAccountName `
  --auth-mode login

# Grant service principal access to storage
$StorageAccountId = az storage account show `
  --name $StorageAccountName `
  --resource-group $ResourceGroupName `
  --query id -o tsv

az role assignment create `
  --assignee "YOUR_SERVICE_PRINCIPAL_CLIENT_ID" `
  --role "Storage Blob Data Contributor" `
  --scope $StorageAccountId
```

**💾 Save your storage account name - you'll need it in the next step!**

### Step 5: Set Up Pre-commit Hooks (Optional but Recommended)

Pre-commit hooks catch errors before they reach GitHub, saving time and preventing issues.

```bash
# Install pre-commit
pip install pre-commit

# Install hooks in this repo
pre-commit install

# Test (optional)
pre-commit run --all-files
```

**What this does:**
- ✅ Auto-formats Terraform code
- ✅ Validates syntax before commit
- ✅ Scans for security issues
- ✅ Catches common mistakes early

**Takes 2 seconds per commit, saves 30+ minutes per failed PR!**

### Step 6: Update Terragrunt Configuration

Edit `terraform/live/test/terragrunt.hcl` and update the storage account name:

```hcl
locals {
  env                  = "test"
  location             = "westus2"
  resource_group_name  = "test-rg"
  storage_account_name = "YOUR_STORAGE_ACCOUNT_NAME"  # ← UPDATE THIS
  container_name       = "tfstate"
  # ... rest of config
}
```

---

## 🤖 GitHub Actions Pipeline Setup

### Step 1: Configure GitHub Secrets

Navigate to your repository on GitHub: **Settings → Secrets and variables → Actions**

Click **New repository secret** and add the following:

| Secret Name | Value | How to Get |
|-------------|-------|------------|
| `ARM_SUBSCRIPTION_ID` | Your Azure subscription ID | `az account show --query id -o tsv` |
| `ARM_CLIENT_ID` | Service Principal App ID | From Step 3 above |
| `ARM_CLIENT_SECRET` | Service Principal Password | From Step 3 above |
| `ARM_TENANT_ID` | Azure Tenant ID | `az account show --query tenantId -o tsv` |
| `SQL_ADMIN_PASSWORD` | SQL Server admin password | Create a strong password (min 8 chars, mixed case, numbers, special chars) |

### Step 2: Configure GitHub Environments (Optional but Recommended)

GitHub Environments provide approval gates for production deployments.

1. Go to **Settings → Environments**
2. Click **New environment**
3. Create three environments:
   - `test` (no protection rules)
   - `dev` (no protection rules)
   - `prod` (enable protection rules)

#### Configure Production Protection:

For the `prod` environment:
1. ✅ Enable **Required reviewers**
2. Add team members who must approve production deployments
3. Optionally enable **Wait timer** (e.g., 5 minutes delay)

This ensures production deployments require manual approval.

### Step 3: Verify Workflow Files

The repository includes two workflow files:

**`.github/workflows/terragrunt-plan.yml`**
- Triggers on pull requests
- Runs `terragrunt plan` for changed environments
- Posts results as PR comment

**`.github/workflows/terragrunt-apply.yml`**
- Triggers on merge to `main` or manual dispatch
- Runs `terragrunt apply` to deploy infrastructure
- Uploads kubeconfig artifacts

These files are pre-configured and ready to use.

---

## 🎯 Using the Pipeline

### Workflow 1: Automated PR → Plan → Review → Merge → Apply

This is the recommended workflow for all infrastructure changes.

#### Step 1: Create Feature Branch

```bash
# Create and checkout a new feature branch
git checkout -b feature/add-monitoring-alerts

# Make your infrastructure changes
# Example: Edit terraform/live/test/monitoring/terragrunt.hcl
```

#### Step 2: Commit and Push

```bash
# Stage your changes
git add .

# Commit with descriptive message
git commit -m "Add monitoring alerts for AKS cluster"

# Push to GitHub
git push origin feature/add-monitoring-alerts
```

#### Step 3: Create Pull Request

1. Go to GitHub repository
2. Click **Pull requests → New pull request**
3. Select your feature branch
4. Click **Create pull request**

**What happens automatically:**
- GitHub Actions detects changed files
- Determines affected environments (test/dev/prod)
- Runs `terragrunt plan` for each environment
- Posts plan output as a comment on the PR

#### Step 4: Review Plan Output

The PR comment will show:

```
## Terragrunt Plan: `test` ✅ Success

<details>
<summary>Show Plan Output</summary>

```
Terraform will perform the following actions:

  # azurerm_monitor_metric_alert.cpu_alert will be created
  + resource "azurerm_monitor_metric_alert" "cpu_alert" {
      + name                = "aks-cpu-high"
      + resource_group_name = "test-rg"
      ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

</details>

**Environment**: `test`
**Exit Code**: `0`
```

#### Step 5: Code Review

- Review the plan output
- Request review from team members
- Address any feedback

#### Step 6: Merge Pull Request

After approval, merge the PR to `main`.

**What happens automatically:**
- GitHub Actions detects the merge
- Identifies changed environments
- Runs `terragrunt apply --auto-approve`
- Deploys infrastructure to Azure
- Uploads kubeconfig artifact (if AKS changed)
- Creates deployment summary

#### Step 7: Verify Deployment

1. Go to **Actions** tab on GitHub
2. View the workflow run
3. Check deployment summary
4. Verify resources in Azure Portal

---

### Workflow 2: Manual Deployment

Use this for first-time deployments or emergency updates.

#### Step 1: Navigate to Actions

1. Go to **Actions** tab on GitHub
2. Select **Terragrunt Apply** workflow
3. Click **Run workflow** button

#### Step 2: Configure Deployment

Select deployment options:

- **Branch**: `main` (or your branch)
- **Environment**: Choose `test`, `dev`, or `prod`
- **First deploy**: Check this for first-time deployment

#### Step 3: Run Workflow

Click **Run workflow**

For production deployments:
- Workflow will pause for approval
- Designated reviewers will receive notification
- Approve in **Actions → Review deployments**

---

## 🔄 Deployment Workflows

### Standard Deployment (After Initial Setup)

```bash
# GitHub Actions runs:
cd terraform/live/<environment>
terragrunt run-all apply --terragrunt-parallelism 1 --auto-approve
```

All modules are deployed respecting their dependencies.

### First Deployment (For New Environments)

When deploying a new environment for the first time, enable "First deploy" mode. This ensures proper dependency ordering:

```bash
# Step 1: Independent modules
terragrunt apply --working-dir monitoring
terragrunt apply --working-dir network
terragrunt apply --working-dir sql

# Step 2: KeyVault (depends on SQL & monitoring)
terragrunt apply --working-dir keyvault

# Step 3: AKS (depends on monitoring & network)
terragrunt apply --working-dir aks
```

---

## ➕ Adding New Environments

Currently configured: `test` environment
Want to add: `dev`, `prod`, `staging`, etc.

### Step 1: Create Backend Storage

```bash
# Set environment name
$ENV = "dev"  # or prod, staging, etc.
$ResourceGroupName = "${ENV}-rg"
$StorageAccountName = "tfbackend${ENV}$(Get-Random)"
$Location = "eastus"  # choose your region

# Create resource group
az group create --name $ResourceGroupName --location $Location

# Create storage account
az storage account create `
  --name $StorageAccountName `
  --resource-group $ResourceGroupName `
  --location $Location `
  --sku Standard_LRS

# Create container
az storage container create `
  --name "tfstate" `
  --account-name $StorageAccountName `
  --auth-mode login

# Grant service principal access
$StorageAccountId = az storage account show `
  --name $StorageAccountName `
  --resource-group $ResourceGroupName `
  --query id -o tsv

az role assignment create `
  --assignee "YOUR_SERVICE_PRINCIPAL_CLIENT_ID" `
  --role "Storage Blob Data Contributor" `
  --scope $StorageAccountId
```

### Step 2: Copy Environment Directory

```bash
# Copy existing environment as template
cd terraform/live
cp -r test dev  # or your new environment name
```

### Step 3: Update Environment Configuration

Edit `terraform/live/dev/terragrunt.hcl`:

```hcl
locals {
  env                  = "dev"  # ← Update environment name
  location             = "eastus"  # ← Update region if needed
  resource_group_name  = "dev-rg"  # ← Update resource group
  storage_account_name = "YOUR_NEW_STORAGE_ACCOUNT"  # ← Update storage account
  container_name       = "tfstate"

  # Node pool settings (adjust for environment)
  node_count          = 2
  vm_size             = "Standard_B2s"
  enable_auto_scaling = false
  min_count           = 1
  max_count           = 3
}

# Keep the remote_state, generate, and inputs blocks
# Update storage_account_name in remote_state config
remote_state {
  backend = "azurerm"
  config = {
    resource_group_name  = local.resource_group_name
    storage_account_name = local.storage_account_name  # Uses local above
    container_name       = local.container_name
    key                  = "${path_relative_to_include()}/terraform.tfstate"
  }
}

# Provider generation (keep as-is from test)
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
      purge_soft_delete_on_destroy = true  # Set false for production
    }
    resource_group {
      prevent_deletion_if_contains_resources = false  # Set true for production
    }
  }
}
EOF
}

# Inputs passed to child modules
inputs = {
  env                 = local.env
  location            = local.location
  resource_group_name = local.resource_group_name
  node_count          = local.node_count
  vm_size             = local.vm_size
  enable_auto_scaling = local.enable_auto_scaling
  min_count           = local.min_count
  max_count           = local.max_count
}
```

### Step 4: Review Module Configurations

Check each module directory (`aks/`, `keyvault/`, `monitoring/`, `network/`, `sql/`) and update any hardcoded values specific to your new environment.

**Example:** `terraform/live/dev/sql/terragrunt.hcl`

```hcl
inputs = {
  cluster_name        = "myapp-${local.env}-v2"  # Uses 'dev' from parent
  resource_group_name = local.resource_group_name
  location            = local.location
  admin_username      = "devadmin"
  admin_password      = get_env("SQL_ADMIN_PASSWORD", "DefaultDevPass123!")
  # ... other settings
}
```

### Step 5: First Deployment

Use GitHub Actions manual workflow:

1. Go to **Actions → Terragrunt Apply**
2. Click **Run workflow**
3. Select:
   - Environment: `dev` (your new environment)
   - First deploy: ✅ **Checked**
4. Click **Run workflow**

### Step 6: Verify Deployment

```bash
# Check resources in Azure Portal
az resource list --resource-group dev-rg -o table

# Verify state in storage
az storage blob list \
  --account-name YOUR_STORAGE_ACCOUNT \
  --container-name tfstate \
  --auth-mode login -o table
```

---

## 📊 Environment Detection

The GitHub Actions workflows automatically detect which environments need to be planned/applied based on file changes:

| File Changed | Environments Affected |
|--------------|----------------------|
| `terraform/live/test/*` | `test` only |
| `terraform/live/dev/*` | `dev` only |
| `terraform/live/prod/*` | `prod` only (requires approval) |
| `terraform/modules/*` | **Plan:** All environments<br>**Apply:** `test` only (manual promotion to others) |
| Multiple environments | All changed environments |

---

## 🆘 Troubleshooting

### Issue: Plan workflow fails with "Failed to get existing workspaces"

**Cause:** Service principal lacks access to storage account

**Solution:**

```bash
# Grant storage access
$StorageAccountId = az storage account show `
  --name YOUR_STORAGE_ACCOUNT `
  --resource-group YOUR_RG `
  --query id -o tsv

az role assignment create `
  --assignee "YOUR_CLIENT_ID" `
  --role "Storage Blob Data Contributor" `
  --scope $StorageAccountId
```

### Issue: Apply fails with "Resource already exists"

**Cause:** Manual changes conflict with Terraform state

**Solution:**

```bash
# Option 1: Import existing resource
cd terraform/live/test
terragrunt import azurerm_resource_group.rg /subscriptions/.../resourceGroups/test-rg

# Option 2: Remove manually created resource
az resource delete --ids /subscriptions/.../resourceGroups/test-rg
```

### Issue: Workflow doesn't trigger on PR

**Cause:** PR not targeting `main` or `develop` branch

**Solution:** Ensure your PR targets `main` or `develop` (check workflow triggers in `.github/workflows/terragrunt-plan.yml`)

### Issue: State lock errors

**Cause:** Previous operation didn't release lock

**Solution:**

```bash
# Get lock ID from error message, then unlock
cd terraform/live/test
terragrunt force-unlock LOCK_ID_FROM_ERROR_MESSAGE
```

### Issue: Production deployment stuck on "Waiting"

**Cause:** Approval required for production environment

**Solution:**
1. Go to **Actions → Select workflow run**
2. Click **Review deployments**
3. Select `prod` environment
4. Click **Approve and deploy**

---

## 📚 Additional Resources

### Project Documentation

- **README-DEV-TEAM.md** - Local development workflow (scripts, manual operations)
- **`.github/workflows/`** - GitHub Actions workflow definitions

### External Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/)
- [Azure Terraform Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

## 🎉 Quick Start Summary

1. ✅ Clone repository
2. ✅ Create Azure service principal (save output!)
3. ✅ Create backend storage account (save name!)
4. ✅ (Optional) Install pre-commit hooks
5. ✅ Update storage account name in `terraform/live/test/terragrunt.hcl`
6. ✅ Add GitHub secrets (5 secrets: ARM_* + SQL_ADMIN_PASSWORD)
7. ✅ Create feature branch and make changes
8. ✅ Push and create PR
9. ✅ Review plan output in PR comment
10. ✅ Merge PR
11. ✅ Verify automated deployment

**Your infrastructure is now fully automated! 🚀**

For local development and manual script usage, see **README-DEV-TEAM.md**.
