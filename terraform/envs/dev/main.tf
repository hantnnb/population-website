terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.47.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.8.2"
    }

  }

  backend "gcs" {
    bucket = "population-website-terraform-state"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}


provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

locals {
  name_prefix = "${var.app_name}-${var.environment}"
}

# Enable required APIs
resource "google_project_service" "services" {
  for_each = toset([
    "compute.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ])

  service            = each.value
  disable_on_destroy = false
}

# Network module
module "network" {
  source        = "../../modules/network"
  region        = var.region
  ip_cidr_range = var.ip_cidr_range
  name_prefix   = local.name_prefix

  depends_on = [google_project_service.services]
}

module "vm" {
  source        = "../../modules/vm"
  name_prefix   = local.name_prefix
  machine_type  = var.machine_type
  zone          = var.zone
  environment   = var.environment
  image_family  = var.image_family
  image_project = var.image_project

  startup_file = var.startup_file
  region       = var.region
  network      = module.network.network_id
  subnetwork   = module.network.subnet_id
  env_file     = var.env_file
  env_backend  = var.env_backend

  depends_on = [google_project_service.services]
}

module "client_dns" {
  source     = "../../modules/dns_record"
  name       = local.name_prefix
  ip_address = module.vm.vm_ip
  zone_id    = var.zone_id
  isProxied  = true
  dns_type   = "A"
  ttl        = 1
  # When a DNS record is marked as `proxied` the TTL must be 1 as Cloudflare will control the TTL internally.
}

module "api_dns" {
  source     = "../../modules/dns_record"
  name       = "api.${local.name_prefix}"
  ip_address = module.vm.vm_ip
  zone_id    = var.zone_id
  isProxied  = false
  dns_type   = "A"
  ttl        = 300
}