variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "your-project-id-staging"
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "zones" {
  description = "The GCP zones for the cluster"
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b", "us-central1-c"]
}

variable "regional" {
  description = "Whether to create a regional cluster"
  type        = bool
  default     = true
}

variable "project_prefix" {
  description = "The prefix for resource names"
  type        = string
  default     = "staging"
}

variable "subnet_cidr" {
  description = "The CIDR range for the subnet"
  type        = string
  default     = "10.40.0.0/20"
}

variable "pod_cidr" {
  description = "The CIDR range for pods"
  type        = string
  default     = "10.50.0.0/16"
}

variable "svc_cidr" {
  description = "The CIDR range for services"
  type        = string
  default     = "10.60.0.0/16"
}

variable "enable_network_policy" {
  description = "Enable network policy on the cluster"
  type        = bool
  default     = true
}

variable "enable_private_nodes" {
  description = "Enable private nodes"
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "The IP CIDR block for the master network"
  type        = string
  default     = "172.16.1.0/28"
}

variable "machine_type" {
  description = "The machine type for the nodes"
  type        = string
  default     = "e2-standard-2"
}

variable "disk_size_gb" {
  description = "The disk size in GB for the nodes"
  type        = number
  default     = 100
}

variable "disk_type" {
  description = "The disk type for the nodes"
  type        = string
  default     = "pd-standard"
}

variable "image_type" {
  description = "The image type for the nodes"
  type        = string
  default     = "COS_CONTAINERD"
}

variable "enable_autoscaling" {
  description = "Enable autoscaling"
  type        = bool
  default     = true
}

variable "min_nodes_per_zone" {
  description = "The minimum number of nodes per zone"
  type        = number
  default     = 2
}

variable "max_nodes_per_zone" {
  description = "The maximum number of nodes per zone"
  type        = number
  default     = 5
}

variable "nodes_per_zone" {
  description = "The number of nodes per zone"
  type        = number
  default     = 2
}

variable "node_labels" {
  description = "The labels to apply to the nodes"
  type        = map(string)
  default     = {
    environment = "staging"
  }
}

variable "node_taints" {
  description = "The taints to apply to the nodes"
  type        = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default     = []
}

variable "master_authorized_networks" {
  description = "List of master authorized networks"
  type        = list(object({
    cidr_block   = string
    display_name = string
  }))
  default     = [
    {
      cidr_block   = "10.0.0.0/8"
      display_name = "Internal VPC"
    }
  ]
} 