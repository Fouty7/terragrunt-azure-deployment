# Azure Terraform Backend Setup

This guide explains how to create an Azure Resource Group and a Storage Account to use as a Terraform remote backend. It includes commands for **PowerShell**, **Bash**, and **CMD** environments.


---

## **Pre-requisites**

1. Install [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (latest version recommended).
2. Ensure you are logged in to your Azure account:

N:B

You can run the automated scrip ```./az-tf-backend.ps1 ``` to get up and running with default values or edit the required fields

```bash
az login
```
## Check your default subscription:

```az account show```

## Set the subscription you want to use:

```az account set --subscription "YOUR_SUBSCRIPTION_ID"```

# Step 1: Create a Resource Group

### PowerShell
``` powershell
$ResourceGroupName = "test-rg"
$Location = "eastus"

# Create Resource Group
az group create --name $ResourceGroupName --location $Location
```

### Bash/CMD
```bash
RESOURCE_GROUP="test-rg"
LOCATION="eastus"

az group create --name $RESOURCE_GROUP --location $LOCATION


```
# Step 2: Register the Storage Resource Provider

Terraform backend requires a storage account, and the Microsoft.Storage provider must be registered.

### PowerShell / Bash / CMD

```shell
# Register Storage Provider
az provider register --namespace Microsoft.Storage

# Confirm registration
az provider show --namespace Microsoft.Storage --query "registrationState"
```

Expected output:
```"Registered"```

# Step 3: Create the Storage Account

Azure Storage Account names must be globally unique, lowercase, 3–24 characters.

# PowerShell
```powershell
$StorageAccountName = "tfbackend27a558b6" # < --- Replace with a unique name>
$ContainerName = "tfstate"

# Create Storage Account
az storage account create `
  --name $StorageAccountName `
  --resource-group $ResourceGroupName `
  --location $Location `
  --sku Standard_LRS `
  --kind StorageV2 `
  --encryption-services blob

# Create Blob Container for Terraform state
az storage container create `
  --name $ContainerName `
  --account-name $StorageAccountName `
  --auth-mode login

```

## CMD

```shell

set STORAGE_ACCOUNT=tfbackend27a558b6
set CONTAINER_NAME=tfstate

az storage account create --name %STORAGE_ACCOUNT% --resource-group test-rg --location eastus --sku Standard_LRS --kind StorageV2 --encryption-services blob

REM Wait 60 seconds for DNS propagation
timeout /t 60

az storage container create --name %CONTAINER_NAME% --account-name %STORAGE_ACCOUNT% --auth-mode login

```

## Bash

```bash
STORAGE_ACCOUNT="tfbackend27a558b6"
CONTAINER_NAME="tfstate"

az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2 \
  --encryption-services blob

# Wait for DNS propagation (optional)
sleep 60

az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT \
  --auth-mode login


```