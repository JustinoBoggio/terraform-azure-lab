variable "name" {
  type        = string
  description = "Name of the Log Analytics workspace"
}

variable "location" {
  type        = string
  description = "Azure region where the workspace will be created"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group where the workspace will be created"
}

variable "sku" {
  type        = string
  description = "Pricing tier (SKU) for the Log Analytics workspace"
  default     = "PerGB2018"
}

variable "retention_in_days" {
  type        = number
  description = "Number of days to retain logs in the workspace"
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the workspace"
  default     = {}
}
