variable "environment" {
  type = string
}

variable "owner" {
  type = string
}

variable "namespace" {
  type    = string
  default = "monitoring"
}

variable "grafana_admin_user" {
  type    = string
  default = "admin"
}

variable "grafana_admin_password" {
  type    = string
  default = "ChangeMe123!"
}
