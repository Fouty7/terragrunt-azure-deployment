##########################################
# modules/keyvault/variables.tf
##########################################

variable "name" {
  description = "Name of the Key Vault"
  type        = string
}

variable "location" {
  description = "Azure region where the Key Vault will be deployed"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name where the Key Vault will be created"
  type        = string
}

variable "tenant_id" {
  description = "Tenant ID for the Key Vault (optional, defaults to current tenant)"
  type        = string
  default     = null
}

variable "soft_delete_retention_days" {
  description = "Soft delete retention in days"
  type        = number
  default     = 7
}

variable "purge_protection_enabled" {
  description = "Enable purge protection"
  type        = bool
  default     = false
}

variable "enable_rbac_authorization" {
  description = "Enable RBAC authorization for Key Vault"
  type        = bool
  default     = true
}

variable "default_secrets" {
  description = "Map of default secrets to create in the Key Vault"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
