terraform {
  backend "gcs" {
    bucket = "tf-state-staging-gke-cluster"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

module "network" {
  source = "../../modules/network"

  project_id  = var.project_id
  region      = var.region
  vpc_name    = "${var.project_prefix}-vpc"
  subnet_name = "${var.project_prefix}-subnet"
  subnet_cidr = var.subnet_cidr
  pod_cidr    = var.pod_cidr
  svc_cidr    = var.svc_cidr
}

module "iam" {
  source = "../../modules/iam"

  project_id         = var.project_id
  service_account_id = "${var.project_prefix}-gke-sa"
  
  enable_workload_identity = true
  k8s_namespace           = "kube-system"
  k8s_sa_name             = "default"
}

module "gke" {
  source = "../../modules/gke"

  project_id           = var.project_id
  region               = var.region
  zones                = var.zones
  regional             = var.regional
  cluster_name         = "${var.project_prefix}-cluster"
  
  vpc_id               = module.network.vpc_id
  subnet_id            = module.network.subnet_id
  pod_range_name       = module.network.pod_range_name
  svc_range_name       = module.network.svc_range_name
  service_account_email = module.iam.service_account_email
  
  enable_network_policy    = var.enable_network_policy
  enable_private_nodes     = var.enable_private_nodes
  enable_private_endpoint  = var.enable_private_endpoint
  master_ipv4_cidr_block   = var.master_ipv4_cidr_block
  
  machine_type        = var.machine_type
  disk_size_gb        = var.disk_size_gb
  disk_type           = var.disk_type
  image_type          = var.image_type
  
  enable_autoscaling  = var.enable_autoscaling
  min_nodes_per_zone  = var.min_nodes_per_zone
  max_nodes_per_zone  = var.max_nodes_per_zone
  nodes_per_zone      = var.nodes_per_zone
  
  node_labels         = var.node_labels
  node_taints         = var.node_taints
  
  master_authorized_networks = var.master_authorized_networks
} 