# PubSub Topic
resource "google_pubsub_topic" "pubsub_topic" {
  name    = "datadog_log_collection_topic"
  project = var.gcp-project-id
}

# PubSub Subscription
resource "google_pubsub_subscription" "pubsub_subscription" {
  name    = "datadog_log_collection_subscription"
  topic   = google_pubsub_topic.pubsub_topic.name
  project = google_pubsub_topic.pubsub_topic.project

  message_retention_duration = "1200s"   # 20 minutes
  retain_acked_messages      = true
  ack_deadline_seconds = 20

  # Never expires
  expiration_policy {
    ttl = ""
  }
  retry_policy {
    minimum_backoff = "10s"
  }

  push_config {
    push_endpoint = "https://gcp-intake.logs.datadoghq.eu/api/v2/logs?dd-api-key=${var.datadog_api_key}&dd-protocol=gcp"

    attributes = {
      x-goog-version = "v1"
    }
  }
}

# App Logs router sink
resource "google_logging_project_sink" "datadog_logs_sink" {
  name    = "datadog_logs_sink"
  project = google_pubsub_topic.pubsub_topic.project 

  # Export to PubSub
  destination = "pubsub.googleapis.com/projects/${var.gcp-project-id}/topics/${google_pubsub_topic.pubsub_topic.name}"

  # Log kubernetes app logs
  filter = "resource.type=k8s_container AND resource.labels.project_id=${var.gcp-project-id} AND resource.labels.location=${var.region} AND log_name=projects/${var.gcp-project-id}/logs/${var.log_name}"

  # Service account used for writing
  unique_writer_identity = true
}

# SQL failed login router sink
resource "google_logging_project_sink" "datadog_failed_login_sink" {
  name    = "datadog_failed_login_sink"
  project = google_pubsub_topic.pubsub_topic.project 

  # Export to PubSub
  destination = "pubsub.googleapis.com/projects/${var.gcp-project-id}/topics/${google_pubsub_topic.pubsub_topic.name}"

  # Log failed logins for SQL
  filter = "resource.labels.project_id=${var.gcp-project-id} AND resource.type=cloudsql_database AND \"Logon\""

  # Service account used for writing
  unique_writer_identity = true
}

# Pubsub publisher role
resource "google_project_iam_binding" "pubsub_publisher_role" {
  project = google_pubsub_topic.pubsub_topic.project
  role = "roles/pubsub.publisher"

  members = [
    google_logging_project_sink.datadog_logs_sink.writer_identity,
    google_logging_project_sink.datadog_failed_login_sink.writer_identity,
  ]
}