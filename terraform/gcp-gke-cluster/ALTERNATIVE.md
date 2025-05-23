# Using the Official Google GKE Terraform Module

As an alternative to the custom GKE modules in this project, you can use the official Google Kubernetes Engine module from the Terraform Registry. This document provides guidance on how to migrate to or implement the official module.

## Official Module Benefits

- Maintained by Google Cloud
- Regular updates with new GKE features
- Comprehensive documentation and examples
- Well-tested configurations
- Community support

## Official Module Usage

### Module Reference

```hcl
module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  version                    = "~> 36.3.0"  # Use the latest version
  
  project_id                 = var.project_id
  name                       = "${var.project_prefix}-cluster"
  region                     = var.region
  zones                      = var.zones
  network                    = var.vpc_name
  subnetwork                 = var.subnet_name
  ip_range_pods              = var.pod_range_name
  ip_range_services          = var.svc_range_name
  
  regional                   = var.regional
  
  # Private cluster configuration
  enable_private_nodes       = var.enable_private_nodes
  enable_private_endpoint    = var.enable_private_endpoint
  master_ipv4_cidr_block     = var.master_ipv4_cidr_block
  
  # Network policy
  network_policy             = var.enable_network_policy
  
  # Node pools
  remove_default_node_pool   = true
  initial_node_count         = 1
  
  # Service account
  service_account            = var.service_account_email
  
  # Release channel
  release_channel            = var.release_channel
  
  # Advanced features
  datapath_provider          = var.datapath_provider
  enable_vertical_pod_autoscaling = var.enable_vertical_pod_autoscaling
  deletion_protection        = var.deletion_protection
  
  # Binary authorization
  enable_binary_authorization = var.binary_authorization_mode == "PROJECT_SINGLETON_POLICY_ENFORCE"
  
  # DNS configuration
  cluster_dns_provider       = var.cluster_dns_provider
  cluster_dns_scope          = var.cluster_dns_scope
  cluster_dns_domain         = var.cluster_dns_domain
  
  # Node pools configuration
  node_pools = [
    {
      name               = "default-node-pool"
      machine_type       = var.machine_type
      min_count          = var.enable_autoscaling ? var.min_nodes_per_zone : null
      max_count          = var.enable_autoscaling ? var.max_nodes_per_zone : null
      initial_node_count = var.nodes_per_zone
      disk_size_gb       = var.disk_size_gb
      disk_type          = var.disk_type
      image_type         = var.image_type
      auto_repair        = true
      auto_upgrade       = true
      
      # Node security
      enable_secure_boot          = true
      enable_integrity_monitoring = true
      
      # Labels and taints
      node_labels                 = var.node_labels
      node_taints                 = var.node_taints
    }
  ]
  
  # Maintenance window
  maintenance_start_time    = var.maintenance_start_time
  maintenance_end_time      = var.maintenance_end_time
  maintenance_recurrence    = var.maintenance_recurrence
  
  # Master authorized networks
  master_authorized_networks = var.master_authorized_networks
}
```

## Migration Process

To migrate from the custom modules to the official Google module:

1. Create a new Terraform configuration file using the above module reference
2. Adjust variables as needed to match your requirements
3. Run `terraform init` to download the official module
4. Run `terraform plan` to preview changes
5. Apply the changes using `terraform apply`

## Mapping Custom Module Variables to Official Module

| Custom Module Variable | Official Module Variable | Notes |
|------------------------|--------------------------|-------|
| `project_id` | `project_id` | |
| `cluster_name` | `name` | |
| `region` | `region` | |
| `zones` | `zones` | |
| `vpc_id` | `network` | Use network name instead of ID |
| `subnet_id` | `subnetwork` | Use subnet name instead of ID |
| `pod_range_name` | `ip_range_pods` | |
| `svc_range_name` | `ip_range_services` | |
| `enable_network_policy` | `network_policy` | |
| `enable_private_nodes` | `enable_private_nodes` | |
| `enable_private_endpoint` | `enable_private_endpoint` | |
| `master_ipv4_cidr_block` | `master_ipv4_cidr_block` | |
| `binary_authorization_mode` | `enable_binary_authorization` | Convert to boolean |
| `service_account_email` | `service_account` | |
| `regional` | `regional` | |
| `datapath_provider` | `datapath_provider` | |
| `enable_vertical_pod_autoscaling` | `enable_vertical_pod_autoscaling` | |
| `deletion_protection` | `deletion_protection` | |
| `cluster_dns_provider` | `cluster_dns_provider` | |
| `cluster_dns_scope` | `cluster_dns_scope` | |
| `cluster_dns_domain` | `cluster_dns_domain` | |
| Node pool variables | `node_pools` list of objects | Combine into node pool objects |

## Additional Resources

- [Official GKE Module Documentation](https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/latest)
- [Module GitHub Repository](https://github.com/terraform-google-modules/terraform-google-kubernetes-engine)
- [Module Examples](https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/tree/master/examples)

## Advanced Configurations

The official module supports several advanced configurations:

### Multiple Node Pools

```hcl
node_pools = [
  {
    name               = "general-pool"
    machine_type       = "e2-standard-2"
    min_count          = 1
    max_count          = 5
    disk_size_gb       = 100
    disk_type          = "pd-standard"
    image_type         = "COS_CONTAINERD"
    node_labels        = {
      role = "general"
    }
  },
  {
    name               = "high-memory-pool"
    machine_type       = "e2-highmem-4"
    min_count          = 1
    max_count          = 3
    disk_size_gb       = 200
    disk_type          = "pd-ssd"
    image_type         = "COS_CONTAINERD"
    node_labels        = {
      role = "memory-intensive"
    }
    node_taints        = [
      {
        key    = "workload"
        value  = "memory-intensive"
        effect = "NO_SCHEDULE"
      }
    ]
  }
]
```

### Cluster Autoscaling

```hcl
cluster_autoscaling = {
  enabled             = true
  autoscaling_profile = "BALANCED"
  min_cpu_cores       = 2
  max_cpu_cores       = 20
  min_memory_gb       = 4
  max_memory_gb       = 100
  gpu_resources       = []
  auto_repair         = true
  auto_upgrade        = true
}
```

### Workload Identity

```hcl
identity_namespace = "${var.project_id}.svc.id.goog"
``` 