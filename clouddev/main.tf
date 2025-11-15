# ==============================================================================
# AUTOMATED TDE KEY AND SQL MI DEPLOYMENT
# ==============================================================================
# This configuration automatically:
# 1. Creates unique TDE keys for each SQL MI
# 2. Deploys SQL MI with the key
# 3. Grants Key Vault access to SQL MI identity
# ==============================================================================

# ------------------------------------------------------------------------------
# STEP 1: Generate Random Passwords
# ------------------------------------------------------------------------------
resource "random_password" "sqlmi_admin" {
  for_each = var.sqlmi_instances

  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
}

# ------------------------------------------------------------------------------
# STEP 2: Create Unique TDE Keys for Each SQL MI
# ------------------------------------------------------------------------------
# Only create keys for instances that require CMK (tde_cmk_enabled = true)
resource "azurerm_key_vault_key" "sqlmi_tde" {
  for_each = {
    for key, instance in var.sqlmi_instances :
    key => instance
    if try(instance.tde_cmk_enabled, false) == true
  }

  name         = "key-${each.value.name}-tde"  # Unique key per SQL MI
  key_vault_id = data.azurerm_key_vault.sqlmi.id
  key_type     = "RSA"
  key_size     = 3072
  
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"  # Rotate 30 days before expiry
    }

    expire_after         = "P90D"  # Keys expire after 90 days
    notify_before_expiry = "P29D"  # Notify 29 days before expiry
  }

  tags = merge(
    local.common_tags,
    {
      Purpose      = "TDE-CMK"
      SQLMIName    = each.value.name
      Environment  = var.environment
      ManagedBy    = "Terraform"
      AutoRotation = "Enabled"
    }
  )
}

# ------------------------------------------------------------------------------
# STEP 3: Store Passwords in Key Vault
# ------------------------------------------------------------------------------
resource "azurerm_key_vault_secret" "sqlmi_admin_password" {
  for_each = var.sqlmi_instances

  name         = "${each.value.name}-admin-password"
  value        = random_password.sqlmi_admin[each.key].result
  key_vault_id = data.azurerm_key_vault.sqlmi.id

  tags = merge(
    local.common_tags,
    {
      SQLMIName = each.value.name
      Purpose   = "SQLMIAdminPassword"
    }
  )

  depends_on = [azurerm_key_vault_key.sqlmi_tde]
}

# ------------------------------------------------------------------------------
# STEP 4: Deploy SQL Managed Instances
# ------------------------------------------------------------------------------
module "sqlmi" {
  source = "../../modules/sqlmi"

  for_each = var.sqlmi_instances

  # Required parameters
  name                         = each.value.name
  resource_group_name          = each.value.resource_group_name
  location                     = each.value.location
  administrator_login          = each.value.administrator_login
  administrator_login_password = random_password.sqlmi_admin[each.key].result
  license_type                 = each.value.license_type
  sku_name                     = each.value.sku_name
  storage_size_in_gb           = each.value.storage_size_in_gb
  subnet_id                    = each.value.subnet_id
  vcores                       = each.value.vcores

  # Optional parameters
  collation                          = each.value.collation
  dns_zone_partner_id                = each.value.dns_zone_partner_id
  maintenance_configuration_name     = each.value.maintenance_configuration_name
  minimum_tls_version                = each.value.minimum_tls_version
  proxy_override                     = each.value.proxy_override
  public_data_endpoint_enabled       = each.value.public_data_endpoint_enabled
  timezone_id                        = each.value.timezone_id
  zone_redundant_enabled             = each.value.zone_redundant_enabled
  storage_account_type               = each.value.storage_account_type
  advanced_threat_protection_enabled = each.value.advanced_threat_protection_enabled

  # Security configurations
  security_alert_policy       = each.value.security_alert_policy
  vulnerability_assessment    = each.value.vulnerability_assessment
  storage_account_resource_id = each.value.storage_account_resource_id
  
  # Transparent Data Encryption - Automatically use created key
  transparent_data_encryption = try(each.value.tde_cmk_enabled, false) ? merge(
    try(each.value.transparent_data_encryption, {}),
    {
      auto_rotation_enabled = true
      key_vault_key_id      = azurerm_key_vault_key.sqlmi_tde[each.key].id
    }
  ) : try(each.value.transparent_data_encryption, {})
  
  active_directory_administrator = each.value.active_directory_administrator

  # Failover group
  failover_group = each.value.failover_group

  # Databases
  databases = each.value.databases

  # Diagnostic settings
  diagnostic_settings = each.value.diagnostic_settings

  # Resource lock
  lock = each.value.lock

  # Managed identities - System assigned required for Key Vault access
  managed_identities = merge(
    each.value.managed_identities,
    {
      system_assigned = true  # Force system assigned for TDE
    }
  )

  # Private endpoints
  private_endpoints                        = each.value.private_endpoints
  private_endpoints_manage_dns_zone_group = each.value.private_endpoints_manage_dns_zone_group

  # Role assignments
  role_assignments = each.value.role_assignments

  # Retry configuration
  retry = each.value.retry

  # Timeouts
  timeouts = each.value.timeouts

  # Tags
  tags = merge(
    local.common_tags,
    each.value.tags,
    {
      TDEKeyId = try(each.value.tde_cmk_enabled, false) ? azurerm_key_vault_key.sqlmi_tde[each.key].id : "ServiceManaged"
    }
  )

  # Telemetry
  enable_telemetry = var.enable_telemetry

  depends_on = [
    azurerm_key_vault_secret.sqlmi_admin_password,
    azurerm_key_vault_key.sqlmi_tde
  ]
}

# ------------------------------------------------------------------------------
# STEP 5: Grant Key Vault Access to SQL MI Managed Identities
# ------------------------------------------------------------------------------
# Grant each SQL MI access to its specific TDE key
resource "azurerm_key_vault_access_policy" "sqlmi_tde_access" {
  for_each = {
    for key, instance in var.sqlmi_instances :
    key => instance
    if try(instance.tde_cmk_enabled, false) == true
  }

  key_vault_id = data.azurerm_key_vault.sqlmi.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = module.sqlmi[each.key].system_assigned_mi_principal_id

  key_permissions = [
    "Get",
    "List",
    "WrapKey",
    "UnwrapKey",
  ]

  depends_on = [module.sqlmi]
}

# # Alternative: Using RBAC (Recommended for new deployments)
# resource "azurerm_role_assignment" "sqlmi_key_vault_crypto" {
#   for_each = {
#     for key, instance in var.sqlmi_instances :
#     key => instance
#     if try(instance.tde_cmk_enabled, false) == true && var.use_key_vault_rbac == true
#   }

#   scope                = azurerm_key_vault_key.sqlmi_tde[each.key].resource_versionless_id
#   role_definition_name = "Key Vault Crypto Service Encryption User"
#   principal_id         = module.sqlmi[each.key].system_assigned_mi_principal_id

#   depends_on = [module.sqlmi]
# }

# # ------------------------------------------------------------------------------
# # STEP 6: Grant Storage Account Access for Vulnerability Assessments
# # ------------------------------------------------------------------------------
# resource "azurerm_role_assignment" "sqlmi_storage_access" {
#   for_each = {
#     for key, instance in var.sqlmi_instances :
#     key => instance
#     if instance.vulnerability_assessment != null
#   }

#   scope                = each.value.storage_account_resource_id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = module.sqlmi[each.key].system_assigned_mi_principal_id

#   depends_on = [module.sqlmi]
# }

# ------------------------------------------------------------------------------
# DATA SOURCES
# ------------------------------------------------------------------------------
data "azurerm_client_config" "current" {}