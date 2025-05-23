# GCP GKE Cluster Terraform Module

This Terraform module creates a Google Kubernetes Engine (GKE) cluster in Google Cloud Platform (GCP) with security best practices and operational readiness.

## Features

- Regional or zonal cluster deployment options
- Private GKE cluster configuration with VPC-native networking
- Workload Identity for secure GCP service authentication
- Node pool configuration with autoscaling
- Network Policy (Calico) support
- Maintenance window configuration
- Secure node configuration with shielded VMs
- IAM service accounts with least privilege
- Support for master authorized networks
- Advanced networking with VPC-native mode
- Support for Binary Authorization
- Release channel configuration
- Vertical Pod Autoscaling

## Module Structure

```
terraform/gcp-gke-cluster/
├── envs/
│   ├── dev/       # Development environment configuration
│   ├── staging/   # Staging environment configuration
│   └── prod/      # Production environment configuration
├── modules/
│   ├── gke/       # GKE cluster and node pool configuration
│   ├── iam/       # IAM and service account configuration
│   └── network/   # VPC, subnet, and network configuration
├── provider.tf    # Terraform provider configuration
└── README.md      # This documentation
```

## Usage

1. Navigate to the desired environment directory (dev, staging, or prod)
2. Update the `terraform.tfvars` file with your desired configuration
3. Initialize Terraform: `terraform init`
4. Plan the deployment: `terraform plan`
5. Apply the configuration: `terraform apply`

### Example Configuration

```hcl
# terraform.tfvars
project_id       = "your-project-id"
region           = "us-central1"
zones            = ["us-central1-a", "us-central1-b", "us-central1-c"]
regional         = true
project_prefix   = "env"  # dev, staging, prod, etc.

subnet_cidr      = "10.10.0.0/20"
pod_cidr         = "10.20.0.0/16"
svc_cidr         = "10.30.0.0/16"

enable_network_policy   = true
enable_private_nodes    = true
enable_private_endpoint = false
master_ipv4_cidr_block  = "172.16.0.0/28"

machine_type     = "e2-standard-2"
disk_size_gb     = 100
disk_type        = "pd-standard"
image_type       = "COS_CONTAINERD"

enable_autoscaling = true
min_nodes_per_zone = 1
max_nodes_per_zone = 3
nodes_per_zone     = 1

node_labels = {
  environment = "dev"
}

node_taints = []

master_authorized_networks = [
  {
    cidr_block   = "10.0.0.0/8"
    display_name = "Internal VPC"
  }
]
```

## Security Best Practices

This module implements the following security best practices:

- Private GKE clusters to limit exposure
- Workload Identity for secure service account access
- Shielded nodes with secure boot and integrity monitoring
- Network Policy for pod-to-pod traffic control
- Master authorized networks to limit control plane access
- Least privilege IAM service accounts
- VPC-native networking with separate pod and service CIDR ranges
- Support for Binary Authorization to enforce deployment policies
- Release channel configuration for automated security updates
- Automatic node repair and upgrade

## Networking

The module configures VPC-native networking with separate CIDR ranges for:

- Subnet CIDR: Primary subnet for GKE nodes
- Pod CIDR: Secondary IP range for Kubernetes pods
- Service CIDR: Secondary IP range for Kubernetes services

The network configuration includes:
- NAT gateway for egress traffic
- Firewall rules for internal communication
- Support for private clusters with master authorized networks

## IAM

The IAM module creates a dedicated service account for GKE nodes with the minimum required permissions:

- Monitoring metrics writer
- Logging writer
- Stackdriver metadata writer
- Container node service account

It also supports Workload Identity for secure GCP service authentication from Kubernetes pods.

## Maintenance and Operations

The module includes operational best practices:

- Node auto-repair and auto-upgrade
- Maintenance windows to control when upgrades occur
- Node pool autoscaling to adjust capacity based on demand
- Vertical Pod Autoscaling (optional)
- Release channel subscription for managed upgrades
- Monitoring and logging with Google Cloud Operations

## Requirements

- Terraform v1.0.0+
- Google Provider v6.36.1+
- Google Beta Provider v6.36.1+
- GCP Project with GKE API enabled
- Appropriate IAM permissions to create GKE clusters

## Additional Resources

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Terraform Google Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GKE Enterprise Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices) 