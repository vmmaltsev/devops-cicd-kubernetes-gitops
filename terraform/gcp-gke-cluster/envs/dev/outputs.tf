output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.gke.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = module.gke.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "The CA certificate of the GKE cluster"
  value       = module.gke.cluster_ca_certificate
  sensitive   = true
}

output "vpc_name" {
  description = "The name of the VPC"
  value       = module.network.vpc_name
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = module.network.subnet_name
}

output "service_account_email" {
  description = "The email of the service account"
  value       = module.iam.service_account_email
}

output "workload_identity_pool" {
  description = "The workload identity pool"
  value       = module.gke.workload_identity_pool
}

output "cluster_location" {
  description = "The location of the GKE cluster"
  value       = module.gke.cluster_location
}

output "get_credentials_command" {
  description = "Command to get credentials for the GKE cluster"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${module.gke.cluster_location} --project ${var.project_id}"
} 