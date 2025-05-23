output "vpc_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "subnet_id" {
  description = "The ID of the subnet"
  value       = google_compute_subnetwork.subnet.id
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}

output "pod_cidr_range" {
  description = "The CIDR range for pods"
  value       = var.pod_cidr
}

output "svc_cidr_range" {
  description = "The CIDR range for services"
  value       = var.svc_cidr
}

output "pod_range_name" {
  description = "The name of the pod secondary IP range"
  value       = "${var.subnet_name}-pod-range"
}

output "svc_range_name" {
  description = "The name of the service secondary IP range"
  value       = "${var.subnet_name}-svc-range"
} 