# Complete example of the Azure Key Vault module usage
# This example demonstrates all module features including secrets, keys, and certificates.
# Secret values never live in code. Pass them through the sensitive `secrets` variable
# (for example with TF_VAR_secrets or an untracked *.tfvars file).

locals {
  key_vault_name = "${var.key_vault_name_prefix}-${random_string.suffix.result}"
}

# Data sources for existing resources
data "azurerm_client_config" "current" {}

data "azuread_user" "admin_user" {
  user_principal_name = var.admin_user_principal_name
}

data "azuread_service_principal" "app_service_principal" {
  display_name = var.app_service_principal_name
}

# Random suffix for a globally unique Key Vault name
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Resource group for the example
resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

# Key Vault module usage
module "key_vault" {
  source = "../../"

  key_vault_name      = local.key_vault_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku_name            = var.key_vault_sku

  # Security configuration
  soft_delete_retention_days    = var.soft_delete_retention_days
  purge_protection_enabled      = var.purge_protection_enabled
  public_network_access_enabled = var.public_network_access_enabled

  # The firewall denies everything not listed here
  network_acls = {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = var.allowed_ip_ranges
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  # Private Link access
  private_endpoint = {
    subnet_id            = var.private_endpoint_subnet_id
    private_dns_zone_ids = var.private_dns_zone_ids
  }

  # Audit and resource logging
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # RBAC role assignments
  rbac_assignments = {
    "admin-assignment" = {
      principal_id         = data.azuread_user.admin_user.object_id
      role_definition_name = "Key Vault Administrator"
      description          = "Administrative access for Key Vault admin user"
    }
    "secrets-officer-assignment" = {
      principal_id         = data.azurerm_client_config.current.object_id
      role_definition_name = "Key Vault Secrets Officer"
      description          = "Secrets management for Terraform service principal"
    }
    "app-secrets-user" = {
      principal_id         = data.azuread_service_principal.app_service_principal.object_id
      role_definition_name = "Key Vault Secrets User"
      description          = "Read-only access for application service principal"
    }
  }

  # Secret values come in at runtime and never live in code
  secrets = var.secrets

  # Every key has an expiration date and a rotation policy
  keys = var.create_sample_keys ? {
    "data-encryption-key" = {
      key_type        = "RSA"
      key_size        = 2048
      key_opts        = ["decrypt", "encrypt", "wrapKey", "unwrapKey"]
      expiration_date = var.key_expiration_date
      rotation_policy = {
        automatic = {
          time_before_expiry = "P30D"
        }
        expire_after         = "P90D"
        notify_before_expiry = "P15D"
      }
      tags = {
        Usage       = "DataEncryption"
        Application = "WebApp"
        Environment = var.environment
      }
    }
    "signing-key" = {
      key_type        = "RSA"
      key_size        = 2048
      key_opts        = ["sign", "verify"]
      expiration_date = var.key_expiration_date
      rotation_policy = {
        automatic = {
          time_before_expiry = "P30D"
        }
        expire_after         = "P12M"
        notify_before_expiry = "P30D"
      }
      tags = {
        Usage       = "DocumentSigning"
        Application = "WebApp"
        Environment = var.environment
      }
    }
  } : {}

  # Certificate management
  certificates = var.create_sample_certificates ? {
    "web-app-ssl-cert" = {
      certificate_policy = {
        issuer_parameters = {
          name = "Self"
        }
        key_properties = {
          exportable = true
          key_size   = 2048
          key_type   = "RSA"
          reuse_key  = true
        }
        lifetime_action = {
          action = {
            action_type = "AutoRenew"
          }
          trigger = {
            days_before_expiry = 30
          }
        }
        secret_properties = {
          content_type = "application/x-pkcs12"
        }
        x509_certificate_properties = {
          key_usage = [
            "cRLSign",
            "dataEncipherment",
            "digitalSignature",
            "keyAgreement",
            "keyCertSign",
            "keyEncipherment"
          ]
          subject            = "CN=webapp.example.com"
          validity_in_months = 12
          subject_alternative_names = {
            dns_names = ["webapp.example.com", "www.webapp.example.com", "api.webapp.example.com"]
          }
        }
      }
      tags = {
        Usage       = "WebAppSSL"
        Application = "WebApp"
        Environment = var.environment
      }
    }
  } : {}

  tags = var.tags
}
