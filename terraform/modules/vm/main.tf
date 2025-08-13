resource "google_service_account" "vm-sa" {
  account_id   = "${var.name_prefix}-vm-sa"
  display_name = "Custom SA for VM Instance"
  # member = "serviceAccount:${google_service_account.vm-sa.email}"
}

data "google_compute_image" "ubuntu" {
  family  = var.image_family
  project = var.image_project
}

# Reserved static eip
resource "google_compute_address" "static-eip" {
  name   = "${var.name_prefix}-ip"
  region = var.region
}

resource "google_compute_instance" "vm-instance" {
  name         = "${var.name_prefix}-vm"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["web-${var.name_prefix}"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork

    access_config {
      nat_ip = google_compute_address.static-eip.address
    }
  }

  metadata = {
    env_file    = var.env_file
    env_backend = var.env_backend
  }

  metadata_startup_script = file("${path.module}/../../envs/dev/${var.startup_file}")

  service_account {
    email  = google_service_account.vm-sa.email
    scopes = ["cloud-platform"]
  }

  # Explicit dependency to service account
  depends_on = [google_service_account.vm-sa]
}