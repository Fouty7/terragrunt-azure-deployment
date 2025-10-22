variable "cluster_name" {
  description = "Name of the AKS cluster (used for naming network resources)"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for network resources"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags for the network resources"
  type        = map(string)
  default     = {}
}