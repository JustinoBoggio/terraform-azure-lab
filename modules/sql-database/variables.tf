variable "server_name" {
  type        = string
  description = "Globally unique name for the Azure SQL server."
}

variable "database_name" {
  type        = string
  description = "Name of the Azure SQL database."
}

variable "location" {
  type        = string
  description = "Azure region where the SQL server and database will be created."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where SQL server and database will be created."
}

variable "administrator_login" {
  type        = string
  description = "Administrator login for the SQL server."
}

variable "administrator_login_password" {
  type        = string
  description = "Administrator password for the SQL server."
  sensitive   = true
}

variable "sku_name" {
  type        = string
  description = "SKU for the SQL database (for example Basic, S0, P1)."
  default     = "Basic"
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to all SQL resources."
  default     = {}
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Whether public network access is allowed for this SQL server"
  default     = true
}