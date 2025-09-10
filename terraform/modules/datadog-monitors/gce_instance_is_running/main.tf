terraform {
  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.0"
    }
  }
}

# Create a new Datadog gce monitor
resource "datadog_monitor" "gce_instance_is_running" {
  name    = "[gce instance][${var.asset_lbnref}] - anomaly gce_instance_is_running"
  type    = "query alert"
  message = "This check verify the instance is running. See IRP for more informations. Notify: ${var.notify_to}"

  query = <<-EOT
    max(last_5m):avg:gcp.gce.instance.is_running{
      project_id:${var.project_id},
      instance-id:${var.instance_id}
    } < 1
  EOT

  notify_no_data    = false
  renotify_interval = 40

  notify_audit = true
  timeout_h    = 0
  include_tags = true

  require_full_window = var.full_window

  tags = [
    "template:${var.template}",
    "monitor_resource_name:gcp.gce.instance.is_running",
    "lbnref:${var.asset_lbnref}",
    "isprod:${var.isprod}",
    "severity:${var.severity}",
    "category:${var.category}",
    "type:incident",
    "kb:${var.kb}",
  ]
}
