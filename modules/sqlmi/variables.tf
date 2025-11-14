variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the this resource."
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}

variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Controls the Managed Identity configuration on this resource. The following properties can be specified:

- `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
- `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
DESCRIPTION
  nullable    = false
}

variable "private_endpoints" {
  type = map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
  default     = {}
  description = <<DESCRIPTION
A map of private endpoints to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the private endpoint. One will be generated if not set.
- `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. See `var.role_assignments` for more information.
- `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
- `tags` - (Optional) A mapping of tags to assign to the private endpoint.
- `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
- `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
- `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
- `application_security_group_resource_ids` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
- `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
- `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
- `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
- `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of this resource.
- `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `name` - The name of the IP configuration.
  - `private_ip_address` - The private IP address of the IP configuration.
DESCRIPTION
  nullable    = false
}

# This variable is used to determine if the private_dns_zone_group block should be included,
# or if it is to be managed externally, e.g. using Azure Policy.
# https://github.com/Azure/terraform-azurerm-avm-res-keyvault-vault/issues/32
# Alternatively you can use AzAPI, which does not have this issue.
variable "private_endpoints_manage_dns_zone_group" {
  type        = bool
  default     = true
  description = "Whether to manage private DNS zone groups with this module. If set to false, you must manage private DNS zone groups externally, e.g. using Azure Policy."
  nullable    = false
}

variable "retry" {
  type = object({
    mssql_managed_instance_security_alert_policy = optional(object({
      error_message_regex = optional(list(string), [
        "SqlServerAlertPolicyInProgress", # see #54
      ])
      interval_seconds     = optional(number)
      max_interval_seconds = optional(number)
    }), null)
    sql_managed_instance_patch_identities = optional(object({
      error_message_regex = optional(list(string), [
        "ConflictingServerOperation", # see #54
      ])
      interval_seconds     = optional(number)
      max_interval_seconds = optional(number)
    }), null)
    sql_advanced_threat_protection = optional(object({
      error_message_regex  = optional(list(string))
      interval_seconds     = optional(number)
      max_interval_seconds = optional(number)
    }), null)
  })
  default     = {}
  description = <<DESCRIPTION
The AzAPI resource retry configuration, per resource type.
Will retry up to the resource timeout, see `var.timeout`.

Each resource has the following attributes:

- `error_message_regex` - A list of regular expressions to match error messages for retrying the request.
- `interval_seconds` - The interval in seconds between retry attempts.
- `max_interval_seconds` - The maximum interval in seconds between retry attempts.
DESCRIPTION
  nullable    = false
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "timeout" {
  type = object({
    mssql_managed_instance_security_alert_policy = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }), {})
    sql_managed_instance_patch_identities = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }), {})
    sql_advanced_threat_protection = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
The resource-specific timeout configuration.
Values are a valid timespan, e.g. `1m`, `30s`, `5m30s`.
DESCRIPTION
  nullable    = false
}


variable "administrator_login" {
  type        = string
  description = "(Required) The administrator login name for the new SQL Managed Instance. Changing this forces a new resource to be created."
  nullable    = false
}

variable "administrator_login_password" {
  type        = string
  description = "(Required) The password associated with the `administrator_login` user. Needs to comply with Azure's [Password Policy](https://msdn.microsoft.com/library/ms161959.aspx)"
  nullable    = false
  sensitive   = true
}

variable "license_type" {
  type        = string
  description = "(Required) What type of license the Managed Instance will use. Possible values are `LicenseIncluded` and `BasePrice`."
  nullable    = false
}

variable "sku_name" {
  type        = string
  description = "(Required) Specifies the SKU Name for the SQL Managed Instance. Valid values include `GP_Gen4`, `GP_Gen5`, `GP_Gen8IM`, `GP_Gen8IH`, `BC_Gen4`, `BC_Gen5`, `BC_Gen8IM` or `BC_Gen8IH`."
  nullable    = false
}

variable "storage_size_in_gb" {
  type        = number
  description = "(Required) Maximum storage space for the SQL Managed instance. This should be a multiple of 32 (GB)."
  nullable    = false
}

variable "subnet_id" {
  type        = string
  description = "(Required) The subnet resource id that the SQL Managed Instance will be associated with. Changing this forces a new resource to be created."
  nullable    = false
}

variable "vcores" {
  type        = number
  description = "(Required) Number of cores that should be assigned to the SQL Managed Instance. Values can be `8`, `16`, or `24` for Gen4 SKUs, or `4`, `6`, `8`, `10`, `12`, `16`, `20`, `24`, `32`, `40`, `48`, `56`, `64`, `80`, `96` or `128` for Gen5 SKUs."
  nullable    = false
}

