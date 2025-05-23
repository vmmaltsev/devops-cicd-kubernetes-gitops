variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "service_account_id" {
  description = "The ID of the service account"
  type        = string
}

variable "service_account_roles" {
  description = "The roles to assign to the service account"
  type        = list(string)
  default = [
    "roles/container.nodeServiceAccount",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer"
  ]
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity for the GKE cluster"
  type        = bool
  default     = true
}

variable "k8s_namespace" {
  description = "The Kubernetes namespace for Workload Identity"
  type        = string
  default     = "default"
}

variable "k8s_sa_name" {
  description = "The Kubernetes service account name for Workload Identity"
  type        = string
  default     = "default"
} 