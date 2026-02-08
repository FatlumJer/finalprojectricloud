variable "subscription_id" {
  type        = string
  description = "The Azure Subscription ID from the sandbox"
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "node_vm_size" {
  type = string
}

variable "cluster_name" {
  type = string
}