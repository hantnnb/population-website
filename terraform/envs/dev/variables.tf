# General variables
variable "project_id" {}
variable "region" {}
variable "zone" {}
variable "environment" {}

# App variables
variable "app_name" {}
variable "ip_cidr_range" {}
variable "machine_type" {}
variable "image_family" {}
variable "image_project" {}
variable "startup_file" {}
variable "env_file" {
  sensitive = true
}
variable "env_backend" {
  sensitive = true
}

#Cloudflare
variable "cloudflare_api_token" {
  sensitive = true
}
variable "zone_id" {}
variable "root_domain" {}
variable "cloudflare_account_id" {}

# Datadog
variable "dataflow_job_name" {
  type        = string
  default     = "datadog-logs-export-job"
}

variable "dataflow_temp_bucket_name" {
  type        = string
  default     = "datadog-temp-bucket"
}

variable "topic_name" {
  type        = string
  default     = "datadog-export-topic"
}

variable "subscription_name" {
  type        = string
  default     = "datadog-export-sub"
}

variable "datadog_api_key" {
  type        = string
  sensitive   = true
}

variable "datadog_site_url" {
  type        = string
  default     = "datadoghq.com"
}

variable "log_sink_in_folder" {
  type        = bool
  default     = true
}

variable "folder_id" {
  type        = string
  default     = ""
}

variable "inclusion_filter" {
  type        = string
  default     = ""
}
