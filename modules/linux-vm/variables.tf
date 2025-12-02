variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "name" {
  description = "Name of the VM"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the VM will be placed"
  type        = string
}

variable "vm_size" {
  description = "Size of the Virtual Machine"
  type        = string
  default     = "Standard_B2ats_v2"
}

variable "admin_username" {
  description = "Admin username for SSH"
  type        = string
  default     = "azureuser"
}

variable "public_key_content" {
  description = "The content of the SSH public key (string)"
  type        = string
}

variable "custom_data" {
  description = "Base64 encoded custom data (cloud-init script)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
}