variable "cluster_name" {
  type        = string
  description = "Name of the AKS cluster (used for naming resources)"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for monitoring resources"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}
