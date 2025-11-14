
# Data source to fetch Key Vault for TDE CMK keys
data "azurerm_key_vault" "sqlmi" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group_name
}