# General variables
variable "project_id" {}
variable "region" {}
variable "zone" {}
variable "bucket_name" {}
variable "prefix" {}
variable "environment" {}

# App variables
variable "app_name" {}
variable "name_prefix" {}
variable "ip_cidr_range" {}
variable "machine_type" {}
variable "image_family" {}
variable "image_project" {}
variable "startup_file" {}
variable "env_file" {}
variable "env_backend" {}

#Cloudflare
variable "cloudflare_api_token" {}
variable "type" {}
variable "zone_id" {}
variable "root_domain" {}