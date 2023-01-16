variable "gcp-project-id" {
  type        = string
  default     = "project-id-123"
  description = "GCP project ID"
}
variable "gcp_project_number"{
  type        = string
  default     = "123456789"
  description = "GCP project number"
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Environment"
}