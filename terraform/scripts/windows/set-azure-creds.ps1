# ===============================================
# Script: set-azure-creds.ps1
# Purpose: Set Azure authentication environment variables
# for Terraform/Terragrunt usage in PowerShell.
# ===============================================

Write-Host "`nSetting Azure credentials for Terraform/Terragrunt..." -ForegroundColor Cyan

# Prompt for values if not already set
if (-not $env:ARM_SUBSCRIPTION_ID) {
    $env:ARM_SUBSCRIPTION_ID = Read-Host "Enter your Azure Subscription ID"
}
if (-not $env:ARM_CLIENT_ID) {
    $env:ARM_CLIENT_ID = Read-Host "Enter your Azure Service Principal (Client) ID"
}
if (-not $env:ARM_CLIENT_SECRET) {
    $env:ARM_CLIENT_SECRET = Read-Host "Enter your Azure Service Principal Client Secret"
}
if (-not $env:ARM_TENANT_ID) {
    $env:ARM_TENANT_ID = Read-Host "Enter your Azure Tenant ID"
}

# Optional region override
if (-not $env:ARM_REGION) {
    $env:ARM_REGION = "EastUS"
}

# Display what’s set
Write-Host "`nEnvironment variables set:" -ForegroundColor Yellow
Write-Host "  ARM_SUBSCRIPTION_ID : $env:ARM_SUBSCRIPTION_ID"
Write-Host "  ARM_CLIENT_ID       : $env:ARM_CLIENT_ID"
Write-Host "  ARM_TENANT_ID       : $env:ARM_TENANT_ID"
Write-Host "  ARM_REGION          : $env:ARM_REGION"

# Confirm for user
Write-Host "`n✅ Azure credentials configured successfully for this session." -ForegroundColor Green
Write-Host "You can now run:  terragrunt init  or  terragrunt apply"
