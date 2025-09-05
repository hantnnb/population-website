variable "region" { type = string }
variable "zone" { type = string }

variable "machine_type" { type = string }
variable "image_family" { type = string }
variable "image_project" { type = string }

variable "environment" { type = string }
variable "name_prefix" { type = string }
variable "startup_file" { type = string }
variable "startup_script_content" {
  description = "Full contents of the startup script"
  type        = string
}
variable "env_file" { type = string }
variable "env_backend" { type = string }

variable "network" { type = string }
variable "subnetwork" { type = string }

variable "sa_user_members" {
  description = "Members that can use this SA on instances (roles/iam.serviceAccountUser)."
  type        = list(string)
  default     = []
}

variable "ssh_pubkey" {
  type        = string
  description = "Public SSH key contents for ubuntu user"
}

# Datadog variables ============================================================
variable "datadog_enabled" {
  type    = bool
  default = false
}

# Required api keys only when datadog is enabled
variable "datadog_api_key" {
  type      = string
  sensitive = true
  default   = ""
  validation {
    condition     = var.datadog_enabled ? length(trim(var.datadog_api_key)) > 0 : true
    error_message = "datadog_api_key must be set when datadog_enabled = true."
  }
}

variable "datadog_site" {
  type    = string
  default = "ap1.datadoghq.com"
}

variable "dd_env" {
  type    = string
  default = null
}

variable "dd_service" {
  type    = string
  default = "population-website"
}

variable "dd_version" {
  type    = string
  default = "v1"
}