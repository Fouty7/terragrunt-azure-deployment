# 🚀 Quick Reference - Azure Infrastructure

## 🎯 Daily Commands

### Deploy Infrastructure
```powershell
# Plan changes
.\scripts\deploy-smart.ps1 -Action plan -Environment test

# Apply changes
.\scripts\deploy-smart.ps1 -Action apply -Environment test

# First time setup
.\scripts\deploy-smart.ps1 -Action apply -Environment test -FirstDeploy
```

### Destroy Infrastructure
```powershell
# Safe destroy (with confirmation)
.\scripts\destroy.ps1 -Environment test

# Automated destroy
.\scripts\destroy.ps1 -Environment test -AutoApprove
```

## 🔧 Troubleshooting Commands

### State Lock Issues
```powershell
# Find lock ID in error message, then:
terragrunt force-unlock LOCK_ID_FROM_ERROR
```

### Clean Caches
```powershell
Get-ChildItem -Directory | ForEach-Object { Remove-Item -Path "$($_.Name)/.terragrunt-cache" -Recurse -Force -ErrorAction SilentlyContinue }
```

### Check Resources
```bash
# List all resources
az resource list --resource-group test-rg -o table

# Check specific service
az sql server list --resource-group test-rg
az aks list --resource-group test-rg
```

## 🏗️ Project Structure
```
terraform/
├── live/test/          # Test environment configs
├── modules/            # Reusable modules
└── scripts/            # Deployment scripts
```

## 📦 Components Created
- **AKS Cluster**: `cai-aks-test`
- **SQL Server**: `cai-aks-test-v2-sql` 
- **KeyVault**: `cai-test-kv`
- **Monitoring**: `cai-aks-test-logs` + `cai-aks-test-insights`

## ⚠️ Common Gotchas

1. **Always run from `terraform/` directory**
2. **Use `westus2` region (not eastus)**
3. **First deployments need `-FirstDeploy` flag**
4. **State locks need manual cleanup if interrupted**

## 🆘 Emergency Contacts
- DevOps Team: [contact info]
- Azure Support: [support info]
- Documentation: See main README.md