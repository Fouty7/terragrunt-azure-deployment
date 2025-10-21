# terraform/live/test/variables.tf
variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig for the environment"
  default     = "${path.module}/kubeconfig.yaml"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name for the environment"
  default     = "mycai_test-rg"
}

variable "storage_account_name" {
  type        = string
  description = "Storage account for Terraform backend"
  default     = "tfstatetestcai"
}

variable "container_name" {
  type        = string
  description = "Blob container for Terraform backend"
  default     = "tfstatetestcai"
}
