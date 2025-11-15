variable "environment" {
  type        = string
  description = "Environment name, for example dev or uat"
}

variable "owner" {
  type        = string
  description = "Owner label value for Kubernetes resources"
}