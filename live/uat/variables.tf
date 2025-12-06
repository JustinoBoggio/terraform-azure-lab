# Variables to be used in the Terraform configuration for the Azure lab environment

variable "sql_admin_login" {
  type        = string
  description = "Administrator login for the dev SQL server."
  default     = "sqladmindev"
}

variable "ssh_source_ip" {
  description = "IP allowed to SSH"
  type        = string
}

variable "admin_object_id" {
  description = "Object ID of the Azure Administrator (Justino)"
  type        = string
}

variable "pipeline_client_id" {
  description = "Client ID of the Azure DevOps Pipeline Service Principal"
  type        = string
}