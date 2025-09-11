variable "datadog_api_key" {
  type      = string
  sensitive = true
}

variable "datadog_app_key" {
  type      = string
  sensitive = true
}

variable "datadog_api_url" {
  type    = string
  default = "ap1.datadoghq.com"

}

variable "notify" {
  type    = string
  default = "han.tnnb@gmail.com"
}

variable "discord_webhook_url" {
  type = string
}
