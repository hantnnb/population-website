output "vm_ip" {
  value       = google_compute_address.static_eip.address
  description = "The external static IP of the VM"
}

output "vm_sa_email" { 
  value = google_service_account.vm_sa.email 
  }
  
output "vm_sa_name"  { 
  value = google_service_account.vm_sa.name 
  }