variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "zenit"
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
  default     = "dev"
}

variable "subnet_cidr" {
  description = "The CIDR range for the subnet"
  type        = string
  default     = "10.10.0.0/20"
}

variable "pod_cidr" {
  description = "The CIDR range for pods"
  type        = string
  default     = "10.20.0.0/16"
}

variable "svc_cidr" {
  description = "The CIDR range for services"
  type        = string
  default     = "10.30.0.0/16"
}

variable "enable_network_policy" {
  description = "Enable network policy for the cluster"
  type        = bool
  default     = true
}

variable "enable_private_nodes" {
  description = "Enable private nodes for the cluster"
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for the cluster"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "The CIDR block for the master network"
  type        = string
  default     = "172.16.0.0/28"
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
  default     = 1
}

variable "max_nodes_per_zone" {
  description = "The maximum number of nodes per zone"
  type        = number
  default     = 3
}

variable "nodes_per_zone" {
  description = "The number of nodes per zone"
  type        = number
  default     = 1
}

variable "node_labels" {
  description = "The labels to apply to the nodes"
  type        = map(string)
  default     = {
    environment = "dev"
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

variable "binary_authorization_mode" {
  description = "Mode of operation for Binary Authorization. Accepted values are DISABLED and PROJECT_SINGLETON_POLICY_ENFORCE"
  type        = string
  default     = "DISABLED"
}

variable "release_channel" {
  description = "The release channel of this cluster. Accepted values are `UNSPECIFIED`, `RAPID`, `REGULAR` and `STABLE`."
  type        = string
  default     = "REGULAR"
}

variable "datapath_provider" {
  description = "The desired datapath provider for this cluster. By default, `DATAPATH_PROVIDER_UNSPECIFIED` enables the IPTables-based kube-proxy implementation. `ADVANCED_DATAPATH` enables Dataplane-V2 feature."
  type        = string
  default     = "DATAPATH_PROVIDER_UNSPECIFIED"
}

variable "enable_vertical_pod_autoscaling" {
  description = "Vertical Pod Autoscaling automatically adjusts the resources of pods controlled by it"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Whether or not to allow Terraform to destroy the cluster."
  type        = bool
  default     = true
}

variable "cluster_dns_provider" {
  description = "Which in-cluster DNS provider should be used. PROVIDER_UNSPECIFIED (default) or PLATFORM_DEFAULT or CLOUD_DNS."
  type        = string
  default     = "PROVIDER_UNSPECIFIED"
}

variable "cluster_dns_scope" {
  description = "The scope of access to cluster DNS records. DNS_SCOPE_UNSPECIFIED (default) or CLUSTER_SCOPE or VPC_SCOPE."
  type        = string
  default     = "DNS_SCOPE_UNSPECIFIED"
}

variable "cluster_dns_domain" {
  description = "The suffix used for all cluster service records."
  type        = string
  default     = ""
}

variable "maintenance_start_time" {
  description = "Time window specified for daily or recurring maintenance operations in RFC3339 format"
  type        = string
  default     = "2023-01-01T00:00:00Z"
}

variable "maintenance_end_time" {
  description = "Time window specified for recurring maintenance operations in RFC3339 format"
  type        = string
  default     = "2023-01-02T00:00:00Z"
}

variable "maintenance_recurrence" {
  description = "Frequency of the recurring maintenance window in RFC5545 format."
  type        = string
  default     = "FREQ=WEEKLY;BYDAY=SA,SU"
}

variable "upgrade_max_surge" {
  description = "The number of additional nodes that can be added during an upgrade."
  type        = number
  default     = 1
}

variable "upgrade_max_unavailable" {
  description = "The number of nodes that can be simultaneously unavailable during an upgrade."
  type        = number
  default     = 0
}

variable "upgrade_strategy" {
  description = "The upgrade strategy to use for the node pool. Valid values include `SURGE` and `BLUE_GREEN`."
  type        = string
  default     = "SURGE"
} 