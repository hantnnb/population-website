variable "project_id" {}
variable "instance_id" {}

variable "template" {
  description = "Template name"
  default     = "gcp-compute_engine"
}

variable "asset_name" {
  description = "Asset name"
}

variable "asset_lbnref" {
  description = "Asset lbnref"
}

variable "notify_to" {
  description = "Define webhook to notify"
  default     = "@webhook-discord_webhook"
}

variable "isprod" {
  description = "Define whether the monitor container_uptime is in production or not"
  default     = "false"
}

variable "kb" {
  description = "KB tag value"
  type        = string
  default     = ""
}


variable "severity" {
  description = "Define severity for gce_instance_is_running"
  default     = "1"
}

variable "category" {
  description = "Define category for gce_instance_is_running"
  default     = "235"
}

variable "evaluation_delay" {
  description = "Delay in seconds for the metric evaluation, for cloud 900s is recommended by Datadog"
  default     = 900
}

variable "new_host_delay" {
  description = "Delay in seconds before monitor new resource"
  default     = 300
}

variable "escalation_message" {
  description = "Default escalation message"
  default     = ""
}

variable "renotify_interval" {
  description = "Delay in minutes before monitor is renotified"
  default     = 15
}

variable "include_tags" {
  description = "Include triggered event tags in title"
  default     = false
}

variable "full_window" {
  description = "define full windows"
  default     = false
}
