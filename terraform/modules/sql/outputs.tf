output "sql_server_name" {
  value = azurerm_mssql_server.this.name
}

output "sql_database_name" {
  value = azurerm_mssql_database.this.name
}

output "sql_connection_string" {
  value     = local.connection_string
  sensitive = true
}
