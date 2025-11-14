# ============================================================================
# PRODUCTION ENVIRONMENT - SQL MANAGED INSTANCE CONFIGURATION
# ============================================================================

environment     = "production"
subscription_id = "00000000-0000-0000-0000-000000000000" # UPDATE WITH YOUR SUBSCRIPTION ID

# Key Vault for storing passwords and CMK keys
key_vault_name                = "kv-sqlmi-prod-001"    # UPDATE
key_vault_resource_group_name = "rg-security-prod"     # UPDATE

# Enable network validation checks
validate_network_requirements = true

# Enable module telemetry
enable_telemetry = true

# ============================================================================
# SQL MANAGED INSTANCES CONFIGURATION
# ============================================================================

sqlmi_instances = {

  # -------------------------------------------------------------------------
  # SQL MI for ERP Application - Business Critical with TDE CMK
  # -------------------------------------------------------------------------
  sqlmi_erp_prod = {
    name                = "sqlmi-erp-prod-001"
    resource_group_name = "rg-database-prod"
    location            = "eastus"
    subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-prod/subnets/snet-sqlmi" # UPDATE

    # Authentication (Password auto-generated and stored in Key Vault)
    administrator_login = "sqladmin"

    # SKU - Business Critical with zone redundancy
    sku_name           = "BC_Gen5"
    vcores             = 16
    storage_size_in_gb = 1024
    license_type       = "BasePrice" # Azure Hybrid Benefit

    # High Availability
    zone_redundant_enabled = true
    storage_account_type   = "GeoZone" # Geo-zone redundant backups

    # Network Configuration
    public_data_endpoint_enabled = false
    proxy_override               = "Default"
    minimum_tls_version          = "1.2"

    # Database Settings
    collation   = "SQL_Latin1_General_CP1_CI_AS"
    timezone_id = "Eastern Standard Time"

    # Maintenance Window
    maintenance_configuration_name = "SQL_EastUS_MI_1"

    # Advanced Threat Protection
    advanced_threat_protection_enabled = true

    # Security Alert Policy
    security_alert_policy = {
      enabled                      = true
      email_account_admins_enabled = true
      email_addresses              = ["dba-team@company.com", "security@company.com"]
      retention_days               = 90
      disabled_alerts              = []
    }

    # Transparent Data Encryption with Customer Managed Key
    tde_cmk_key_name = "key-sqlmi-tde-prod" # Key name in Key Vault
    transparent_data_encryption = {
      auto_rotation_enabled = true
      # key_vault_key_id will be constructed from data source
    }

    # Vulnerability Assessment
    storage_account_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-security-prod/providers/Microsoft.Storage/storageAccounts/stsqlmivaprod001" # UPDATE
    vulnerability_assessment = {
      storage_container_path = "https://stsqlmivaprod001.blob.core.windows.net/vulnerability-assessment"
      recurring_scans = {
        enabled                   = true
        email_subscription_admins = true
        emails                    = ["dba-team@company.com"]
      }
    }

    # Azure AD Administrator
    active_directory_administrator = {
      azuread_authentication_only = false
      login_username              = "DBA-Team-AAD"
      object_id                   = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" # UPDATE with AAD Group Object ID
      tenant_id                   = "tttttttt-tttt-tttt-tttt-tttttttttttt" # UPDATE with Tenant ID
    }

    # Managed Identity (System Assigned for Key Vault access)
    managed_identities = {
      system_assigned = true
    }

    # Private Endpoints
    private_endpoints = {
      primary = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-prod/subnets/snet-privateendpoints" # UPDATE
        private_dns_zone_resource_ids = [
          "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns-prod/providers/Microsoft.Network/privateDnsZones/privatelink.database.windows.net" # UPDATE
        ]
        private_dns_zone_group_name = "default"
      }
    }

    # Diagnostic Settings - Send to Log Analytics
    diagnostic_settings = {
      default = {
        name                       = "diag-sqlmi-erp"
        workspace_resource_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring-prod/providers/Microsoft.OperationalInsights/workspaces/law-prod" # UPDATE
        log_analytics_destination_type = "Dedicated"
        log_categories = [
          "SQLSecurityAuditEvents",
          "DevOpsOperationsAudit",
          "ResourceUsageStats",
          "SQLInsights",
          "Errors",
          "DatabaseWaitStatistics",
          "Timeouts",
          "Blocks",
          "Deadlocks"
        ]
        metric_categories = ["AllMetrics"]
        log_groups        = ["allLogs"]
      }
    }

    # Databases to create
    databases = {
      erp_prod = {
        name                      = "ERP_Production"
        short_term_retention_days = 35
        long_term_retention_policy = {
          weekly_retention  = "P12W"
          monthly_retention = "P12M"
          yearly_retention  = "P7Y"
          week_of_year      = 1
        }
        tags = {
          Application = "ERP"
          DataClass   = "Critical"
        }
      }
    }

    # Resource Lock
    lock = {
      kind = "CanNotDelete"
      name = "do-not-delete-erp-sqlmi"
    }

    # Role Assignments - Grant backup operator access
    role_assignments = {
      backup_operator = {
        role_definition_id_or_name = "SQL Managed Instance Contributor"
        principal_id               = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb" # UPDATE with Service Principal ID
        description                = "Backup automation service principal"
      }
    }

    # Timeouts for long-running operations
    timeouts = {
      create = "24h"
      update = "24h"
      delete = "24h"
      read   = "5m"
    }

    # Tags
    tags = {
      Application     = "ERP"
      Tier            = "BusinessCritical"
      DataClass       = "Confidential"
      BackupRequired  = "Yes"
      DRRequired      = "Yes"
      Compliance      = "SOX"
      CostCenter      = "IT-Database"
      Owner           = "dba-team@company.com"
    }
  }

  # -------------------------------------------------------------------------
  # SQL MI for CRM Application - General Purpose
  # -------------------------------------------------------------------------
  sqlmi_crm_prod = {
    name                = "sqlmi-crm-prod-001"
    resource_group_name = "rg-database-prod"
    location            = "eastus"
    subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-prod/subnets/snet-sqlmi" # UPDATE

    administrator_login = "sqladmin"

    # General Purpose SKU
    sku_name           = "GP_Gen5"
    vcores             = 8
    storage_size_in_gb = 512
    license_type       = "BasePrice"

    zone_redundant_enabled = false
    storage_account_type   = "GRS" # Geo-redundant backups

    public_data_endpoint_enabled = false
    minimum_tls_version          = "1.2"

    advanced_threat_protection_enabled = true

    security_alert_policy = {
      enabled                      = true
      email_account_admins_enabled = true
      email_addresses              = ["dba-team@company.com"]
      retention_days               = 30
    }

    # TDE with Service Managed Key (no CMK)
    transparent_data_encryption = {}

    # Vulnerability Assessment
    storage_account_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-security-prod/providers/Microsoft.Storage/storageAccounts/stsqlmivaprod001" # UPDATE
    vulnerability_assessment = {
      storage_container_path = "https://stsqlmivaprod001.blob.core.windows.net/vulnerability-assessment"
      recurring_scans = {
        enabled = true
        emails  = ["dba-team@company.com"]
      }
    }

    managed_identities = {
      system_assigned = true
    }

    private_endpoints = {
      primary = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-prod/subnets/snet-privateendpoints" # UPDATE
        private_dns_zone_resource_ids = [
          "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns-prod/providers/Microsoft.Network/privateDnsZones/privatelink.database.windows.net" # UPDATE
        ]
      }
    }

    diagnostic_settings = {
      default = {
        name                  = "diag-sqlmi-crm"
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring-prod/providers/Microsoft.OperationalInsights/workspaces/law-prod" # UPDATE
        log_categories        = ["SQLSecurityAuditEvents", "ResourceUsageStats"]
        metric_categories     = ["AllMetrics"]
      }
    }

    databases = {
      crm_prod = {
        name                      = "CRM_Production"
        short_term_retention_days = 14
        long_term_retention_policy = {
          weekly_retention  = "P4W"
          monthly_retention = "P12M"
        }
      }
    }

    timeouts = {
      create = "24h"
      update = "24h"
      delete = "24h"
    }

    tags = {
      Application    = "CRM"
      Tier           = "GeneralPurpose"
      DataClass      = "Internal"
      BackupRequired = "Yes"
      CostCenter     = "Sales"
    }
  }

  # -------------------------------------------------------------------------
  # SQL MI for Analytics - General Purpose with Larger Storage
  # -------------------------------------------------------------------------
  sqlmi_analytics_prod = {
    name                = "sqlmi-analytics-prod-001"
    resource_group_name = "rg-database-prod"
    location            = "eastus"
    subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-prod/subnets/snet-sqlmi" # UPDATE

    administrator_login = "sqladmin"

    # Larger storage for analytics
    sku_name           = "GP_Gen5"
    vcores             = 16
    storage_size_in_gb = 2048
    license_type       = "BasePrice"

    storage_account_type   = "LRS" # Local redundant for analytics (cost savings)
    zone_redundant_enabled = false

    public_data_endpoint_enabled = false
    minimum_tls_version          = "1.2"

    advanced_threat_protection_enabled = true

    managed_identities = {
      system_assigned = true
    }

    private_endpoints = {
      primary = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-prod/subnets/snet-privateendpoints" # UPDATE
        private_dns_zone_resource_ids = [
          "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns-prod/providers/Microsoft.Network/privateDnsZones/privatelink.database.windows.net" # UPDATE
        ]
      }
    }

    diagnostic_settings = {
      default = {
        name                  = "diag-sqlmi-analytics"
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring-prod/providers/Microsoft.OperationalInsights/workspaces/law-prod" # UPDATE
        log_categories        = ["ResourceUsageStats", "SQLInsights"]
        metric_categories     = ["AllMetrics"]
      }
    }

    databases = {
      analytics_dw = {
        name                      = "Analytics_DataWarehouse"
        short_term_retention_days = 7
      }
    }

    tags = {
      Application = "Analytics"
      Tier        = "GeneralPurpose"
      Workload    = "DataWarehouse"
      CostCenter  = "IT-DataPlatform"
    }
  }

}