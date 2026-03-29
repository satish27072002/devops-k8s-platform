variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "devops-platform"
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "ams3"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.31.1-do.4"
}

variable "node_size" {
  description = "Size of the worker nodes"
  type        = string
  default     = "s-2vcpu-2gb"
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}
