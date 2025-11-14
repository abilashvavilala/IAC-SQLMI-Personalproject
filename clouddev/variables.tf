variable "sqlmi_instances" {
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    # Admin
    administrator_login         = string
    administrator_password      = string
    license_type                = string
    sku_name                    = string
    storage_size_in_gb          = number
    vnet_subnet_id              = string
    vcores                      = number
    collation                   = optional(string)
    dns_zone_partner_id         = optional(string)
    maintenance_configuration_name = optional(string)
    minimum_tls_version         = optional(string, "1.2")
    proxy_override              = optional(string)
    public_data_endpoint_enabled = optional(bool)
    advanced_threat_protection_enabled = optional(bool, true)
    zone_redundant_enabled      = optional(bool, true)
    timezone_id                 = optional(string, "UTC")

    # Security & Encryption
    security_alert_policy = optional(object({
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
    }), {})

    transparent_data_encryption = optional(object({
      auto_rotation_enabled = optional(bool)
      key_vault_key_id      = optional(string)
      timeouts = optional(object({
        create = optional(string)
        delete = optional(string)
        read   = optional(string)
        update = optional(string)
      }))
    }), {})

    vulnerability_assessment = optional(object({
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
    }))

    # AD Admin
    active_directory_administrator = optional(object({
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
    }), {})

    # Failover
    failover_group = optional(map(object({
      location                                  = optional(string)
      name                                      = optional(string)
      partner_managed_instance_id               = optional(string)
      readonly_endpoint_failover_policy_enabled = optional(bool)
      read_write_endpoint_failover_policy = optional(object({
        grace_minutes = optional(number)
        mode          = optional(string)
      }))
      timeouts = optional(object({
        create = optional(string)
        delete = optional(string)
        read   = optional(string)
        update = optional(string)
      }))
    })), {})

    # Databases
    databases = optional(map(object({
      name                      = string
      short_term_retention_days = optional(number)
      tags                      = optional(map(string))
      long_term_retention_policy = optional(object({
        monthly_retention = optional(string)
        week_of_year      = optional(number)
        weekly_retention  = optional(string)
        yearly_retention  = optional(string)
      }))
      point_in_time_restore = optional(object({
        restore_point_in_time = string
        source_database_id    = string
      }))
      timeouts = optional(object({
        create = optional(string)
        delete = optional(string)
        read   = optional(string)
        update = optional(string)
      }))
    })), {})

    # Diagnostic Settings
    diagnostic_settings = optional(map(object({
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
    })), {})

    # Locks
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }))

    # Managed Identities
    managed_identities = optional(object({
      system_assigned            = optional(bool, false)
      user_assigned_resource_ids = optional(set(string), [])
    }), {})

    # Private Endpoints
    private_endpoints = optional(map(object({
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
    })), {})

    # New additions
    private_endpoints_manage_dns_zone_group = optional(bool, true)
    retry = optional(object({
      mssql_managed_instance_security_alert_policy = optional(object({
        error_message_regex = optional(list(string), [
          "SqlServerAlertPolicyInProgress",
        ])
        interval_seconds     = optional(number)
        max_interval_seconds = optional(number)
      }), null)
      sql_managed_instance_patch_identities = optional(object({
        error_message_regex = optional(list(string), [
          "ConflictingServerOperation",
        ])
        interval_seconds     = optional(number)
        max_interval_seconds = optional(number)
      }), null)
      sql_advanced_threat_protection = optional(object({
        error_message_regex  = optional(list(string))
        interval_seconds     = optional(number)
        max_interval_seconds = optional(number)
      }), null)
    }), {})
    tags = optional(map(string), {
        default = null
        description = "A map of tags to assign to the resource."
    })

    
  }))
}


################ new sqlmi object creation ######

#################################################

