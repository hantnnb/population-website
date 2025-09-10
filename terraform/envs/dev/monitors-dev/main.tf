module "gce_cpu_high" {
  source             = "../../../modules/datadog-monitors/gce_cpu_high"
  env                = "dev"
  tag_filter         = "env:dev" # add host: or service: tags if you want to narrow
  notify             = var.notify
  warning_threshold  = 85
  critical_threshold = 95
}
