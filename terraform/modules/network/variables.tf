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

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_address_prefixes" {
  description = "Address prefixes for the AKS subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "tags" {
  description = "Tags for the network resources"
  type        = map(string)
  default     = {}
}
