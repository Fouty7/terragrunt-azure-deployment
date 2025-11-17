# 🇺🇸 Azure US Government Cloud Configuration Guide

**Error**: `AADSTS900382: Confidential Client is not supported in Cross Cloud request`

**Cause**: Your Service Principal and resources are in **Azure US Government Cloud**, but Terraform is defaulting to **Azure Public Cloud** endpoints.

---

## ✅ Required Changes

### **1. Update Environment Terragrunt Configuration**

**File**: `terraform/live/test/terragrunt.hcl` (or dev/prod)

#### **A. Update Remote State Backend**

**Location**: Lines 21-30

**Current**:
```hcl
remote_state {
  backend = "azurerm"
  config = {
    resource_group_name  = local.resource_group_name
    storage_account_name = local.storage_account_name
    container_name       = local.container_name
    key                  = "${path_relative_to_include()}/terraform.tfstate"
  }
}
```

**Change to**:
```hcl
remote_state {
  backend = "azurerm"
  config = {
    resource_group_name  = local.resource_group_name
    storage_account_name = local.storage_account_name
    container_name       = local.container_name
    key                  = "${path_relative_to_include()}/terraform.tfstate"
    environment          = "usgovernment"  # ← ADD THIS LINE
  }
}
```

#### **B. Update Provider Configuration**

**Location**: Lines 50-59 (inside the `generate "provider"` block)

**Current**:
```hcl
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
```

**Change to**:
```hcl
provider "azurerm" {
  environment = "usgovernment"  # ← ADD THIS LINE
  
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
```

---

### **2. Update Azure CLI Configuration (Local Development)**

If running Terraform locally, switch Azure CLI to US Government cloud:

```powershell
# Switch to Azure US Government
az cloud set --name AzureUSGovernment

# Login to US Government cloud
az login

# Verify you're in the correct cloud
az cloud show

# List subscriptions
az account list --output table

# Set the correct subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

**To switch back to public cloud later**:
```powershell
az cloud set --name AzureCloud
```
---

### **4. Verify Service Principal Scope**

Ensure your Service Principal was created in Azure US Government cloud:

```powershell
# Switch to US Government cloud
az cloud set --name AzureUSGovernment
az login

# Verify service principal exists
az ad sp show --id "YOUR_CLIENT_ID"

```
---

## 📋 Complete Checklist

### **Files to Update**:
- [ ] `terraform/live/test/terragrunt.hcl` - Add `environment = "usgovernment"` to:
  - [ ] `remote_state` config block
  - [ ] `provider "azurerm"` block
- [ ] `terraform/live/dev/terragrunt.hcl` (if exists) - Same changes
- [ ] `terraform/live/prod/terragrunt.hcl` (if exists) - Same changes


### **Local Environment**:
- [ ] Switch Azure CLI to US Government: `az cloud set --name AzureUSGovernment`
- [ ] Login: `az login`
- [ ] Verify subscription: `az account show`

---

## 🧪 Testing After Changes

### **1. Test Remote State Connection**:
```powershell
cd terraform/live/test
terragrunt init
```

Should succeed without authentication errors.

### **2. Test Provider Configuration**:
```powershell
cd terraform/live/test/network
terragrunt init
terragrunt plan
```

Should connect to US Government endpoints.

---

## 🚨 Common Issues & Solutions

### **Issue 1**: "Storage account not found"
**Cause**: Storage account name is for Public Cloud, not US Gov  
**Solution**: Verify storage account exists in US Government portal (portal.azure.us)

### **Issue 2**: "Subscription not found"
**Cause**: Using Public Cloud subscription ID  
**Solution**: Get subscription ID from US Government: `az account show` (after `az cloud set --name AzureUSGovernment`)

### **Issue 4**: "Invalid tenant"
**Cause**: Tenant ID is from Public Cloud  
**Solution**: Get US Gov tenant ID: `az account show --query tenantId -o tsv` (in US Gov cloud)

---

## 🎉 Summary

**Two Key Changes**:
1. Add `environment = "usgovernment"` to Terragrunt configs (2 places per environment)
2. Use `az cloud set --name AzureUSGovernment` to switch to US Government cloud

**Result**: Terraform will use correct US Government endpoints and authentication will work! ✅