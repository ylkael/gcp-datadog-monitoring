variable "gcp-project-id" {
  type        = string
  default     = ""
  description = "GCP project ID"
}

variable "region"{
  default = ""
}

variable "log_name" {
  type        = string
  default     = ""
  description = "Log name"  
}

variable "datadog_api_key" {
  type = string
  default = ""
  description = "Datadog API Key"
}