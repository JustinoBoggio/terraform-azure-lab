# Variables to be used in the Terraform configuration for the Azure lab environment

variable "sql_admin_login" {
  type        = string
  description = "Administrator login for the dev SQL server."
  default     = "sqladmindev"
}