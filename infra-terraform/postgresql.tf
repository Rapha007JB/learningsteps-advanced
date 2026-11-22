# PostgreSQL Flexible Server - private access only (no public endpoint)
resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = "psql-${var.environment}-${var.cluster_name}"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  version                = var.postgresql_version
  administrator_login    = var.postgresql_admin_username
  administrator_password = var.postgresql_admin_password
  storage_mb             = var.postgresql_storage_mb
  sku_name               = var.postgresql_sku_name
  zone                   = "1"

  delegated_subnet_id           = azurerm_subnet.db.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  public_network_access_enabled = false

  # Zone is set at creation time and cannot be changed
  lifecycle {
    ignore_changes = [zone]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "app_db" {
  name      = var.postgresql_database_name
  server_id = azurerm_postgresql_flexible_server.postgres.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}
