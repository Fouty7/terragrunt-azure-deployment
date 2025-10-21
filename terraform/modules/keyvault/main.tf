##########################################
# modules/keyvault/main.tf
##########################################

# Optional provider block is *not needed* since Terragrunt generates one.

data "azurerm_client_config" "current" {}

# ────────────────────────────────────────────────
# Key Vault creation
# ────────────────────────────────────────────────
resource "azurerm_key_vault" "this" {
  name                        = var.name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = var.tenant_id != null ? var.tenant_id : data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = var.soft_delete_retention_days
  purge_protection_enabled    = var.purge_protection_enabled
  rbac_authorization_enabled   = var.enable_rbac_authorization

  tags = var.tags
}

# ────────────────────────────────────────────────
# Role assignment for the current principal (optional but useful)
# ────────────────────────────────────────────────
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ────────────────────────────────────────────────
# Example secrets (optional - can be parameterized later)
# ────────────────────────────────────────────────
resource "azurerm_key_vault_secret" "default_secrets" {
  for_each = var.default_secrets

  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [azurerm_role_assignment.kv_admin]
}
