output "key_vault_name" {
  value       = azurerm_key_vault.kv.name
  description = "Key Vault holding the database connection string"
}

output "tenant_id" {
  value       = data.azurerm_client_config.current.tenant_id
  description = "Azure AD tenant ID (needed by the SecretProviderClass)"
}

output "key_vault_csi_client_id" {
  value       = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].client_id
  description = "Client ID of the identity the pods use to read Key Vault"
}
