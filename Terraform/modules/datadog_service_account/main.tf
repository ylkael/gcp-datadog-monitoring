resource "google_service_account" "datadog_service_account" {
  project      = var.gcp-project-id
  account_id   = "datadog-service-account"
  display_name = "datadog-service-account"
}

resource "google_project_iam_binding" "datadog_service_account_compute_viewer" {
  project = var.gcp-project-id
  role    = "roles/compute.viewer"

  members = [
    "serviceAccount:${google_service_account.datadog_service_account.email}",
  ]
}

resource "google_project_iam_binding" "datadog_service_account_monitoring_viewer" {
  project = var.gcp-project-id
  role    = "roles/monitoring.viewer"

  members = [
    "serviceAccount:${google_service_account.datadog_service_account.email}",
  ]
}

resource "google_project_iam_binding" "datadog_service_account_cloud_asset_viewer" {
  project = var.gcp-project-id
  role    = "roles/cloudasset.viewer"

  members = [
    "serviceAccount:${google_service_account.datadog_service_account.email}",
  ]
}