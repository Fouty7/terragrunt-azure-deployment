resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.cluster_name}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30  # minimum allowed value

  tags = var.tags
}

resource "azurerm_application_insights" "this" {
  name                = "${var.cluster_name}-insights"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"

  tags = var.tags
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.this.id
}

output "application_insights_instrumentation_key" {
  value     = azurerm_application_insights.this.instrumentation_key
  sensitive = true
}
