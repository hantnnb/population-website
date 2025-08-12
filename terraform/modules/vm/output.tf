output "vm_ip" {
  value       = google_compute_address.static-eip.address
  description = "The external static IP of the VM"
}