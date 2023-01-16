variable "gcp-project-id" {
  type        = string
  default     = ""
  description = "GCP project ID"
}

variable "environment" {
  type        = string
  default     = ""
  description = "Environment"
}

variable "datadog_api_key" {
  type = string
  default = ""
  description = "Datadog API Key"
}

variable "datadog_app_key" {
  type = string
  default = ""
  description = "Datadog Application Key"
}