variable "sqlmi_instances" {
  description = "Map of SQL Managed Instances to deploy with all supported configurations"
  type = map(object({
    # Required Basic Configuration
    name                = string
    resource_group_name = string
    location            = string

    # Required Authentication & SKU
    administrator_login    = string
    administrator_password = string # Fixed from administrator_login_password
    license_type          = string
    sku_name              = string
    storage_size_in_gb    = number
    subnet_id             = string # Fixed from vnet_subnet_id
    vcores                = number

    # Optional Basic Configuration
    collation                      = optional(string)
    dns_zone_partner_id            = optional(string)
    maintenance_configuration_name = optional(string)
    minimum_tls_version            = optional(string, "1.2")
    proxy_override                 = optional(string)
    public_data_endpoint_enabled   = optional(bool)
    timezone_id                    = optional(string, "UTC")
    zone_redundant_enabled         = optional(bool, true)
    
    # Storage backup redundancy - MISSING in your original
    storage_account_type = optional(string, "ZRS") # For backup storage redundancy

    # Advanced Threat Protection - Fixed structure
    advanced_threat_protection_enabled = optional(bool, true)

    # Security Alert Policy - Fixed structure
    security_alert_policy = optional(object({
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
    }), {})

    # Transparent Data Encryption
    transparent_data_encryption = optional(object({
      auto_rotation_enabled = optional(bool)
      key_vault_key_id      = optional(string)
      timeouts = optional(object({
        create = optional(string)
        delete = optional(string)
        read   = optional(string)
        update = optional(string)
      }))
    }), {})

    # Vulnerability Assessment
    vulnerability_assessment = optional(object({
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
    }))

    # MISSING: Storage account for vulnerability assessment
    storage_account_resource_id = optional(string)

    # Azure AD Administrator
    active_directory_administrator = optional(object({
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
    }), {})

    # Failover Group
    failover_group = optional(map(object({
      location                                  = optional(string)
      name                                      = optional(string)
      partner_managed_instance_id               = optional(string)
      readonly_endpoint_failover_policy_enabled = optional(bool)
      read_write_endpoint_failover_policy = optional(object({
        grace_minutes = optional(number)
        mode          = optional(string)
      }))
      timeouts = optional(object({
        create = optional(string)
        delete = optional(string)
        read   = optional(string)
        update = optional(string)
      }))
    })), {})

    # Databases
    databases = optional(map(object({
      name                      = string
      short_term_retention_days = optional(number)
      tags                      = optional(map(string))
      long_term_retention_policy = optional(object({
        monthly_retention = optional(string)
        week_of_year      = optional(number)
        weekly_retention  = optional(string)
        yearly_retention  = optional(string)
      }))
      point_in_time_restore = optional(object({
        restore_point_in_time = string
        source_database_id    = string
      }))
      timeouts = optional(object({
        create = optional(string)
        delete = optional(string)
        read   = optional(string)
        update = optional(string)
      }))
    })), {})

    # Diagnostic Settings
    diagnostic_settings = optional(map(object({
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
    })), {})

    # Resource Lock
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }))

    # Managed Identities
    managed_identities = optional(object({
      system_assigned            = optional(bool, false)
      user_assigned_resource_ids = optional(set(string), [])
    }), {})

    # Private Endpoints
    private_endpoints = optional(map(object({
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
    })), {})

    # Private Endpoints DNS Management
    private_endpoints_manage_dns_zone_group = optional(bool, true)

    # Role Assignments - MISSING in your original
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

    # Retry Configuration
    retry = optional(object({
      mssql_managed_instance_security_alert_policy = optional(object({
        error_message_regex = optional(list(string), [
          "SqlServerAlertPolicyInProgress",
        ])
        interval_seconds     = optional(number)
        max_interval_seconds = optional(number)
      }), null)
      sql_managed_instance_patch_identities = optional(object({
        error_message_regex = optional(list(string), [
          "ConflictingServerOperation",
        ])
        interval_seconds     = optional(number)
        max_interval_seconds = optional(number)
      }), null)
      sql_advanced_threat_protection = optional(object({
        error_message_regex  = optional(list(string))
        interval_seconds     = optional(number)
        max_interval_seconds = optional(number)
      }), null)
    }), {})

    # Timeouts - MISSING in your original
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))

    # Timeouts for sub-resources - MISSING in your original
    timeouts_resource_specific = optional(object({
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
    }), {})

    # Tags - Fixed syntax error in your original
    tags = optional(map(string), {})
  }))

  default = {}

  validation {
    condition = alltrue([
      for k, v in var.sqlmi_instances :
      contains(["GP_Gen4", "GP_Gen5", "GP_Gen8IM", "GP_Gen8IH", "BC_Gen4", "BC_Gen5", "BC_Gen8IM", "BC_Gen8IH"], v.sku_name)
    ])
    error_message = "SKU must be one of: GP_Gen4, GP_Gen5, GP_Gen8IM, GP_Gen8IH, BC_Gen4, BC_Gen5, BC_Gen8IM, BC_Gen8IH"
  }

  validation {
    condition = alltrue([
      for k, v in var.sqlmi_instances :
      (v.sku_name == "GP_Gen4" || v.sku_name == "BC_Gen4") ? contains([8, 16, 24], v.vcores) :
      contains([4, 6, 8, 10, 12, 16, 20, 24, 32, 40, 48, 56, 64, 80, 96, 128], v.vcores)
    ])
    error_message = "vCores must be 8, 16, or 24 for Gen4 SKUs, or 4-128 for Gen5/Gen8 SKUs"
  }

  validation {
    condition = alltrue([
      for k, v in var.sqlmi_instances :
      v.storage_size_in_gb >= 32 && v.storage_size_in_gb <= 16384 && v.storage_size_in_gb % 32 == 0
    ])
    error_message = "Storage size must be between 32 and 16384 GB and must be a multiple of 32"
  }

  validation {
    condition = alltrue([
      for k, v in var.sqlmi_instances :
      contains(["LicenseIncluded", "BasePrice"], v.license_type)
    ])
    error_message = "License type must be either 'LicenseIncluded' or 'BasePrice'"
  }

  validation {
    condition = alltrue([
      for k, v in var.sqlmi_instances :
      v.minimum_tls_version == null || contains(["1.0", "1.1", "1.2"], v.minimum_tls_version)
    ])
    error_message = "Minimum TLS version must be one of: 1.0, 1.1, 1.2"
  }

  validation {
    condition = alltrue([
      for k, v in var.sqlmi_instances :
      v.proxy_override == null || contains(["Default", "Proxy", "Redirect"], v.proxy_override)
    ])
    error_message = "Proxy override must be one of: Default, Proxy, Redirect"
  }

  validation {
    condition = alltrue([
      for k, v in var.sqlmi_instances :
      v.storage_account_type == null || contains(["GRS", "LRS", "ZRS"], v.storage_account_type)
    ])
    error_message = "Storage account type must be one of: GRS, LRS, ZRS"
  }
}