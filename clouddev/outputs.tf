# ============================================================================
# SQL MANAGED INSTANCE OUTPUTS
# ============================================================================

output "sqlmi_instances" {
  description = "Map of SQL Managed Instance details"
  value = {
    for key, instance in module.sqlmi : key => {
      id                  = instance.resource_id
      name                = instance.name
      fqdn                = instance.fqdn
      principal_id        = instance.system_assigned_mi_principal_id
      identity            = instance.managed_identities
      private_endpoint_id = try(instance.private_endpoints["primary"].id, null)
    }
  }
}

output "sqlmi_connection_strings" {
  description = "Connection strings for SQL Managed Instances (excluding passwords)"
  value = {
    for key, instance in module.sqlmi : key => {
      fqdn                  = instance.fqdn
      administrator_login   = var.sqlmi_instances[key].administrator_login
      password_key_vault_id = azurerm_key_vault_secret.sqlmi_admin_password[key].id
      example_connection_string = "Server=${instance.fqdn};Database=master;User Id=${var.sqlmi_instances[key].administrator_login};Password=<from_key_vault>;Encrypt=true;TrustServerCertificate=false;"
    }
  }
  sensitive = false
}

output "sqlmi_databases" {
  description = "Databases created in each SQL Managed Instance"
  value = {
    for key, instance in module.sqlmi : key => {
      databases = [for db_key, db in var.sqlmi_instances[key].databases : db.name]
    }
  }
}

output "key_vault_secret_ids" {
  description = "Key Vault secret IDs containing SQL MI admin passwords"
  value = {
    for key, secret in azurerm_key_vault_secret.sqlmi_admin_password : key => secret.id
  }
}