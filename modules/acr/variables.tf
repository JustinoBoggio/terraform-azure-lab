variable "name" {
  type        = string
  description = "ACR name. Must be globally unique, 5-50 characters, alphanumeric only"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where the ACR will be created"
}

variable "location" {
  type        = string
  description = "Azure region for the ACR"
}

variable "sku" {
  type        = string
  description = "ACR SKU (Basic, Standard, Premium)"
  default     = "Basic"
}

variable "admin_enabled" {
  type        = bool
  description = "Whether the admin user is enabled for the ACR"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the ACR"
  default     = {}
}

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed for the container registry"
  type        = bool
  default     = true
}