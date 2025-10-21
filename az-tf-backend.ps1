<#
.SYNOPSIS
    Setup Terraform backend on Azure.
.DESCRIPTION
    This script creates a Resource Group, registers the Storage provider, creates a Storage Account,
    and a Blob container for storing Terraform state.

.NOTES
    Author: Your Name
    Date: 2025-10-19
#>

# -----------------------------
# Configuration
# -----------------------------
$ResourceGroupName = "test-rg"           # Name of the Resource Group
$Location = "eastus"                     # Azure region
$StorageAccountName = "tfbackend$((Get-Random -Minimum 1000 -Maximum 9999))"  # Must be lowercase, globally unique
$ContainerName = "tfstate"               # Blob container name for Terraform state

# -----------------------------
# Step 1: Check Azure login
# -----------------------------
try {
    $account = az account show | ConvertFrom-Json
    Write-Host "Logged in to Azure Subscription: $($account.id) ($($account.name))"
} catch {
    Write-Host "You are not logged in. Logging in now..."
    az login
}

# -----------------------------
# Step 2: Create Resource Group
# -----------------------------
Write-Host "Creating Resource Group '$ResourceGroupName' in location '$Location'..."
az group create --name $ResourceGroupName --location $Location | Out-Null
Write-Host "Resource Group created successfully."

# -----------------------------
# Step 3: Register Storage Provider
# -----------------------------
Write-Host "Registering Microsoft.Storage provider..."
az provider register --namespace Microsoft.Storage | Out-Null

# Wait until registration completes
do {
    $state = az provider show --namespace Microsoft.Storage --query "registrationState" -o tsv
    Write-Host "Current registration state: $state"
    Start-Sleep -Seconds 5
} while ($state -ne "Registered")

Write-Host "Storage provider registered successfully."

# -----------------------------
# Step 4: Create Storage Account
# -----------------------------
Write-Host "Creating Storage Account '$StorageAccountName'..."
az storage account create `
    --name $StorageAccountName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --sku Standard_LRS `
    --kind StorageV2 `
    --encryption-services blob | Out-Null

Write-Host "Storage Account created successfully."

# -----------------------------
# Step 5: Wait for DNS propagation
# -----------------------------
Write-Host "Waiting 60 seconds for DNS propagation..."
Start-Sleep -Seconds 60

# -----------------------------
# Step 6: Create Blob Container
# -----------------------------
Write-Host "Creating Blob container '$ContainerName'..."
az storage container create `
    --name $ContainerName `
    --account-name $StorageAccountName `
    --auth-mode login | Out-Null

Write-Host "Blob container created successfully."

# -----------------------------
# Step 7: Summary
# -----------------------------
Write-Host "Terraform backend setup complete!"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Storage Account: $StorageAccountName"
Write-Host "Container: $ContainerName"
Write-Host "You can now configure your Terraform backend as follows:"
Write-Host @"
terraform {
  backend "azurerm" {
    resource_group_name  = "$ResourceGroupName"
    storage_account_name = "$StorageAccountName"
    container_name       = "$ContainerName"
    key                  = "terraform.tfstate"
  }
}
"@
