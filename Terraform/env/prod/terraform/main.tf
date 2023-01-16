terraform {
  required_version = "~> 1.1.4"
  required_providers {
    google = {
      source  = "google"
      version = "~> 4.11.0"
    }
    google-beta = {
      source  = "google-beta"
      version = "~> 4.11.0"
    }
    # Datadog provider must be specified in each module which requires that provider
    datadog = {
      source  = "DataDog/datadog"
      version = "3.10.0"
    }
  }

  backend "gcs" {
    credentials = "keyfile.json"
    bucket      = "terraform-${var.environment}"
    prefix      = "terraform/state"
  }
}

provider "google" {
  project     = var.gcp-project-id
  region      = "europe-north1"
  credentials = file("terraform-serviceaccount-keyfile.json")
}

provider "google-beta" {
  project   = var.gcp-project-id
  region    = "europe-north1"
}

# Datadog provider must be specified in each module which requires that provider
provider "datadog" {
  api_key = data.google_kms_secret.datadog_api_key.plaintext
  app_key = data.google_kms_secret.datadog_app_key.plaintext
  api_url =  "https://api.datadoghq.eu/"
}

data "google_kms_secret" "datadog_api_key" {
  crypto_key = "${var.gcp-project-id}/europe-north1/terraform-secret/secret"
  ciphertext = "xxx"
}

data "google_kms_secret" "datadog_app_key" {
  crypto_key = "${var.gcp-project-id}/europe-north1/terraform-secret/secret"
  ciphertext = "xxx"
}

# Modules
module "datadog_service_account" {
  source          = "../../../terraform/modules/datadog_service_account"
  gcp-project-id  = var.gcp-project-id
  environment     = var.environment 
}

module "datadog_pubsub_logging"{
  source          = "../../../terraform/modules/datadog_pubsub_logging"
  datadog_api_key = data.google_kms_secret.datadog_api_key.plaintext
  gcp-project-id  = var.gcp-project-id
  region          = "europe-north1"
  log_name        = "App-${var.environment}"
}

module "datadog_monitors" {
  source          = "../../../terraform/modules/datadog_monitors"
  gcp-project-id  = var.gcp-project-id
  environment     = var.environment
  datadog_api_key = data.google_kms_secret.datadog_api_key.plaintext
  datadog_app_key = data.google_kms_secret.datadog_app_key.plaintext
}