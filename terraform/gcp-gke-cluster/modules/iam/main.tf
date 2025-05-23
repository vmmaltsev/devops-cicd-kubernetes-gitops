resource "google_service_account" "gke_sa" {
  account_id   = var.service_account_id
  display_name = "${var.service_account_id} Service Account for GKE"
  project      = var.project_id
}

# Assign roles to the GKE service account
resource "google_project_iam_member" "gke_sa_roles" {
  for_each = toset(var.service_account_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.gke_sa.email}"
}

# Allow workload identity for GKE to GSA mapping
resource "google_service_account_iam_binding" "workload_identity_binding" {
  count              = var.enable_workload_identity ? 1 : 0
  service_account_id = google_service_account.gke_sa.name
  role               = "roles/iam.workloadIdentityUser"
  members            = [
    "serviceAccount:${var.project_id}.svc.id.goog[${var.k8s_namespace}/${var.k8s_sa_name}]",
  ]
} 