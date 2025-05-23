terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.36.1"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.36.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
  
  backend "gcs" {
    # This will be configured in each environment
    # Example:
    # bucket = "your-terraform-state-bucket"
    # prefix = "terraform/gke-cluster/dev"
  }
}

provider "google" {
  # Project and region will be configured in each environment
  # Configuration will be provided via environment variables or terraform.tfvars
}

provider "google-beta" {
  # Project and region will be configured in each environment
  # Configuration will be provided via environment variables or terraform.tfvars
}