variable "active_directory_administrator" {
  type = object({
    azuread_authentication_only = optional(bool)
    login_username              = optional(string)
    object_id                   = optional(string)
    tenant_id                   = optional(string)
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  })
  default     = {}
  description = <<-DESCRIPTION
 - `azuread_authentication_only` - (Optional) When `true`, only permit logins from AAD users and administrators. When `false`, also allow local database users.
 - `login_username` - (Required) The login name of the principal to set as the Managed Instance Administrator.
 - `object_id` - (Required) The Object ID of the principal to set as the Managed Instance Administrator.
 - `tenant_id` - (Required) The Azure Active Directory Tenant ID.

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 30 minutes) Used when creating the SQL Active Directory Administrator.
 - `delete` - (Defaults to 30 minutes) Used when deleting the SQL Active Directory Administrator.
 - `read` - (Defaults to 5 minutes) Used when retrieving the SQL Active Directory Administrator.
 - `update` - (Defaults to 30 minutes) Used when updating the SQL Active Directory Administrator.
DESCRIPTION
  nullable    = false
}

variable "advanced_threat_protection_enabled" {
  type        = bool
  default     = true
  description = "(Optional) Whether to enabled Defender for SQL Advanced Threat Protection."
  nullable    = false
}

variable "collation" {
  type        = string
  default     = null
  description = "(Optional) Specifies how the SQL Managed Instance will be collated. Default value is `SQL_Latin1_General_CP1_CI_AS`. Changing this forces a new resource to be created."
}

variable "dns_zone_partner_id" {
  type        = string
  default     = null
  description = "(Optional) The ID of the SQL Managed Instance which will share the DNS zone. This is a prerequisite for creating an `azurerm_mssql_managed_instance_failover_group`. Setting this after creation forces a new resource to be created."
}

variable "maintenance_configuration_name" {
  type        = string
  default     = null
  description = "(Optional) The name of the Public Maintenance Configuration window to apply to the SQL Managed Instance. Valid values include `SQL_Default` or an Azure Location in the format `SQL_{Location}_MI_{Size}`(for example `SQL_EastUS_MI_1`). Defaults to `SQL_Default`."
}

variable "minimum_tls_version" {
  type        = string
  default     = "1.2"
  description = "(Optional) The Minimum TLS Version. Default value is `1.2` Valid values include `1.0`, `1.1`, `1.2`."
}

variable "proxy_override" {
  type        = string
  default     = null
  description = "(Optional) Specifies how the SQL Managed Instance will be accessed. Default value is `Default`. Valid values include `Default`, `Proxy`, and `Redirect`."
}

variable "public_data_endpoint_enabled" {
  type        = bool
  default     = null
  description = "(Optional) Is the public data endpoint enabled? Default value is `false`."
}

variable "security_alert_policy" {
  type = object({
    disabled_alerts              = optional(set(string))
    email_account_admins_enabled = optional(bool)
    email_addresses              = optional(set(string))
    enabled                      = optional(bool)
    retention_days               = optional(number)
    storage_account_access_key   = optional(string)
    storage_endpoint             = optional(string)
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  })
  default     = {}
  description = <<-DESCRIPTION
 - `disabled_alerts` - (Optional) Specifies an array of alerts that are disabled. Possible values are `Sql_Injection`, `Sql_Injection_Vulnerability`, `Access_Anomaly`, `Data_Exfiltration`, `Unsafe_Action` and `Brute_Force`.
 - `email_account_admins_enabled` - (Optional) Boolean flag which specifies if the alert is sent to the account administrators or not. Defaults to `false`.
 - `email_addresses` - (Optional) Specifies an array of email addresses to which the alert is sent.
 - `enabled` - (Optional) Specifies the state of the Security Alert Policy, whether it is enabled or disabled. Possible values are `true`, `false`.
 - `retention_days` - (Optional) Specifies the number of days to keep in the Threat Detection audit logs. Defaults to `0`.
 - `storage_account_access_key` - (Optional) Specifies the identifier key of the Threat Detection audit storage account. This is mandatory when you use `storage_endpoint` to specify a storage account blob endpoint.
 - `storage_endpoint` - (Optional) Specifies the blob storage endpoint (e.g. https://example.blob.core.windows.net). This blob storage will hold all Threat Detection audit logs.

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 30 minutes) Used when creating the MS SQL Managed Instance Security Alert Policy.
 - `delete` - (Defaults to 30 minutes) Used when deleting the MS SQL Managed Instance Security Alert Policy.
 - `read` - (Defaults to 5 minutes) Used when retrieving the MS SQL Managed Instance Security Alert Policy.
 - `update` - (Defaults to 30 minutes) Used when updating the MS SQL Managed Instance Security Alert Policy.
DESCRIPTION
  nullable    = false
}

