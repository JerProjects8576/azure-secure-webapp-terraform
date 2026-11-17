project     = "secweb"
environment = "dev"
location    = "westeurope"

vnet_address_space = "10.10.0.0/16"
app_service_sku    = "B1"
log_retention_days = 30

# Fill these in to be able to set the secret from your own machine:
#   key_vault_allowed_ips      = ["<your public IP>"]
#   key_vault_admin_object_ids = ["<output of: az ad signed-in-user show --query id -o tsv>"]
key_vault_allowed_ips      = []
key_vault_admin_object_ids = []
