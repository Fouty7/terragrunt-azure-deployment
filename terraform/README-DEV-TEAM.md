# 🚀 Infrastructure Deployment Guide

This repository contains Terragrunt configurations for managing Azure infrastructure across multiple environments.

## 🏗️ Architecture

```
terraform/
├── modules/           # Reusable Terraform modules
├── live/             # Environment-specific configurations
│   ├── test/         # Test environment
│   ├── dev/          # Development environment
│   └── prod/         # Production environment
└── scripts/          # Deployment utilities
```

## 🔧 Prerequisites

1. **Azure CLI**: Install and login with `az login`
2. **Terraform**: Version >= 1.3.0
3. **Terragrunt**: Latest version
4. **PowerShell**: For running deployment scripts

## 🎯 Quick Start

### For Development Team

**Plan infrastructure changes:**
```powershell
.\scripts\deploy.ps1 -Action plan -Environment test
```

**Apply infrastructure changes:**
```powershell
.\scripts\deploy.ps1 -Action apply -Environment test
```

**Destroy infrastructure (SAFE - with confirmation):**
```powershell
.\scripts\destroy.ps1 -Environment test
```

**Destroy infrastructure (DANGEROUS - no confirmation):**
```powershell
.\scripts\destroy.ps1 -Environment test -AutoApprove
```

### Manual Commands (Advanced Users)

If you prefer manual control:

```powershell
# Navigate to environment
cd live\test

# Plan all modules
terragrunt run-all plan --terragrunt-parallelism 1

# Apply all modules
terragrunt run-all apply --terragrunt-parallelism 1
```

## 📁 Modules Included

- **🔐 KeyVault**: Secrets management
- **📊 Monitoring**: Log Analytics + Application Insights  
- **🗄️ SQL**: Azure SQL Database
- **☸️ AKS**: Azure Kubernetes Service (depends on monitoring)

## 🔄 Module Dependencies

```
Monitoring → AKS
(All other modules are independent)
```

## ⚠️ Important Notes

1. **Sequential Execution**: Use `--terragrunt-parallelism 1` to avoid Azure API conflicts
2. **Authentication**: Ensure you're logged in with `az login` before running commands
3. **Unique State Files**: Each module has its own state file for isolation
4. **Retry Logic**: The deployment script includes automatic retry for Azure API issues

## 🛠️ Troubleshooting

### Common Issues

**"HTTP response was nil; connection may have been reset"**
- This is an Azure API intermittent issue
- Use the deployment script which includes retry logic
- Or manually retry the command after a few seconds

**"State lock" errors**
- Find the lock ID in the error message
- Run: `terragrunt force-unlock <LOCK_ID>`

**Provider installation conflicts**
- Clean caches: `Remove-Item -Path "*/.terragrunt-cache" -Recurse -Force`
- Re-run the command

**Destroy issues**
- Use the dedicated destroy script: `\scripts\destroy.ps1`
- It handles dependencies in reverse order (AKS first, then others)
- For stuck resources, destroy individual modules manually

## 📞 Support

For infrastructure issues, contact the DevOps team or create an issue in this repository.