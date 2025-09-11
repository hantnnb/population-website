module "gce_cpu_high" {
  source = "../../../modules/datadog-monitors/gce_cpu_high"
  # env    = "dev"
  tag_filter         = "host:pplt-dev-vm"
  notify             = "${var.notify} @webhook.${datadog_webhook.discord.name}"
  warning_threshold  = 80
  critical_threshold = 95
}

# Discord webhook
# Source: https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/webhook
resource "datadog_webhook" "discord" {
  name           = "discord-webhook"
  url            = var.discord_webhook_url
  encode_as      = "json"
  custom_headers = jsonencode({ "custom" : "header" })
  payload        = jsonencode({ "custom" : "payload" })
}
