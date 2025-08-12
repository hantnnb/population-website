# VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.name_prefix}-vpc"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.name_prefix}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.ip_cidr_range
}

# Firewall rule - HTTP
resource "google_compute_firewall" "allow-http" {
  name    = "${var.name_prefix}-allow-http"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-${var.name_prefix}"]
}

# Firewall rule - HTTPS
resource "google_compute_firewall" "allow-https" {
  name    = "${var.name_prefix}-allow-https"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-${var.name_prefix}"]
}

# Firewall rule - SSH
resource "google_compute_firewall" "allow-ssh" {
  name    = "${var.name_prefix}-allow-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-${var.name_prefix}"]
}