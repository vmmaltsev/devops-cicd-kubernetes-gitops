terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.36.1"
    }
  }
  # После создания бакета вы сможете использовать его как бэкенд
  # backend "gcs" {
  #   bucket = "devops-cicd-demo-bucket-vm"
  #   prefix = "terraform/state"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.location
  credentials = file(var.credentials_file)
}

resource "google_storage_bucket" "main" {
  name                        = var.bucket_name
  location                    = var.location
  force_destroy               = false
  uniform_bucket_level_access = true
  
  versioning {
    enabled = var.versioning_enabled
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age                   = var.lifecycle_days
      with_state            = "ARCHIVED"
      matches_storage_class = ["STANDARD"]
    }
  }
  
  # Добавление правила для перехода в холодное хранилище
  lifecycle_rule {
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
    condition {
      age = 60
    }
  }

  # Защита от случайного удаления
  lifecycle {
    prevent_destroy = true
  }

  labels = {
    environment = "prod"
    team        = "devops"
    project     = var.project_id
    managed_by  = "terraform"
  }
}
