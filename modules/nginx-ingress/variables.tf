variable "namespace" {
  type        = string
  description = "Namespace where ingress-nginx will be installed"
  default     = "ingress-nginx"
}

variable "release_name" {
  type        = string
  description = "Helm release name for ingress-nginx"
  default     = "ingress-nginx"
}

variable "replica_count" {
  type        = number
  description = "Number of controller replicas"
  default     = 1
}

variable "environment" {
  type        = string
  description = "Environment name (dev, uat, etc)"
}

variable "owner" {
  type        = string
  description = "Owner label"
}

variable "service_type" {
  type        = string
  description = "Kubernetes Service type for the ingress controller (ClusterIP, LoadBalancer, NodePort)"
  default     = "ClusterIP"
}
