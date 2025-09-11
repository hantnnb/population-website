module "gce_cpu_high" {
  source             = "../../../modules/datadog-monitors/gce_cpu_high"
  env                = "dev"
  tag_filter         = "env:dev" # add host: or service: tags if you want to narrow
  notify             = var.notify
  warning_threshold  = 85
  critical_threshold = 95
}

# Discord webhook
# Source: https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/webhook
resource "datadog_webhook" "discord" {
    name = "${var.name_prefix}-webhook"
    url = "https://discord.com/api/webhooks/1415527754513911809/bxypE7OejW1rvHPNS0CTF6C0rdXwICxDMB7c7A1-39HeIE5hX1q1_LD2_B7gEEB02wkH"
    encode_as = "json"
    custom_headers = jsonencode({ "custom" : "header" })
    payload        = jsonencode({ "custom" : "payload" })
}
