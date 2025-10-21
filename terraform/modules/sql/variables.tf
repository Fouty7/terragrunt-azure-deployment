variable "cluster_name" {
  description = "Name of the AKS cluster (used for naming SQL Server)"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for the SQL Server"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "admin_username" {
  description = "Administrator username for SQL Server"
  type        = string
  default     = "testadmin"
}

variable "admin_password" {
  description = "Administrator password for SQL Server"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags for the resources"
  type        = map(string)
  default     = {}
}
