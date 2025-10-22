variable "cluster_name" {
  type        = string
  description = "Name of the AKS cluster"
  
}

variable "resource_group_name" {
  type        = string
  description = "Resource group in which AKS cluster will be created"
}

variable "location" {
  type        = string
  description = "Azure region for the cluster"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for AKS"
}

variable "node_count" {
  type        = number
  description = "Number of nodes in the default node pool"
}

variable "vm_size" {
  type        = string
  description = "VM size for nodes"
}

variable "enable_auto_scaling" {
  type        = bool
  description = "Enable autoscaling for the node pool"
}

variable "min_count" {
  type        = number
  description = "Minimum nodes if autoscaling enabled"
  default     = 1
}

variable "max_count" {
  type        = number
  description = "Maximum nodes if autoscaling enabled"
  default     = 3
}

variable "enable_monitoring" {
  type        = bool
  description = "Enable Azure Monitor for AKS"
  default     = true
}

variable "enable_rbac" {
  type        = bool
  description = "Enable RBAC for AKS"
  default     = true
}

variable "network_plugin" {
  type        = string
  description = "Network plugin to use for AKS"
  default     = "azure"
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics Workspace ID for monitoring"
  default     = null
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for the AKS cluster node pool"
  default     = null
}

variable "service_cidr" {
  type        = string
  description = "CIDR block for Kubernetes services"
  default     = "172.16.0.0/16"
}

variable "dns_service_ip" {
  type        = string
  description = "IP address within the service CIDR for DNS service"
  default     = "172.16.0.10"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the AKS cluster"
  default     = {}
}