variable "storage_account_resource_id" {
  type        = string
  default     = null
  description = <<-DESCRIPTION
(Optional) Storage Account to store vulnerability assessments.

The System Assigned Managed Identity will be granted Storage Blob Data Contributor over this storage account.

Note these limitations documented in Microsoft Learn - <https://learn.microsoft.com/en-us/azure/azure-sql/database/sql-database-vulnerability-assessment-storage?view=azuresql#store-va-scan-results-for-azure-sql-managed-instance-in-a-storage-account-that-can-be-accessed-behind-a-firewall-or-vnet>

* User Assigned MIs are not supported
* The storage account firewall public network access must be allowed.  If "Enabled from selected virtual networks and IP addresses" is set (recommended), the SQL MI subnet ID must be added to the storage account firewall.

DESCRIPTION
}

variable "storage_account_type" {
  type        = string
  default     = "ZRS"
  description = "(Optional) Specifies the storage account type used to store backups for this database. Changing this forces a new resource to be created. Possible values are `GRS`, `LRS` and `ZRS`. Defaults to `GRS`."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = null
  description = <<-DESCRIPTION
 - `create` - (Defaults to 24 hours) Used when creating the Microsoft SQL Managed Instance.
 - `delete` - (Defaults to 24 hours) Used when deleting the Microsoft SQL Managed Instance.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Microsoft SQL Managed Instance.
 - `update` - (Defaults to 24 hours) Used when updating the Microsoft SQL Managed Instance.
DESCRIPTION
}

variable "timezone_id" {
  type        = string
  default     = null
  description = "(Optional) The TimeZone ID that the SQL Managed Instance will be operating in. Default value is `UTC`. Changing this forces a new resource to be created."
}

variable "transparent_data_encryption" {
  type = object({
    auto_rotation_enabled = optional(bool)
    key_vault_key_id      = optional(string)
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  })
  default     = {}
  description = <<-DESCRIPTION
 - `auto_rotation_enabled` - (Optional) When enabled, the SQL Managed Instance will continuously check the key vault for any new versions of the key being used as the TDE protector. If a new version of the key is detected, the TDE protector on the SQL Managed Instance will be automatically rotated to the latest key version within 60 minutes.
 - `key_vault_key_id` - (Optional) To use customer managed keys from Azure Key Vault, provide the AKV Key ID. To use service managed keys, omit this field.

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 30 minutes) Used when creating the MSSQL.
 - `delete` - (Defaults to 30 minutes) Used when deleting the MSSQL.
 - `read` - (Defaults to 5 minutes) Used when retrieving the MSSQL.
 - `update` - (Defaults to 30 minutes) Used when updating the MSSQL.
DESCRIPTION
}

variable "vulnerability_assessment" {
  type = object({
    storage_account_access_key = optional(string)
    storage_container_path     = optional(string)
    storage_container_sas_key  = optional(string)
    recurring_scans = optional(object({
      email_subscription_admins = optional(bool)
      emails                    = optional(list(string))
      enabled                   = optional(bool)
    }))
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  })
  default     = null
  description = <<-DESCRIPTION
 - `storage_account_access_key` - (Optional) Specifies the identifier key of the storage account for vulnerability assessment scan results. If `storage_container_sas_key` isn't specified, `storage_account_access_key` is required.  Set to `null` if the storage account is protected by a resource firewall.
 - `storage_container_path` - (Required) A blob storage container path to hold the scan results (e.g. <https://myStorage.blob.core.windows.net/VaScans/>).
 - `storage_container_sas_key` - (Optional) A shared access signature (SAS Key) that has write access to the blob container specified in `storage_container_path` parameter. If `storage_account_access_key` isn't specified, `storage_container_sas_key` is required.  Set to `null` if the storage account is protected by a resource firewall.

 ---
 `recurring_scans` block supports the following:
 - `email_subscription_admins` - (Optional) Boolean flag which specifies if the schedule scan notification will be sent to the subscription administrators. Defaults to `true`.
 - `emails` - (Optional) Specifies an array of e-mail addresses to which the scan notification is sent.
 - `enabled` - (Optional) Boolean flag which specifies if recurring scans is enabled or disabled. Defaults to `false`.

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 60 minutes) Used when creating the Vulnerability Assessment.
 - `delete` - (Defaults to 60 minutes) Used when deleting the Vulnerability Assessment.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Vulnerability Assessment.
 - `update` - (Defaults to 60 minutes) Used when updating the Vulnerability Assessment.
DESCRIPTION
}

variable "zone_redundant_enabled" {
  type        = bool
  default     = true
  description = "(Optional) If true, the SQL Managed Instance will be deployed with zone redundancy.  Defaults to `true`."
}

