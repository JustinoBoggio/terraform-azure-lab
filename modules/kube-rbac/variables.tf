variable "environment" {
  type        = string
  description = "Environment name, for example dev or uat"
}

variable "namespace" {
  type        = string
  description = "Target namespace for RBAC objects"
}

variable "owner" {
  type        = string
  description = "Owner label for Kubernetes resources"
}