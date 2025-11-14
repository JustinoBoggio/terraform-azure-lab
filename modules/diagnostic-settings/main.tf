resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = var.name
  target_resource_id         = var.target_resource_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    # Only create blocks for logs that are enabled
    for_each = { for l in var.logs : l.category => l if l.enabled }

    content {
      category = enabled_log.value.category
    }
  }

  dynamic "metric" {
    for_each = { for m in var.metrics : m.category => m if m.enabled }

    content {
      category = metric.value.category
      enabled  = metric.value.enabled
    }
  }
}
