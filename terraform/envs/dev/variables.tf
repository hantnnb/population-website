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