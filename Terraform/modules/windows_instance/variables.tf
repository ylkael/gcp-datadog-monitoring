variable "gcp-project-id" {
  type        = string
  default     = ""
  description = "GCP project ID"
}

variable "gcp_project_number"{
  type        = string
  default     = ""
  description = "GCP project number"
}

variable "environment" {
  type        = string
  default     = ""
  description = "Environment"
} 

variable "region"{
  default = ""
}

variable "zone"{
  default = ""
}