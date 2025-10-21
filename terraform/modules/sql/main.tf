resource "azurerm_mssql_server" "this" {
  name                         = "${var.cluster_name}-sql"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"

  administrator_login          = var.admin_username
  administrator_login_password = var.admin_password

  # relaxed network settings for test environments
  public_network_access_enabled = true

  tags = merge(var.tags, {
    ManagedBy = "Terragrunt"
  })
}

resource "azurerm_mssql_database" "this" {
  name           = "testdb"
  server_id      = azurerm_mssql_server.this.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb    = 2
  sku_name       = "Basic"

  tags = var.tags
}

# Build connection string
locals {
  connection_string = "Server=${azurerm_mssql_server.this.fully_qualified_domain_name};Database=${azurerm_mssql_database.this.name};User Id=${var.admin_username};Password=${var.admin_password};Encrypt=true;TrustServerCertificate=true;"
}
