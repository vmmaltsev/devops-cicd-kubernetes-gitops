output "cluster_id" {
  description = "The ID of the GKE cluster"
  value       = google_container_cluster.primary.id
}

output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = google_container_cluster.primary.endpoint
}

output "cluster_ca_certificate" {
  description = "The CA certificate of the GKE cluster"
  value       = google_container_cluster.primary.master_auth.0.cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "The location of the GKE cluster"
  value       = google_container_cluster.primary.location
}

output "cluster_self_link" {
  description = "The self link of the GKE cluster"
  value       = google_container_cluster.primary.self_link
}

output "node_pool_name" {
  description = "The name of the GKE node pool"
  value       = google_container_node_pool.primary_nodes.name
}

output "workload_identity_pool" {
  description = "The workload identity pool of the GKE cluster"
  value       = "${var.project_id}.svc.id.goog"
} 