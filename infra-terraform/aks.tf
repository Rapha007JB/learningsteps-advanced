resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.cluster_name

  # Security: Enable RBAC (AVD-AZU-0042)
  role_based_access_control_enabled = true

  # Security: Restrict API server access (AVD-AZU-0041)
  api_server_access_profile {
    authorized_ip_ranges = var.authorized_ip_ranges
  }

  # Security: Enable network policy (AVD-AZU-0043)
  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr   = "10.100.0.0/16"
    dns_service_ip = "10.100.0.10"
  }

  default_node_pool {
    name           = "default"
    node_count     = var.node_count
    vm_size        = var.vm_size
    vnet_subnet_id = azurerm_subnet.aks.id

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type = "SystemAssigned"
  }

  # Lets pods mount Key Vault secrets (Secrets Store CSI driver)
  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  node_provisioning_profile {
    mode = "Manual"
  }
}
