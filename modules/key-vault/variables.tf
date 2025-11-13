variable "name" {
  type        = string
  description = "Name of the Key Vault"
}

variable "location" {
  type        = string
  description = "Azure region where the Key Vault will be created"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group where the Key Vault will be created"
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID that will own the Key Vault"
}

variable "sku_name" {
  type        = string
  description = "SKU for the Key Vault (standard or premium)"
  default     = "standard"
}

variable "soft_delete_retention_days" {
  type        = number
  description = "Number of days to retain soft deleted secrets"
  default     = 7
}

variable "purge_protection_enabled" {
  type        = bool
  description = "Whether purge protection is enabled for the Key Vault"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the Key Vault"
  default     = {}
}
