terraform {
  backend "gcs" {}
  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.0"
    }
  }
}


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

variable "name_prefix" {
  type = string
}

variable "discord_webhook_url" {
  type = string
}

provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  api_url = var.datadog_api_url
}
