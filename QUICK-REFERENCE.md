# 🚀 Quick Reference - Azure Infrastructure

## 🎯 Daily Commands

### Deploy Infrastructure

Always run commands from terraform folder ```cd terraform```

```bash
cd terraform

# Cross-platform commands (works on Windows, Mac, Linux)
./scripts/deploy -a plan -e test               # Plan changes
./scripts/deploy -a apply -e test              # Apply changes
./scripts/deploy -a apply -e test -f           # First time setup
```

### Destroy Infrastructure
```bash
# Cross-platform commands
./scripts/destroy -e test                      # Safe destroy (with confirmation)
./scripts/destroy -e test --auto-approve       # Automated destroy
```

### Platform-Specific (if needed)
```powershell
# Windows PowerShell
.\scripts\windows\deploy.ps1 -Action plan -Environment test
.\scripts\windows\destroy.ps1 -Environment test
```
```bash
# mac-linux/Linux/macOS Bash
./scripts/mac-linux/deploy.sh -a plan -e test
./scripts/mac-linux/destroy.sh -e test
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
└── scripts/            # Cross-platform deployment scripts
    ├── deploy          # Cross-platform deploy wrapper
    ├── destroy         # Cross-platform destroy wrapper
    ├── windows/        # PowerShell scripts (Windows)
    └── mac-linux/           # Bash scripts (Mac/Linux)
```

## 📦 Components Created
- **AKS Cluster**: `cai-aks-test`
- **SQL Server**: `cai-aks-test-v2-sql` 
- **KeyVault**: `cai-test-kv`
- **Monitoring**: `cai-aks-test-logs` + `cai-aks-test-insights`

## ⚠️ Common Gotchas

1. **Always run from `terraform/` directory**
2. **Use `westus2` region (not eastus)**  
3. **First deployments need `-f` flag (mac-linux) or `-FirstDeploy` flag (Windows)**
4. **State locks need manual cleanup if interrupted**
5. **Cross-platform scripts work on all OS - use them for consistency**

## 🆘 Emergency Contacts
- DevOps Team: [contact info]
- Azure Support: [support info]
- Documentation: See main README.md