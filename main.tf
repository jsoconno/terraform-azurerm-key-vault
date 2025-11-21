# Azure Key Vault Terraform Module
# This module creates an Azure Key Vault with RBAC authorization and manages secrets, keys, and certificates

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

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

  # Always enforce network ACLs for security
  network_acls {
    bypass                     = var.network_acls.bypass
    default_action             = var.network_acls.default_action
    ip_rules                   = var.network_acls.ip_rules
    virtual_network_subnet_ids = var.network_acls.virtual_network_subnet_ids
  }

  tags = var.tags
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
  for_each = var.secrets

  name         = each.key
  value        = each.value.value
  key_vault_id = azurerm_key_vault.main.id

  content_type    = each.value.content_type
  not_before_date = each.value.not_before_date
  expiration_date = each.value.expiration_date

  tags = merge(var.tags, each.value.tags)

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

  dynamic "rotation_policy" {
    for_each = each.value.rotation_policy != null ? [each.value.rotation_policy] : []
    content {
      automatic {
        time_before_expiry = rotation_policy.value.automatic.time_before_expiry
      }
      expire_after         = rotation_policy.value.expire_after
      notify_before_expiry = rotation_policy.value.notify_before_expiry
    }
  }

  tags = merge(var.tags, each.value.tags)

  depends_on = [azurerm_role_assignment.key_vault_rbac]
}

# Key Vault Certificates
resource "azurerm_key_vault_certificate" "certificates" {
  for_each = var.certificates

  name         = each.key
  key_vault_id = azurerm_key_vault.main.id

  dynamic "certificate_policy" {
    for_each = each.value.certificate_policy != null ? [each.value.certificate_policy] : []
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
        key_usage = certificate_policy.value.x509_certificate_properties.key_usage

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
  certificate {
    contents = each.value.certificate_contents
    password = each.value.certificate_password
  }

  tags = merge(var.tags, each.value.tags)

  depends_on = [azurerm_role_assignment.key_vault_rbac]
}