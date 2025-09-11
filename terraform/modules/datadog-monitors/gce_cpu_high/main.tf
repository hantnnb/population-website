# CPU used % = 100 - cpu.idle
resource "datadog_monitor" "gce_cpu_high" {
  name = "[${var.env}] GCE CPU usage high"
  type = "metric alert"

  # Example query:
  # avg(last_5m):100 - avg:system.cpu.idle{env:dev} by {host} > 95
  # query = "avg(last_${var.evaluation_window}m):100 - avg:system.cpu.idle{${var.tag_filter}} by {host} > ${var.critical_threshold}"
  query = "avg(last_${var.evaluation_window}m):100 - avg:system.cpu.idle by {host} > ${var.critical_threshold}"

  message = <<-EOT
    CPU usage is high on {{host.name}} ({{value}}%).
    Investigate top processes and workload spikes.
    ${var.notify}
  EOT

  tags = ["service:gce", "scope:cpu"]

  monitor_thresholds {
    warning  = var.warning_threshold
    critical = var.critical_threshold
  }

  notify_audit       = false
  notify_no_data     = true
  no_data_timeframe  = var.no_data_minutes
  renotify_interval  = var.renotify_minutes
  escalation_message = "Sustained CPU pressure on {{host.name}}. ${var.notify}"

  include_tags        = true
  require_full_window = true
  priority            = 3
}
