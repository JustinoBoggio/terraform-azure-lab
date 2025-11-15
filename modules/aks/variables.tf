variable "name" {
  type        = string
  description = "AKS cluster name"
}

variable "location" {
  type        = string
  description = "Azure region for the cluster"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where AKS will be created"
}

variable "dns_prefix" {
  type        = string
  description = "DNS prefix for the AKS API server"
}

variable "subnet_id" {
  type        = string
  description = "Subnet id where AKS nodes will be placed"
}

variable "vnet_id" {
  type        = string
  description = "Virtual network id for role assignment"
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace id for AKS monitoring"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for the cluster"
  default     = "1.29.2"
}

variable "node_count" {
  type        = number
  description = "Base node count for the system node pool"
  default     = 1
}

variable "node_vm_size" {
  type        = string
  description = "VM size for the system node pool"
  default     = "Standard_DC2s_v3"
}

variable "enable_auto_scaling" {
  type        = bool
  description = "Enable autoscaling on the system node pool"
  default     = false
}

variable "min_count" {
  type        = number
  description = "Minimum node count when autoscaling is enabled"
  default     = 1
}

variable "max_count" {
  type        = number
  description = "Maximum node count when autoscaling is enabled"
  default     = 2
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the AKS resources"
  default     = {}
}
