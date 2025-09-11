# variable "env" {
#   type    = string
#   default = "dev"
# }

# variable "tag_filter" {
#   description = "Extra tag filter added to the query, e.g. env:dev or host:pplt-dev-vm"
#   type        = string
#   default     = "env:dev"
# }

variable "notify" {
  description = "Who to notify (email + webhook handle)"
  type        = string
  default     = ""
}

variable "warning_threshold" {
  type    = number
  default = 85 # percentage
}

variable "critical_threshold" {
  type    = number
  default = 95 # percentage
}

variable "evaluation_window" {
  type    = number
  default = 5 # minutes
}

variable "renotify_minutes" {
  type    = number
  default = 60 # minutes
}

variable "no_data_minutes" {
  type    = number
  default = 10 # minutes
}
