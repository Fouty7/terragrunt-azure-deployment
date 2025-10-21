# 🏗️ Azure Infrastructure with Terraform & Terragrunt

A production-ready, multi-environment Azure infrastructure setup using Terraform modules and Terragrunt for DRY configuration management.

## 🎯 What This Repo Provides

- **Multi-environment** infrastructure (test, dev, prod)
- **Azure Kubernetes Service (AKS)** with monitoring integration
- **Azure Key Vault** for secrets management
- **Azure SQL Database** for data persistence
- **Monitoring stack** (Log Analytics + Application Insights)
- **Automated deployment scripts** with retry logic
- **Dependency management** between modules

## 📋 Prerequisites

### Required Tools
1. **[Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)** (latest version)
2. **[Terraform](https://www.terraform.io/downloads)** (>= 1.3.0)
3. **[Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/)** (latest version)
4. **PowerShell** (for automation scripts)

### Azure Setup
- Active Azure subscription
- Appropriate permissions to create resources and service principals

---

## 🚀 Quick Start (First Time Setup)

### 1. Clone and Setup

```bash
git clone <your-repo-url>
cd Azure-Environment-Terraform/terraform
```

### 2. Azure Authentication

```bash
# Login to Azure
az login

# Verify subscription
az account show

# Set subscription if needed
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 3. Create Azure Backend (One-time)

**Option A: Automated Setup**
```powershell
.\az-tf-backend.ps1
```

**Option B: Manual Setup**
```powershell
# Set variables
$ResourceGroupName = "test-rg"
$StorageAccountName = "tfbackend$(Get-Random)"  # Must be globally unique
$Location = "westus2"  # Use westus2 to avoid SQL provisioning restrictions

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

# Create container
az storage container create `
  --name "tfstate" `
  --account-name $StorageAccountName `
  --auth-mode login
```

### 4. Create Service Principal

```bash
# Create service principal with Contributor role
az ad sp create-for-rbac --name "terragrunt-sp" --role="Contributor" --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"

# Grant User Access Administrator role (needed for KeyVault role assignments)
az role assignment create --assignee "SERVICE_PRINCIPAL_CLIENT_ID" --role "User Access Administrator" --scope "/subscriptions/YOUR_SUBSCRIPTION_ID"
```

**Save the output securely! You'll need:**
- `appId` (Client ID)
- `password` (Client Secret)  
- `tenant` (Tenant ID)
- Your `subscription ID`

### 5. Set Azure Credentials

```powershell
# Windows - Run the credential setup script
.\scripts\windows\set-azure-creds.ps1
```

Or set environment variables manually:
```powershell
$env:ARM_SUBSCRIPTION_ID = "your-subscription-id"
$env:ARM_CLIENT_ID = "your-client-id" 
$env:ARM_CLIENT_SECRET = "your-client-secret"
$env:ARM_TENANT_ID = "your-tenant-id"
```

### 6. Update Configuration

Edit `terraform/live/test/terragrunt.hcl` with your storage account name:

```hcl
locals {
  storage_account_name = "your-storage-account-name"  # Update this
  container_name       = "tfstate"
  # Other settings...
}
```

### 7. Deploy Infrastructure

**Cross-Platform (Recommended):**
```bash
# First deployment (handles dependencies)
./scripts/deploy -a apply -e test -f

# Subsequent deployments  
./scripts/deploy -a plan -e test
./scripts/deploy -a apply -e test
```

**Windows (PowerShell):**
```powershell
.\scripts\windows\deploy.ps1 -Action apply -Environment test -FirstDeploy
.\scripts\windows\deploy.ps1 -Action plan -Environment test
```

**mac-linux/Linux/macOS (Bash):**
```bash
./scripts/mac-linux/deploy.sh -a apply -e test -f
./scripts/mac-linux/deploy.sh -a plan -e test
```

---

## 🏗️ Project Structure

```
terraform/
├── modules/              # Reusable Terraform modules
│   ├── aks/             # Azure Kubernetes Service
│   ├── keyvault/        # Azure Key Vault
│   ├── monitoring/      # Log Analytics + App Insights  
│   ├── network/         # Virtual Network (future)
│   ├── sql/             # Azure SQL Database
│   └── storage/         # Storage accounts (future)
├── live/                # Environment-specific configs
│   ├── test/            # Test environment
│   │   ├── terragrunt.hcl    # Environment config
│   │   ├── aks/              # AKS configuration
│   │   ├── keyvault/         # KeyVault configuration
│   │   ├── monitoring/       # Monitoring configuration
│   │   └── sql/              # SQL configuration
│   ├── dev/             # Development environment  
│   └── prod/            # Production environment
└── scripts/             # Cross-platform automation scripts
    ├── deploy               # Cross-platform deployment wrapper
    ├── destroy              # Cross-platform destroy wrapper  
    ├── windows/             # Windows-specific scripts
    │   ├── deploy.ps1       # PowerShell deployment script
    │   ├── destroy.ps1      # PowerShell destroy script
    │   └── set-azure-creds.ps1  # Credential setup
    └── mac-linux/                # mac-linux/Linux/macOS scripts
        ├── deploy.sh        # Bash deployment script
        └── destroy.sh       # Bash destroy script
```

## 📦 Infrastructure Components

| Component | Purpose | Dependencies |
|-----------|---------|--------------|
| **Monitoring** | Log Analytics Workspace + Application Insights for observability | None |
| **KeyVault** | Centralized secrets management with RBAC | None |  
| **SQL Database** | Azure SQL Server + Database for data persistence | None |
| **AKS Cluster** | Kubernetes cluster with monitoring integration | Monitoring |

## 🔧 Available Scripts

### Deployment Scripts

**Cross-Platform Scripts (Recommended)**
```bash
# First time deployment (handles dependencies)
./scripts/deploy -a apply -e test -f

# Plan changes
./scripts/deploy -a plan -e test

# Apply changes  
./scripts/deploy -a apply -e test
```

**Destruction Scripts**

*Cross-Platform:*
```bash
# Safe destruction (with confirmation)
./scripts/destroy -e test

# Automated destruction (for CI/CD)
./scripts/destroy -e test --auto-approve
```

*Platform-Specific:*
```powershell
# Windows
.\scripts\windows\destroy.ps1 -Environment test
```
```bash
# mac-linux/Linux/macOS  
./scripts/mac-linux/destroy.sh -e test
```

### Manual Commands (Advanced)

```powershell
# Navigate to environment
cd live\test

# Individual module operations
terragrunt plan --terragrunt-working-dir monitoring
terragrunt apply --terragrunt-working-dir monitoring

# All modules (use with caution)
terragrunt run-all plan --terragrunt-parallelism 1
terragrunt run-all apply --terragrunt-parallelism 1
```

---

## 🔐 Security & Best Practices

### Secrets Management
- All sensitive data stored in Azure Key Vault
- Service principal credentials via environment variables
- No secrets in source code

### Access Control
- Service principal with minimal required permissions
- RBAC enabled on Key Vault
- Resource-level access controls

### State Management  
- Remote state in Azure Storage with encryption
- Unique state files per module for isolation
- State locking to prevent concurrent modifications

---

## 🛠️ Troubleshooting Guide

### Common Issues

#### **"ProvisioningDisabled" for SQL Server**
**Cause:** Regional restrictions on SQL provisioning
**Solution:** Use `westus2` region instead of `eastus`

```hcl
# In terragrunt.hcl
locals {
  location = "westus2"  # Change from eastus
}
```

#### **"State lock" Errors**
**Cause:** Previous operations didn't release locks properly
**Solution:** Force unlock with the lock ID from error message

```powershell
terragrunt force-unlock LOCK_ID_FROM_ERROR
```

#### **"HTTP response was nil" Errors**
**Cause:** Azure API connectivity issues
**Solution:** Use deployment scripts with retry logic, or wait and retry

#### **"InvalidResourceLocation" Errors**
**Cause:** Resource name conflicts across regions
**Solution:** Change resource names or clean up conflicting resources

```bash
# Check for existing resources
az resource list --resource-group test-rg

# Clean up if needed
az resource delete --ids "/subscriptions/.../resourceGroups/test-rg/providers/..."
```

#### **Permission Denied for Role Assignments**
**Cause:** Service principal lacks "User Access Administrator" role
**Solution:** Grant additional permissions

```bash
az role assignment create --assignee "SERVICE_PRINCIPAL_CLIENT_ID" --role "User Access Administrator" --scope "/subscriptions/SUBSCRIPTION_ID"
```

### Dependency Issues

#### **AKS Gets "mock-workspace-id" Error**
**Cause:** Monitoring module not applied first
**Solution:** Use `deploy.ps1 -FirstDeploy` or apply monitoring manually first

#### **Module Dependencies**
```
Monitoring (independent) → AKS (dependent)
KeyVault (independent)
SQL (independent)
```

### Performance Optimization

#### **Slow Deployments**
- Use `--terragrunt-parallelism 1` to avoid API throttling
- Deploy independent modules in parallel when possible
- Use `westus2` region for better SQL provisioning reliability

#### **Large State Files**
- Each module has separate state files for faster operations
- Clean `.terragrunt-cache` directories if needed:
```powershell
Get-ChildItem -Directory | ForEach-Object { Remove-Item -Path "$($_.Name)/.terragrunt-cache" -Recurse -Force -ErrorAction SilentlyContinue }
```

---

## 🔄 Development Workflow

### Adding New Environments

1. **Copy environment structure:**
```bash
cp -r live/test live/dev
```

2. **Update environment-specific values:**
```hcl
# live/dev/terragrunt.hcl
locals {
  env = "dev"
  # Update other environment-specific settings
}
```

3. **Deploy:**
```powershell
.\scripts\deploy.ps1 -Action apply -Environment dev -FirstDeploy
```

### Adding New Modules

1. **Create module in `modules/` directory**
2. **Add to environment in `live/ENV/` directory**  
3. **Update dependencies in `deploy.ps1` if needed**
4. **Test with plan first:**
```powershell
terragrunt plan --terragrunt-working-dir live/test/new-module
```

---

## 🆘 Getting Help

### Error Analysis
1. **Check Azure Portal** for resource status
2. **Review Terraform logs** for detailed error messages  
3. **Use Azure CLI** to investigate resource states
4. **Check quotas** in Azure Portal → Subscriptions → Usage + quotas

### Support Channels
- **Internal:** Contact DevOps team
- **Issues:** Create GitHub issue with error logs
- **Azure Support:** For quota/billing issues

### Useful Commands
```bash
# Check resource group contents
az resource list --resource-group test-rg -o table

# Check quotas
az vm list-usage --location westus2 -o table

# Validate template
az deployment group validate --resource-group test-rg --template-file template.json

# Check service health
az resource health list --resource-group test-rg
```

**Happy Infrastructure as Code! 🚀**