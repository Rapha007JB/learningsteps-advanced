terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      # Lets destroy + apply be repeated with the same Key Vault name
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  subscription_id = var.subscription_id
}
