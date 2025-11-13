variable "name" {
  type        = string
  description = "Vnet name"
}

variable "address_space" {
  type        = list(string)
  description = "Vnet address space"
}

variable "resource_group_name" {
  type        = string
  description = "Vnet resource group name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "subnets" {
  description = "Subnets map"
  type = map(object({
    address_prefixes = list(string)
  }))
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the resources"
  default     = {}
}
