# Azure Key Vault Terraform Module
# This module creates an Azure Key Vault with RBAC authorization and manages secrets, keys, and certificates

# Current client configuration, used for the tenant ID
data "azurerm_client_config" "current" {}

# Key Vault Resource
resource "azurerm_key_vault" "main" {
  name                = var.key_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.sku_name

  # Enable RBAC authorization instead of access policies
  enable_rbac_authorization = true

  # Security settings
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = var.purge_protection_enabled

  # Network access settings
  public_network_access_enabled = var.public_network_access_enabled

  tags = var.tags

  # The firewall is always on because default_action must be "Deny"
  network_acls {
    bypass                     = var.network_acls.bypass
    default_action             = var.network_acls.default_action
    ip_rules                   = var.network_acls.ip_rules
    virtual_network_subnet_ids = var.network_acls.virtual_network_subnet_ids
  }
}

# Private endpoint so the vault is reachable over Private Link rather than the public internet
resource "azurerm_private_endpoint" "key_vault" {
  name                = "pe-${var.key_vault_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint.subnet_id

  tags = var.tags

  private_service_connection {
    name                           = "psc-${var.key_vault_name}"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = length(var.private_endpoint.private_dns_zone_ids) > 0 ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = var.private_endpoint.private_dns_zone_ids
    }
  }
}

# Send audit and resource logs to Log Analytics for security investigation
resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "diag-${var.key_vault_name}"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "audit"
  }

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

# RBAC Role Assignments
resource "azurerm_role_assignment" "key_vault_rbac" {
  for_each = var.rbac_assignments

  scope                = azurerm_key_vault.main.id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
  description          = each.value.description
}

# Key Vault Secrets
resource "azurerm_key_vault_secret" "secrets" {
  # Iterate over names because sensitive values cannot key for_each
  for_each = nonsensitive(toset(keys(var.secrets)))

  name         = each.key
  value        = var.secrets[each.key].value
  key_vault_id = azurerm_key_vault.main.id

  content_type    = var.secrets[each.key].content_type
  not_before_date = var.secrets[each.key].not_before_date
  expiration_date = var.secrets[each.key].expiration_date

  tags = merge(var.tags, var.secrets[each.key].tags)

  depends_on = [azurerm_role_assignment.key_vault_rbac]
}

# Key Vault Keys
resource "azurerm_key_vault_key" "keys" {
  for_each = var.keys

  name         = each.key
  key_vault_id = azurerm_key_vault.main.id
  key_type     = each.value.key_type
  key_size     = each.value.key_size
  key_opts     = each.value.key_opts

  not_before_date = each.value.not_before_date
  expiration_date = each.value.expiration_date

  tags = merge(var.tags, each.value.tags)

  # Rotation policy is required for every key (see var.keys validation)
  rotation_policy {
    expire_after         = each.value.rotation_policy.expire_after
    notify_before_expiry = each.value.rotation_policy.notify_before_expiry

    automatic {
      time_before_expiry = each.value.rotation_policy.automatic.time_before_expiry
    }
  }

  depends_on = [azurerm_role_assignment.key_vault_rbac]
}

# Key Vault Certificates
resource "azurerm_key_vault_certificate" "certificates" {
  # Iterate over names because sensitive values cannot key for_each
  for_each = nonsensitive(toset(keys(var.certificates)))

  name         = each.key
  key_vault_id = azurerm_key_vault.main.id

  tags = merge(var.tags, var.certificates[each.key].tags)

  dynamic "certificate_policy" {
    for_each = var.certificates[each.key].certificate_policy != null ? [var.certificates[each.key].certificate_policy] : []
    content {
      issuer_parameters {
        name = certificate_policy.value.issuer_parameters.name
      }

      key_properties {
        exportable = certificate_policy.value.key_properties.exportable
        key_size   = certificate_policy.value.key_properties.key_size
        key_type   = certificate_policy.value.key_properties.key_type
        reuse_key  = certificate_policy.value.key_properties.reuse_key
      }

      lifetime_action {
        action {
          action_type = certificate_policy.value.lifetime_action.action.action_type
        }

        trigger {
          days_before_expiry  = certificate_policy.value.lifetime_action.trigger.days_before_expiry
          lifetime_percentage = certificate_policy.value.lifetime_action.trigger.lifetime_percentage
        }
      }

      secret_properties {
        content_type = certificate_policy.value.secret_properties.content_type
      }

      x509_certificate_properties {
        key_usage          = certificate_policy.value.x509_certificate_properties.key_usage
        subject            = certificate_policy.value.x509_certificate_properties.subject
        validity_in_months = certificate_policy.value.x509_certificate_properties.validity_in_months

        dynamic "subject_alternative_names" {
          for_each = certificate_policy.value.x509_certificate_properties.subject_alternative_names != null ? [certificate_policy.value.x509_certificate_properties.subject_alternative_names] : []
          content {
            dns_names = subject_alternative_names.value.dns_names
            emails    = subject_alternative_names.value.emails
            upns      = subject_alternative_names.value.upns
          }
        }
      }
    }
  }

  # For importing existing certificates
  dynamic "certificate" {
    for_each = var.certificates[each.key].certificate_contents != null ? [1] : []
    content {
      contents = var.certificates[each.key].certificate_contents
      password = var.certificates[each.key].certificate_password
    }
  }

  depends_on = [azurerm_role_assignment.key_vault_rbac]
}
