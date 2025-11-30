variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "backend_ip_addresses" {
  type = list(string)
}

variable "backend_port" {
  type    = number
  default = 30141
}

variable "tags" {
  type = map(string)
}

variable "host_name" {
  type        = string
}