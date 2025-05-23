# Migration Guide for GCP GKE Cluster Module

This guide helps you migrate from the previous version of the GCP GKE Cluster module to the improved version with enhanced security, operational features, and best practices.

## Summary of Changes

The improved GKE module includes:

- Enhanced security features
- Advanced networking options
- Better maintenance and operational controls
- Support for newer GKE features
- Improved documentation

## Migration Steps

Follow these steps to migrate your existing GKE cluster configurations:

### 1. Update Terraform Variables

Add the following new variables to your `terraform.tfvars` file in each environment:

```hcl
# Cluster configuration
binary_authorization_mode = "DISABLED"  # Or "PROJECT_SINGLETON_POLICY_ENFORCE"
release_channel        = "REGULAR"  # Options: "UNSPECIFIED", "RAPID", "REGULAR", "STABLE"
datapath_provider      = "ADVANCED_DATAPATH"  # Enable GKE Dataplane V2
enable_vertical_pod_autoscaling = true
deletion_protection    = true
cluster_dns_provider   = "CLOUD_DNS"  # Options: "PROVIDER_UNSPECIFIED", "PLATFORM_DEFAULT", "CLOUD_DNS"
cluster_dns_scope      = "VPC_SCOPE"  # Options: "DNS_SCOPE_UNSPECIFIED", "CLUSTER_SCOPE", "VPC_SCOPE"
cluster_dns_domain     = ""  # Custom domain suffix

# Maintenance
maintenance_start_time = "2023-01-01T00:00:00Z"  # Format in RFC3339
maintenance_end_time   = "2023-01-02T00:00:00Z"  # Format in RFC3339
maintenance_recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"  # RFC5545 format

# Node pool upgrade settings
upgrade_max_surge       = 1
upgrade_max_unavailable = 0
upgrade_strategy        = "SURGE"  # Options: "SURGE", "BLUE_GREEN"
```

### 2. Update Environment Variables

Add the new variables to your `variables.tf` file in each environment (dev, staging, prod):

```hcl
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
```

### 3. Update Environment main.tf

Update your `main.tf` file in each environment to pass the new variables to the GKE module:

```hcl
module "gke" {
  source = "../../modules/gke"

  # Existing variables
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
  
  # New variables
  binary_authorization_mode = var.binary_authorization_mode
  release_channel        = var.release_channel
  datapath_provider      = var.datapath_provider
  enable_vertical_pod_autoscaling = var.enable_vertical_pod_autoscaling
  deletion_protection    = var.deletion_protection
  cluster_dns_provider   = var.cluster_dns_provider
  cluster_dns_scope      = var.cluster_dns_scope
  cluster_dns_domain     = var.cluster_dns_domain
  
  maintenance_start_time = var.maintenance_start_time
  maintenance_end_time   = var.maintenance_end_time
  maintenance_recurrence = var.maintenance_recurrence
  
  # Existing variables
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
  
  # New variables
  upgrade_max_surge       = var.upgrade_max_surge
  upgrade_max_unavailable = var.upgrade_max_unavailable
  upgrade_strategy        = var.upgrade_strategy
  
  # Existing variables
  master_authorized_networks = var.master_authorized_networks
}
```

### 4. Apply Changes

After making these updates, run the standard Terraform workflow:

```bash
# Initialize Terraform (only needed if you've added new providers)
terraform init

# See the planned changes
terraform plan

# Apply the changes
terraform apply
```

## Important Notes

1. **Dataplane V2**: Enabling `datapath_provider = "ADVANCED_DATAPATH"` will use GKE Dataplane V2, which replaces kube-proxy with a more efficient dataplane. This requires a cluster update with potential downtime.

2. **Deletion Protection**: Setting `deletion_protection = true` prevents accidental deletion of the cluster via Terraform. To delete the cluster intentionally, you'll need to set this to `false` first.

3. **Maintenance Windows**: Configure maintenance windows during off-hours to minimize impact on production workloads.

4. **Release Channel**: The `release_channel` determines how quickly you receive GKE updates:
   - `RAPID`: Latest features, less stable
   - `REGULAR`: New features with reliability (recommended)
   - `STABLE`: Most reliable, fewer features

5. **Vertical Pod Autoscaling**: Enabling VPA requires the VPA controller to be installed in the cluster.

## Compatibility Considerations

- These changes maintain backward compatibility with existing clusters.
- Some features may require GKE version 1.19+ (managed by the release channel).
- No immediate changes will be made to running workloads.

## Additional Resources

- [GKE Release Notes](https://cloud.google.com/kubernetes-engine/docs/release-notes)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [GKE Dataplane V2](https://cloud.google.com/kubernetes-engine/docs/concepts/dataplane-v2)
- [VPA Documentation](https://cloud.google.com/kubernetes-engine/docs/concepts/verticalpodautoscaler) 