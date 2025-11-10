#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# SYNOPSIS
#   Setup Terraform backend on Azure.
#
# DESCRIPTION
#   This script creates a Resource Group, registers the Storage provider,
#   creates a Storage Account, and a Blob container for storing Terraform state.
#
# NOTES
#   Author: Your Name
#   Date: 2025-10-19
# -----------------------------------------------------------------------------

set -euo pipefail

# -----------------------------
# Configuration
# -----------------------------
RESOURCE_GROUP_NAME="test-rg"             # Name of the Resource Group
LOCATION="eastus"                         # Azure region
RANDOM_SUFFIX=$((RANDOM % 9000 + 1000))
STORAGE_ACCOUNT_NAME="tfbackend${RANDOM_SUFFIX}"  # Must be lowercase, globally unique
CONTAINER_NAME="tfstate"                  # Blob container name for Terraform state

# -----------------------------
# Step 1: Check Azure login
# -----------------------------
echo "🔍 Checking Azure login status..."
if ! az account show &>/dev/null; then
  echo "⚠️  You are not logged in. Logging in now..."
  az login >/dev/null
fi

ACCOUNT_ID=$(az account show --query id -o tsv)
ACCOUNT_NAME=$(az account show --query name -o tsv)
echo "✅ Logged in to Azure Subscription: ${ACCOUNT_ID} (${ACCOUNT_NAME})"

# -----------------------------
# Step 2: Create Resource Group
# -----------------------------
echo "📦 Creating Resource Group '${RESOURCE_GROUP_NAME}' in location '${LOCATION}'..."
az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION" >/dev/null
echo "✅ Resource Group created successfully."

# -----------------------------
# Step 3: Register Storage Provider
# -----------------------------
echo "🔧 Registering Microsoft.Storage provider..."
az provider register --namespace Microsoft.Storage >/dev/null

# Wait until registration completes
echo "⏳ Waiting for Microsoft.Storage registration to complete..."
while true; do
  STATE=$(az provider show --namespace Microsoft.Storage --query "registrationState" -o tsv)
  echo "   Current registration state: $STATE"
  [[ "$STATE" == "Registered" ]] && break
  sleep 5
done
echo "✅ Storage provider registered successfully."

# -----------------------------
# Step 4: Create Storage Account
# -----------------------------
echo "💾 Creating Storage Account '${STORAGE_ACCOUNT_NAME}'..."
az storage account create \
  --name "$STORAGE_ACCOUNT_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --encryption-services blob >/dev/null

echo "✅ Storage Account created successfully."

# -----------------------------
# Step 5: Wait for DNS propagation
# -----------------------------
echo "🌐 Waiting 60 seconds for DNS propagation..."
sleep 60

# -----------------------------
# Step 6: Create Blob Container
# -----------------------------
echo "🧱 Creating Blob container '${CONTAINER_NAME}'..."
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --auth-mode login >/dev/null

echo "✅ Blob container created successfully."

# -----------------------------
# Step 7: Summary
# -----------------------------
echo -e "\n🎉 Terraform backend setup complete!"
echo "---------------------------------------"
echo "Resource Group:      ${RESOURCE_GROUP_NAME}"
echo "Storage Account:     ${STORAGE_ACCOUNT_NAME}"
echo "Container:           ${CONTAINER_NAME}"
echo -e "---------------------------------------\n"

echo "You can now configure your Terraform backend as follows:"
cat <<EOF

terraform {
  backend "azurerm" {
    resource_group_name  = "${RESOURCE_GROUP_NAME}"
    storage_account_name = "${STORAGE_ACCOUNT_NAME}"
    container_name       = "${CONTAINER_NAME}"
    key                  = "terraform.tfstate"
  }
}
EOF
