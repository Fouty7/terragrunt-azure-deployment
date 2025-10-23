# 👨‍💻 Developer Guide - Local Development & Manual Operations

This guide is for developers who want to work with the infrastructure locally using manual scripts instead of GitHub Actions.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Local Development Workflow](#local-development-workflow)
- [Deployment Scripts](#deployment-scripts)
- [Adding New Environments](#adding-new-environments)
- [Destroying Infrastructure](#destroying-infrastructure)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

This project uses **Terraform** for infrastructure provisioning and **Terragrunt** for DRY configuration management across multiple environments.

### When to Use Local Development

- Testing infrastructure changes locally before creating a PR
- Debugging Terraform/Terragrunt issues
- Quick iterations during development
- Learning the infrastructure codebase
- Emergency fixes when CI/CD is unavailable

### Infrastructure Modules

| Module | Purpose |
|--------|---------|
| **network** | VNet, subnet, NSG for AKS |
| **monitoring** | Log Analytics + Application Insights |
| **sql** | Azure SQL Server + Database |
| **keyvault** | Secrets management (depends on sql, monitoring) |
| **aks** | Kubernetes cluster (depends on monitoring, network) |

---

## 📋 Prerequisites

### Required Tools

Install the following tools on your local machine:

#### 1. Azure CLI
```bash
# Windows (PowerShell)
winget install Microsoft.AzureCLI

# macOS
brew install azure-cli

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

#### 2. Terraform
```bash
# Windows (PowerShell)
choco install terraform

# macOS
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

#### 3. Terragrunt
```bash
# Windows (PowerShell)
choco install terragrunt

# macOS
brew install terragrunt

# Linux
wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.54.0/terragrunt_linux_amd64
chmod +x terragrunt_linux_amd64
sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
```

#### 4. Verify Installation

```bash
az --version
terraform --version
terragrunt --version
```

---

## 🚀 Initial Setup

### Step 1: Clone Repository

```bash
git clone <your-repo-url>
cd Azure-Environment-Terraform
```

## 🔧 Developer Setup

After cloning the repository: Install the hooks (Optional)

```bash
# Install pre-commit
pip install pre-commit

# Activate hooks in this repo
pre-commit install

```

### Step 2: Azure Authentication

```bash
# Login to Azure
az login

# List subscriptions
az account list --output table

# Set active subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Verify
az account show
```

### Step 3: Create Service Principal (Optional)

If you want to use service principal authentication instead of interactive login:

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "terraform-local-dev-sp" \
  --role="Contributor" \
  --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"

# Grant KeyVault permissions
az role assignment create \
  --assignee "CLIENT_ID_FROM_OUTPUT" \
  --role "User Access Administrator" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID"
```

**Save the output:**
```json
{
  "appId": "xxx",       # CLIENT_ID
  "password": "xxx",    # CLIENT_SECRET
  "tenant": "xxx"       # TENANT_ID
}
```

### Step 4: Set Azure Credentials (If Using Service Principal)

**Windows (PowerShell):**
```powershell
# Set environment variables for current session
$env:ARM_SUBSCRIPTION_ID = "your-subscription-id"
$env:ARM_CLIENT_ID = "your-client-id"
$env:ARM_CLIENT_SECRET = "your-client-secret"
$env:ARM_TENANT_ID = "your-tenant-id"

# Or use the provided script
.\terraform\scripts\windows\set-azure-creds.ps1
```

**macOS/Linux (Bash):**
```bash
# Set environment variables
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_TENANT_ID="your-tenant-id"

# Add to ~/.bashrc or ~/.zshrc for persistence
```

### Step 5: Create Backend Storage Account

This storage account stores Terraform state files.

**Windows (PowerShell):**
```powershell
# Set variables
$ResourceGroupName = "test-rg"
$StorageAccountName = "tfbackend$(Get-Random)"  # Must be globally unique
$Location = "westus2"

# Create resource group
az group create --name $ResourceGroupName --location $Location

# Register storage provider
az provider register --namespace Microsoft.Storage

# Wait for registration
az provider show --namespace Microsoft.Storage --query "registrationState"

# Create storage account
az storage account create `
  --name $StorageAccountName `
  --resource-group $ResourceGroupName `
  --location $Location `
  --sku Standard_LRS `
  --kind StorageV2 `
  --encryption-services blob

# Create container
az storage container create `
  --name "tfstate" `
  --account-name $StorageAccountName `
  --auth-mode login

# Display storage account name
Write-Host "Storage Account Name: $StorageAccountName" -ForegroundColor Green
```

**macOS/Linux (Bash):**
```bash
# Set variables
RESOURCE_GROUP="test-rg"
STORAGE_ACCOUNT="tfbackend$RANDOM"
LOCATION="westus2"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Register storage provider
az provider register --namespace Microsoft.Storage

# Create storage account
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2 \
  --encryption-services blob

# Create container
az storage container create \
  --name "tfstate" \
  --account-name $STORAGE_ACCOUNT \
  --auth-mode login

# Display storage account name
echo "Storage Account Name: $STORAGE_ACCOUNT"
```

**💾 Important: Save your storage account name!**

### Step 6: Update Terragrunt Configuration

Edit `terraform/live/test/terragrunt.hcl`:

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

## 💻 Local Development Workflow

### Option 1: Using Deployment Scripts (Recommended)

The project includes automated scripts that handle dependencies correctly.

#### Windows (PowerShell)

```powershell
cd terraform

# First deployment (handles dependencies)
.\scripts\windows\deploy.ps1 -Action apply -Environment test -FirstDeploy

# Subsequent deployments
.\scripts\windows\deploy.ps1 -Action plan -Environment test
.\scripts\windows\deploy.ps1 -Action apply -Environment test
```

#### macOS/Linux (Bash)

```bash
cd terraform

# First deployment (handles dependencies)
./scripts/unix/deploy.sh -a apply -e test -f

# Subsequent deployments
./scripts/unix/deploy.sh -a plan -e test
./scripts/unix/deploy.sh -a apply -e test
```

### Option 2: Manual Terragrunt Commands

For more control or debugging, use Terragrunt directly.

```bash
cd terraform/live/test

# Initialize all modules
terragrunt run-all init

# Plan all modules
terragrunt run-all plan

# Apply all modules
terragrunt run-all apply

# Plan specific module
terragrunt plan --terragrunt-working-dir monitoring

# Apply specific module
terragrunt apply --terragrunt-working-dir monitoring
```

### First Deployment - Dependency Order

For first-time deployment, apply modules in dependency order:

```bash
cd terraform/live/test

# Step 1: Independent modules (can run in parallel)
terragrunt apply --terragrunt-working-dir monitoring --auto-approve
terragrunt apply --terragrunt-working-dir network --auto-approve
terragrunt apply --terragrunt-working-dir sql --auto-approve

# Step 2: KeyVault (depends on SQL and monitoring)
terragrunt apply --terragrunt-working-dir keyvault --auto-approve

# Step 3: AKS (depends on monitoring and network)
terragrunt apply --terragrunt-working-dir aks --auto-approve
```

### Typical Development Workflow

```bash
# 1. Create feature branch
git checkout -b feature/add-alerting

# 2. Make infrastructure changes
# Example: Edit terraform/live/test/monitoring/terragrunt.hcl

# 3. Plan changes
cd terraform/live/test
terragrunt plan --terragrunt-working-dir monitoring

# 4. Review plan output
# Check what resources will be added/changed/destroyed

# 5. Apply changes
terragrunt apply --terragrunt-working-dir monitoring

# 6. Verify in Azure Portal
az resource list --resource-group test-rg -o table

# 7. Commit changes
git add .
git commit -m "Add CPU alerting for AKS"
git push origin feature/add-alerting

# 8. Create PR for review
```

---

## 🔧 Deployment Scripts

### Windows PowerShell Scripts

Located in `terraform/scripts/windows/`

#### deploy.ps1

Full-featured deployment script with dependency handling.

**Parameters:**
- `-Action` - Operation to perform: `plan`, `apply`, or `destroy`
- `-Environment` - Target environment: `test`, `dev`, or `prod`
- `-FirstDeploy` - (Switch) Use dependency-aware sequential deployment

**Examples:**

```powershell
# First deployment
.\scripts\windows\deploy.ps1 -Action apply -Environment test -FirstDeploy

# Plan changes
.\scripts\windows\deploy.ps1 -Action plan -Environment test

# Apply changes
.\scripts\windows\deploy.ps1 -Action apply -Environment test

# Destroy infrastructure
.\scripts\windows\deploy.ps1 -Action destroy -Environment test
```

#### destroy.ps1

Safe infrastructure destruction with confirmation.

**Parameters:**
- `-Environment` - Target environment: `test`, `dev`, or `prod`

**Example:**

```powershell
# Destroy with confirmation prompt
.\scripts\windows\destroy.ps1 -Environment test

# Or use deploy.ps1
.\scripts\windows\deploy.ps1 -Action destroy -Environment test
```

#### set-azure-creds.ps1

Interactive script to set Azure credentials as environment variables.

```powershell
.\scripts\windows\set-azure-creds.ps1
```

### Unix (macOS/Linux) Scripts

Located in `terraform/scripts/unix/`

#### deploy.sh

**Parameters:**
- `-a` - Action: `plan`, `apply`, or `destroy`
- `-e` - Environment: `test`, `dev`, or `prod`
- `-f` - First deploy flag (sequential deployment)

**Examples:**

```bash
# Make scripts executable
chmod +x scripts/unix/*.sh

# First deployment
./scripts/unix/deploy.sh -a apply -e test -f

# Plan changes
./scripts/unix/deploy.sh -a plan -e test

# Apply changes
./scripts/unix/deploy.sh -a apply -e test
```

#### destroy.sh

**Parameters:**
- `-e` - Environment: `test`, `dev`, or `prod`
- `--auto-approve` - Skip confirmation

**Example:**

```bash
# Destroy with confirmation
./scripts/unix/destroy.sh -e test

# Destroy without confirmation (dangerous!)
./scripts/unix/destroy.sh -e test --auto-approve
```

---

## ➕ Adding New Environments

Currently configured: `test`
Want to add: `dev`, `prod`, `staging`, etc.

### Step 1: Create Backend Storage

**Windows:**
```powershell
$ENV = "dev"
$ResourceGroupName = "${ENV}-rg"
$StorageAccountName = "tfbackend${ENV}$(Get-Random)"
$Location = "eastus"

az group create --name $ResourceGroupName --location $Location

az storage account create `
  --name $StorageAccountName `
  --resource-group $ResourceGroupName `
  --location $Location `
  --sku Standard_LRS

az storage container create `
  --name "tfstate" `
  --account-name $StorageAccountName `
  --auth-mode login

Write-Host "Storage Account: $StorageAccountName" -ForegroundColor Green
```

**Unix:**
```bash
ENV="dev"
RESOURCE_GROUP="${ENV}-rg"
STORAGE_ACCOUNT="tfbackend${ENV}$RANDOM"
LOCATION="eastus"

az group create --name $RESOURCE_GROUP --location $LOCATION

az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS

az storage container create \
  --name "tfstate" \
  --account-name $STORAGE_ACCOUNT \
  --auth-mode login

echo "Storage Account: $STORAGE_ACCOUNT"
```

### Step 2: Copy Environment Structure

```bash
cd terraform/live
cp -r test dev

# Or on Windows
Copy-Item -Recurse test dev
```

### Step 3: Update Environment Configuration

Edit `terraform/live/dev/terragrunt.hcl`:

```hcl
locals {
  env                  = "dev"  # ← Change from "test"
  location             = "eastus"  # ← Update region if desired
  resource_group_name  = "dev-rg"  # ← Change resource group name
  storage_account_name = "YOUR_NEW_STORAGE_ACCOUNT"  # ← Update storage account
  container_name       = "tfstate"

  # Adjust resource sizing for dev environment
  node_count          = 2
  vm_size             = "Standard_B2s"
  enable_auto_scaling = false
  min_count           = 1
  max_count           = 3
}

# remote_state block - update storage_account_name
remote_state {
  backend = "azurerm"
  config = {
    resource_group_name  = local.resource_group_name
    storage_account_name = local.storage_account_name  # Uses local above
    container_name       = local.container_name
    key                  = "${path_relative_to_include()}/terraform.tfstate"
  }
}

# Keep generate "provider" block same as test
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

# Inputs block
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

### Step 4: Update Module-Specific Configurations

Review each module directory and update environment-specific values:

**`terraform/live/dev/sql/terragrunt.hcl`:**
```hcl
locals {
  parent_vars = read_terragrunt_config(find_in_parent_folders())
  env         = local.parent_vars.locals.env
  # ...
}

inputs = {
  cluster_name        = "myapp-${local.env}-v2"
  resource_group_name = local.resource_group_name
  location            = local.location
  admin_username      = "devadmin"
  admin_password      = get_env("SQL_ADMIN_PASSWORD", "DevPassword123!")
  # ...
}
```

**`terraform/live/dev/aks/terragrunt.hcl`:**
```hcl
inputs = {
  cluster_name        = "myapp-aks-${local.env}"
  kubernetes_version  = "1.27.7"  # Update version as needed
  # ... inherit other settings from parent
}
```

### Step 5: Deploy New Environment

**Windows:**
```powershell
cd terraform
.\scripts\windows\deploy.ps1 -Action apply -Environment dev -FirstDeploy
```

**Unix:**
```bash
cd terraform
./scripts/unix/deploy.sh -a apply -e dev -f
```

### Step 6: Verify Deployment

```bash
# List resources
az resource list --resource-group dev-rg -o table

# Check state files
az storage blob list \
  --account-name YOUR_STORAGE_ACCOUNT \
  --container-name tfstate \
  --auth-mode login -o table

# Test AKS connection (if deployed)
az aks get-credentials --resource-group dev-rg --name myapp-aks-dev
kubectl get nodes
```

---

## 🗑️ Destroying Infrastructure

### Using Destroy Scripts

**Windows:**
```powershell
# Safe destruction (with confirmation)
.\scripts\windows\destroy.ps1 -Environment test

# Or via deploy script
.\scripts\windows\deploy.ps1 -Action destroy -Environment test
```

**Unix:**
```bash
# Safe destruction (with confirmation)
./scripts/unix/destroy.sh -e test

# Skip confirmation (use with caution!)
./scripts/unix/destroy.sh -e test --auto-approve
```

### Manual Terragrunt Destroy

```bash
cd terraform/live/test

# Destroy in reverse dependency order
# Step 1: AKS (has dependencies)
terragrunt destroy --terragrunt-working-dir aks --auto-approve

# Step 2: KeyVault (depends on others)
terragrunt destroy --terragrunt-working-dir keyvault --auto-approve

# Step 3: Independent modules
terragrunt destroy --terragrunt-working-dir monitoring --auto-approve
terragrunt destroy --terragrunt-working-dir network --auto-approve
terragrunt destroy --terragrunt-working-dir sql --auto-approve

# Or destroy all at once (let Terragrunt handle order)
terragrunt run-all destroy --terragrunt-parallelism 1
```

### Clean Up Storage Account (Optional)

After destroying infrastructure, you may want to delete the backend storage:

```bash
# Delete storage account
az storage account delete \
  --name YOUR_STORAGE_ACCOUNT \
  --resource-group test-rg \
  --yes

# Delete resource group
az group delete --name test-rg --yes
```

⚠️ **Warning:** Deleting the storage account will permanently delete all Terraform state files!

---

## 🆘 Troubleshooting

### Issue: "State lock" errors

**Cause:** Previous operation didn't release lock properly

**Solution:**
```bash
cd terraform/live/test

# Force unlock (use lock ID from error message)
terragrunt force-unlock LOCK_ID_FROM_ERROR

# For specific module
terragrunt force-unlock LOCK_ID --terragrunt-working-dir monitoring
```

### Issue: "HTTP response was nil" or Azure API errors

**Cause:** Transient Azure API connectivity issues

**Solution:**
- Wait a minute and retry
- Check Azure service health: https://status.azure.com
- Use deployment scripts which include retry logic

### Issue: "Error: Backend initialization required"

**Cause:** Terraform backend not initialized

**Solution:**
```bash
cd terraform/live/test

# Initialize backend
terragrunt init

# Or for all modules
terragrunt run-all init
```

### Issue: Changes not being detected

**Cause:** Stale `.terragrunt-cache` directories

**Solution:**
```bash
cd terraform/live/test

# Clean terragrunt cache
Get-ChildItem -Directory | ForEach-Object { 
    Remove-Item -Path "$($_.Name)/.terragrunt-cache" -Recurse -Force -ErrorAction SilentlyContinue 
}

# Or on Unix
find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;

# Re-initialize
terragrunt run-all init
```

### Issue: "InvalidResourceLocation" errors

**Cause:** Resource name conflicts or region restrictions

**Solution:**
```bash
# Check existing resources
az resource list --resource-group test-rg

# Delete conflicting resource
az resource delete --ids /subscriptions/.../resourceGroups/test-rg/providers/.../resources/name

# Or choose different location
# Edit terragrunt.hcl and change location to "westus2"
```

### Issue: Authentication errors

**Cause:** Expired credentials or missing environment variables

**Solution:**
```bash
# Re-login to Azure
az login

# Verify credentials
az account show

# Check environment variables (Windows)
Get-ChildItem Env:ARM_*

# Check environment variables (Unix)
env | grep ARM_

# Reset environment variables
.\scripts\windows\set-azure-creds.ps1  # Windows
source ~/.bashrc  # Unix
```

### Issue: Module dependency errors

**Cause:** Modules applied out of order

**Solution:**
Use the `-FirstDeploy` flag with deployment scripts, or follow manual dependency order:
1. monitoring, network, sql
2. keyvault
3. aks

### Issue: Can't access kubeconfig

**Cause:** Kubeconfig file generated in cache directory

**Solution:**
```bash
cd terraform/live/test

# Find kubeconfig
$kubeconfigPath = Get-ChildItem -Path "aks\.terragrunt-cache" -Recurse -Filter "kubeconfig-*.yaml" | Select-Object -First 1

# Copy to accessible location
Copy-Item $kubeconfigPath.FullName -Destination "..\..\kubeconfig-test.yaml"

# Use kubeconfig
$env:KUBECONFIG = "..\..\kubeconfig-test.yaml"
kubectl get nodes

# Or get credentials from Azure
az aks get-credentials --resource-group test-rg --name cai-aks-test
```

---

## 📚 Useful Commands

### Terraform/Terragrunt

```bash
# Show current state
terragrunt show

# List resources in state
terragrunt state list

# View specific resource
terragrunt state show azurerm_kubernetes_cluster.aks

# Import existing resource
terragrunt import azurerm_resource_group.rg /subscriptions/.../resourceGroups/test-rg

# Refresh state
terragrunt refresh

# Validate configuration
terragrunt validate

# Format code
terragrunt fmt -recursive
```

### Azure CLI

```bash
# List all resources in resource group
az resource list --resource-group test-rg -o table

# Show specific resource
az resource show --ids /subscriptions/.../resourceGroups/test-rg/providers/.../name

# Check storage account
az storage account show --name YOUR_STORAGE_ACCOUNT --resource-group test-rg

# List blobs (state files)
az storage blob list --account-name YOUR_STORAGE_ACCOUNT --container-name tfstate --auth-mode login

# Check AKS cluster
az aks show --resource-group test-rg --name cai-aks-test

# Get AKS credentials
az aks get-credentials --resource-group test-rg --name cai-aks-test

# Check quota usage
az vm list-usage --location westus2 -o table
```

---

## 🎓 Best Practices

### 1. Always Plan Before Apply

```bash
# Always review what will change
terragrunt plan --terragrunt-working-dir monitoring

# Then apply
terragrunt apply --terragrunt-working-dir monitoring
```

### 2. Use Version Control

```bash
# Create feature branch for changes
git checkout -b feature/my-change

# Commit frequently
git add .
git commit -m "Descriptive message"

# Push to remote
git push origin feature/my-change
```

### 3. Test in Lower Environments First

```
Changes → test environment → dev environment → prod environment
```

### 4. Keep State Files Secure

- Never commit state files to Git
- Use secure storage (Azure Storage with encryption)
- Limit access to state storage
- Enable versioning on storage account

### 5. Document Your Changes

- Add comments to Terragrunt files
- Update README when adding new modules
- Document any manual steps required

---

## 📖 Additional Resources

### Project Documentation
- **README.md** - GitHub Actions CI/CD pipeline setup
- **terraform/README.md** - Backend storage setup
- **terraform/modules/*/README.md** - Module-specific documentation

### External Resources
- [Terraform Documentation](https://www.terraform.io/docs)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/)
- [Azure Terraform Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure CLI Documentation](https://learn.microsoft.com/en-us/cli/azure/)

---

## 🎉 Quick Reference

### First Time Setup
```bash
1. Install tools (Azure CLI, Terraform, Terragrunt)
2. Clone repository
3. Login to Azure (az login)
4. Create backend storage account
5. Update storage account name in terragrunt.hcl
6. Run first deployment with -FirstDeploy flag
```

### Daily Development
```bash
1. git checkout -b feature/my-change
2. Make infrastructure changes
3. cd terraform/live/test
4. terragrunt plan --terragrunt-working-dir MODULE_NAME
5. terragrunt apply --terragrunt-working-dir MODULE_NAME
6. Verify in Azure Portal
7. git commit & push
8. Create PR for review
```

### Clean Up
```bash
1. .\scripts\windows\destroy.ps1 -Environment test
2. Verify resources deleted in Azure Portal
3. Optionally delete storage account
```

**Happy Infrastructure Coding! 🚀**
