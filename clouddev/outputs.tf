# ============================================================================
# SQL MANAGED INSTANCE OUTPUTS
# ============================================================================
# ==============================================================================
# SQL MANAGED INSTANCE OUTPUTS
# ==============================================================================

output "sqlmi_instances" {
  description = "Map of SQL Managed Instance details"
  value = {
    for key, instance in module.sqlmi : key => {
      id                  = instance.resource_id
      name                = instance.name
      fqdn                = instance.fqdn
      principal_id        = instance.system_assigned_mi_principal_id
      tde_key_id          = try(azurerm_key_vault_key.sqlmi_tde[key].id, "ServiceManaged")
      tde_key_name        = try(azurerm_key_vault_key.sqlmi_tde[key].name, "ServiceManaged")
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
      password_secret_name  = azurerm_key_vault_secret.sqlmi_admin_password[key].name
      example_connection_string = "Server=${instance.fqdn};Database=master;User Id=${var.sqlmi_instances[key].administrator_login};Password=<from_key_vault>;Encrypt=true;TrustServerCertificate=false;"
    }
  }
  sensitive = false
}

output "tde_keys_summary" {
  description = "Summary of TDE keys created"
  value = {
    total_keys_created = length(azurerm_key_vault_key.sqlmi_tde)
    key_vault_name     = var.key_vault_name
    keys = {
      for key, tde_key in azurerm_key_vault_key.sqlmi_tde : key => {
        key_name          = tde_key.name
        key_id            = tde_key.id
        sqlmi_name        = var.sqlmi_instances[key].name
        auto_rotation     = true
        expiration_days   = 90
      }
    }
  }
}

output "deployment_summary" {
  description = "Deployment summary statistics"
  value = {
    total_sqlmi_instances = length(module.sqlmi)
    instances_with_cmk    = length(azurerm_key_vault_key.sqlmi_tde)
    instances_with_service_managed_key = length(module.sqlmi) - length(azurerm_key_vault_key.sqlmi_tde)
    
    by_sku = {
      for sku in distinct([for k, v in var.sqlmi_instances : v.sku_name]) :
      sku => length([for k, v in var.sqlmi_instances : v if v.sku_name == sku])
    }
    
    by_tde_type = {
      customer_managed = length([for k, v in var.sqlmi_instances : v if try(v.tde_cmk_enabled, false)])
      service_managed  = length([for k, v in var.sqlmi_instances : v if !try(v.tde_cmk_enabled, false)])
    }
    
    total_databases = sum([
      for k, v in var.sqlmi_instances : 
      length(try(v.databases, {}))
    ])
  }
}

output "key_vault_access_grants" {
  description = "Key Vault access grants created for SQL MI identities"
  value = {
    for key, instance in var.sqlmi_instances : key => {
      sqlmi_name        = instance.name
      principal_id      = module.sqlmi[key].system_assigned_mi_principal_id
      has_key_vault_access = try(instance.tde_cmk_enabled, false)
      access_method     = var.use_key_vault_rbac ? "RBAC" : "AccessPolicy"
    }
    if try(instance.tde_cmk_enabled, false)
  }
}

output "passwords_stored" {
  description = "Key Vault secrets created for SQL MI passwords"
  value = {
    key_vault_name = var.key_vault_name
    secrets_created = length(azurerm_key_vault_secret.sqlmi_admin_password)
    secret_names = [
      for key, secret in azurerm_key_vault_secret.sqlmi_admin_password : secret.name
    ]
  }
  sensitive = false
}

# Output for easy Azure CLI retrieval
output "retrieve_password_commands" {
  description = "Azure CLI commands to retrieve passwords"
  value = {
    for key, instance in var.sqlmi_instances : key => 
    "az keyvault secret show --vault-name ${var.key_vault_name} --name ${instance.name}-admin-password --query value -o tsv"
  }
}

output "verify_tde_commands" {
  description = "Azure CLI commands to verify TDE configuration"
  value = {
    for key, instance in var.sqlmi_instances : key => 
    "az sql mi tde-key show --managed-instance ${instance.name} --resource-group ${instance.resource_group_name}"
    if try(instance.tde_cmk_enabled, false)
  }
}