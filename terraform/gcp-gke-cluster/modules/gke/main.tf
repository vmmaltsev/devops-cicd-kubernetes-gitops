resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.regional ? var.region : var.zones[0]
  project  = var.project_id

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  networking_mode = "VPC_NATIVE"
  network         = var.vpc_id
  subnetwork      = var.subnet_id

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pod_range_name
    services_secondary_range_name = var.svc_range_name
  }

  # Enable Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Network Policy configuration
  dynamic "network_policy" {
    for_each = var.enable_network_policy && var.datapath_provider != "ADVANCED_DATAPATH" ? [1] : []
    content {
      enabled  = true
      provider = "CALICO"
    }
  }

  dynamic "network_policy" {
    for_each = var.enable_network_policy && var.datapath_provider == "ADVANCED_DATAPATH" ? [1] : (!var.enable_network_policy ? [1] : [])
    content {
      enabled = false
    }
  }

  # Enable Private Cluster
  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # Enable Binary Authorization
  binary_authorization {
    evaluation_mode = var.binary_authorization_mode
  }

  # Set Release Channel
  release_channel {
    channel = var.release_channel
  }

  # Enable Shielded Nodes
  node_config {
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
    service_account = var.service_account_email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  # Enable Maintenance Policy with dynamic dates
  maintenance_policy {
    recurring_window {
      start_time = var.maintenance_start_time
      end_time   = var.maintenance_end_time
      recurrence = var.maintenance_recurrence
    }
  }

  # Enable Master Authorized Networks
  dynamic "master_authorized_networks_config" {
    for_each = var.master_authorized_networks != null ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  # Set monitoring and logging service
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  logging_service    = "logging.googleapis.com/kubernetes"

  # Enable datapath provider for better networking
  datapath_provider = var.datapath_provider

  # Enable VPA
  vertical_pod_autoscaling {
    enabled = var.enable_vertical_pod_autoscaling
  }

  # Enable deletion protection
  deletion_protection = var.deletion_protection

  # DNS configuration
  dns_config {
    cluster_dns        = var.cluster_dns_provider
    cluster_dns_scope  = var.cluster_dns_scope
    cluster_dns_domain = var.cluster_dns_domain
  }

  # Cost optimization features
  cluster_autoscaling {
    enabled = var.enable_cluster_autoscaling
    dynamic "resource_limits" {
      for_each = var.enable_cluster_autoscaling ? var.cluster_autoscaling_resource_limits : []
      content {
        resource_type = resource_limits.value.resource_type
        minimum       = resource_limits.value.minimum
        maximum       = resource_limits.value.maximum
      }
    }
    auto_provisioning_defaults {
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform"
      ]
      service_account = var.service_account_email
      disk_size       = var.disk_size_gb
      disk_type       = var.disk_type
      image_type      = var.image_type
      shielded_instance_config {
        enable_secure_boot          = true
        enable_integrity_monitoring = true
      }
    }
  }

  # Enable monitoring config for better observability
  monitoring_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "WORKLOADS",
      "APISERVER",
      "SCHEDULER",
      "CONTROLLER_MANAGER"
    ]
    managed_prometheus {
      enabled = var.enable_managed_prometheus
    }
  }

  # Enable logging config
  logging_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "WORKLOADS",
      "APISERVER"
    ]
  }

  # Resource labels for better organization
  resource_labels = var.cluster_labels

  # Enable Gateway API
  gateway_api_config {
    channel = var.gateway_api_channel
  }

  # Security posture configuration
  security_posture_config {
    mode               = var.security_posture_mode
    vulnerability_mode = var.security_posture_vulnerability_mode
  }

  # Notification configuration for cluster events
  notification_config {
    pubsub {
      enabled = var.enable_notification_config
      topic   = var.notification_config_topic
    }
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes to node_config as it's managed by node pools
      node_config,
      # Ignore changes to initial_node_count after creation
      initial_node_count,
    ]
  }
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.regional ? var.region : var.zones[0]
  cluster    = google_container_cluster.primary.name
  project    = var.project_id
  node_count = var.regional ? null : var.nodes_per_zone

  # For zonal clusters, use only the first zone from the list
  # For regional clusters, GKE automatically distributes nodes across all zones
  node_locations = var.regional ? null : length(var.zones) > 1 ? slice(var.zones, 1, length(var.zones)) : null

  dynamic "autoscaling" {
    for_each = var.enable_autoscaling ? [1] : []
    content {
      min_node_count       = var.min_nodes_per_zone
      max_node_count       = var.max_nodes_per_zone
      location_policy      = var.autoscaling_location_policy
      total_min_node_count = var.autoscaling_total_min_node_count
      total_max_node_count = var.autoscaling_total_max_node_count
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type
    image_type   = var.image_type

    # Enable spot instances for cost optimization
    spot = var.enable_spot_instances

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    service_account = var.service_account_email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Apply labels to nodes
    labels = merge(var.node_labels, var.cluster_labels)

    # Apply taints to nodes
    dynamic "taint" {
      for_each = var.node_taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    # Apply metadata to nodes
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Resource labels for cost tracking
    resource_labels = var.cluster_labels

    # Enable workload metadata config
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Enable GCFS for faster container image pulls
    gcfs_config {
      enabled = var.enable_gcfs
    }

    # Enable gvnic for better network performance
    gvnic {
      enabled = var.enable_gvnic
    }

    # Reservation affinity for committed use discounts
    dynamic "reservation_affinity" {
      for_each = var.reservation_affinity != null ? [var.reservation_affinity] : []
      content {
        consume_reservation_type = reservation_affinity.value.consume_reservation_type
        key                      = reservation_affinity.value.key
        values                   = reservation_affinity.value.values
      }
    }
  }

  upgrade_settings {
    max_surge       = var.upgrade_max_surge
    max_unavailable = var.upgrade_max_unavailable
    strategy        = var.upgrade_strategy

    dynamic "blue_green_settings" {
      for_each = var.upgrade_strategy == "BLUE_GREEN" ? [1] : []
      content {
        standard_rollout_policy {
          batch_percentage    = var.blue_green_batch_percentage
          batch_node_count    = var.blue_green_batch_node_count
          batch_soak_duration = var.blue_green_batch_soak_duration
        }
        node_pool_soak_duration = var.blue_green_node_pool_soak_duration
      }
    }
  }

  # Network configuration for better performance
  network_config {
    create_pod_range     = false
    enable_private_nodes = var.enable_private_nodes
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes to node_count when autoscaling is enabled
      node_count,
    ]
  }
} 