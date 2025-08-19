resource "google_storage_bucket" "le_backup" {
  name                        = var.bucket_name
  project                     = var.project_id
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  force_destroy               = false

  versioning {
    enabled = true
  }

  # Keep only the 5 newest versions of each object
  lifecycle_rule {
    action { type = "Delete" }
    condition { num_newer_versions = 5 }

  }

  lifecycle {
    prevent_destroy = true
  }

  public_access_prevention = "enforced"
}

# Grant the VM SA write access to objects (upload/download)
resource "google_storage_bucket_iam_member" "vm_object_admin" {
  bucket = google_storage_bucket.le_backup.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.vm_sa_email}"
}