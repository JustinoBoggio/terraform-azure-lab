variable "name" {
  type        = string
  description = "Diagnostic settings name"
}

variable "target_resource_id" {
  type        = string
  description = "Resource id where diagnostic settings will be attached"
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace id"
}

variable "logs" {
  description = "List of log categories to enable"
  type = list(object({
    category = string
    enabled  = bool
  }))
  default = []
}

variable "metrics" {
  description = "List of metric categories to enable"
  type = list(object({
    category = string
    enabled  = bool
  }))
  default = []
}