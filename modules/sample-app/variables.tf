variable "environment" {
  type        = string
  description = "Environment name (dev, uat, etc)"
}

variable "owner" {
  type        = string
  description = "Owner label"
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace where the app will be deployed"
}

variable "app_name" {
  type        = string
  description = "Application name"
}

variable "image" {
  type        = string
  description = "Container image for the application"
  default     = "nginxdemos/hello"
}

variable "replicas" {
  type        = number
  description = "Number of replicas for the Deployment"
  default     = 1
}

variable "container_port" {
  type        = number
  description = "Container port exposed by the application"
  default     = 80
}

variable "host" {
  type        = string
  description = "Ingress host name to route traffic to this app"
  default     = ""
}

variable "service_account_name" {
  type        = string
  description = "Service account name used by the application pods"
  default     = "app-deployer"
}

variable "secret_provider_class_name" {
  type        = string
  description = "Name of the SecretProviderClass used to mount Key Vault secrets via CSI"
}

variable "env_vars" {
  type        = map(string)
  description = "Optional environment variables for the application container"
  default     = {}
}