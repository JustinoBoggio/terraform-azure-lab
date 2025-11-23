variable "name" {
  type        = string
  description = "Base name for the managed identity and federated credential"
}

variable "location" {
  type        = string
  description = "Azure region where the identity will be created"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for the managed identity"
}

variable "kubernetes_oidc_issuer_url" {
  type        = string
  description = "OIDC issuer URL of the AKS cluster"
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace of the service account"
}

variable "service_account_name" {
  type        = string
  description = "Kubernetes service account name"
}

variable "key_vault_id" {
  type        = string
  description = "Key Vault resource ID where this identity needs secrets access"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}
