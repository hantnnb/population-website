module "gce_cpu_high" {
  source             = "../../../modules/datadog-monitors/gce_cpu_high"
  env                = "dev"
  tag_filter         = "env:dev" # add host: or service: tags if you want to narrow
  notify             = "${var.notify} @webhook.${datadog_webhook.discord.name}"
  warning_threshold  = 85
  critical_threshold = 95
}

# Discord webhook
# Source: https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/webhook
resource "datadog_webhook" "discord" {
  name           = "${var.name_prefix}-discord-webhook"
  url            = var.discord_webhook_url
  encode_as      = "json"
  custom_headers = jsonencode({ "custom" : "header" })
  payload        = jsonencode({ "custom" : "payload" })
}
