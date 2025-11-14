# Generate random passwords for SQL MI admin accounts
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

# Store passwords in Key Vault
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
}

# Deploy SQL Managed Instances
module "sqlmi" {
  source = "../modules/sqlmi"

  for_each = var.sqlmi_instances  # <-- Loop directly over the tfvars map!

  # Required parameters
  name                         = each.value.name
  resource_group_name          = each.value.resource_group_name
  location                     = each.value.location
  administrator_login          = each.value.administrator_login
  administrator_login_password = random_password.sqlmi_admin[each.key].result  # <-- Inject password here
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
  
  # Transparent Data Encryption - construct Key Vault key ID if tde_cmk_key_name is provided
  transparent_data_encryption = each.value.tde_cmk_key_name != null ? merge(
    each.value.transparent_data_encryption,
    {
      key_vault_key_id = "${data.azurerm_key_vault.sqlmi.vault_uri}keys/${each.value.tde_cmk_key_name}"
    }
  ) : each.value.transparent_data_encryption
  
  active_directory_administrator = each.value.active_directory_administrator

  # Failover group
  failover_group = each.value.failover_group

  # Databases
  databases = each.value.databases

  # Diagnostic settings
  diagnostic_settings = each.value.diagnostic_settings

  # Resource lock
  lock = each.value.lock

  # Managed identities
  managed_identities = each.value.managed_identities

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
    each.value.tags
  )

  # Telemetry
  enable_telemetry = var.enable_telemetry

  depends_on = [
    azurerm_key_vault_secret.sqlmi_admin_password
  ]
}