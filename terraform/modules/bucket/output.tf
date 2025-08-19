output "bucket_name" { value = google_storage_bucket.le_backup.name }
output "bucket_url" { value = "gs://${google_storage_bucket.le_backup.name}" }