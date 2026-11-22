location     = "West Europe"
environment  = "dev"
cluster_name = "aks-learningsteps"
node_count   = 2
vm_size      = "Standard_D2s_v7"
acr_name     = "acrrawad8024"

# PostgreSQL
postgresql_database_name = "learning_journal"

# subscription_id and the DB password are NOT stored here.
# They come from TF_VAR_subscription_id and TF_VAR_postgresql_admin_password.
postgresql_sku_name = "GP_Standard_D2ds_v5"
