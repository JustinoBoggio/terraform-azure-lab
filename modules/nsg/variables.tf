variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region location"
  type        = string
}

variable "name" {
  description = "Name of the Network Security Group"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet to associate this NSG with"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "security_rules" {
  description = "List of security rules to apply inline (required for App Gateway subnets to pass validation)"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = []
}