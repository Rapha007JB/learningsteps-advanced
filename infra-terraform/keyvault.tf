data "azurerm_client_config" "current" {}

locals {
  # Globally unique name derived from the ACR name suffix, e.g. kv-ls-1234
  key_vault_name = "kv-ls-${substr(var.acr_name, -4, -1)}"
}

resource "azurerm_key_vault" "kv" {
  name                       = local.key_vault_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  rbac_authorization_enabled = false # access policies are used instead of Azure RBAC
  purge_protection_enabled   = false # lab setting: allows destroy + re-apply

  network_acls {
    default_action = "Allow" # lab setting: Terraform and the pods reach it over the public endpoint
    bypass         = "AzureServices"
  }
}

# The identity running Terraform may manage secrets
resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
}

# The AKS Key Vault add-on identity may only read secrets (least privilege)
resource "azurerm_key_vault_access_policy" "aks_csi" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].object_id

  secret_permissions = ["Get", "List"]
}

# Connection string the pods will use - never stored in Git or Kubernetes manifests
resource "azurerm_key_vault_secret" "database_url" {
  name         = "database-url"
  value        = "postgresql://${var.postgresql_admin_username}:${var.postgresql_admin_password}@${azurerm_postgresql_flexible_server.postgres.fqdn}:5432/${var.postgresql_database_name}?sslmode=require"
  key_vault_id = azurerm_key_vault.kv.id
  content_type = "text/plain"

  depends_on = [azurerm_key_vault_access_policy.terraform]
}
