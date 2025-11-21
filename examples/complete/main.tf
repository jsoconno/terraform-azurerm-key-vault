# Complete example of the Azure Key Vault module usage
# This example demonstrates all module features including secrets, keys, and certificates

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

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Data sources for existing resources
data "azurerm_client_config" "current" {}

data "azuread_user" "admin_user" {
  user_principal_name = var.admin_user_principal_name
}

data "azuread_service_principal" "app_service_principal" {
  display_name = var.app_service_principal_name
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

  key_vault_name      = var.key_vault_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku_name            = var.key_vault_sku

  # Security configuration
  soft_delete_retention_days    = var.soft_delete_retention_days
  purge_protection_enabled      = var.purge_protection_enabled
  public_network_access_enabled = var.public_network_access_enabled

  # Network access control (always configured for security)
  network_acls = {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = var.allowed_ip_ranges
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

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

  # Secrets management
  secrets = var.create_sample_secrets ? {
    "database-connection-string" = {
      value        = "Server=myserver.database.windows.net;Database=mydb;User Id=myuser;Password=MySecurePassword123!;"
      content_type = "text/plain"
      tags = {
        Application = "WebApp"
        SecretType  = "ConnectionString"
        Environment = var.environment
      }
    }
    "storage-account-key" = {
      value        = "DefaultEndpointsProtocol=https;AccountName=mystorageaccount;AccountKey=ABC123...;EndpointSuffix=core.windows.net"
      content_type = "text/plain"
      tags = {
        Application = "WebApp"
        SecretType  = "StorageKey"
        Environment = var.environment
      }
    }
    "api-key" = {
      value           = "sk-1234567890abcdef1234567890abcdef"
      expiration_date = "2025-12-31T23:59:59Z"
      content_type    = "text/plain"
      tags = {
        Application = "WebApp"
        SecretType  = "APIKey"
        Environment = var.environment
      }
    }
  } : {}

  # Key management
  keys = var.create_sample_keys ? {
    "data-encryption-key" = {
      key_type = "RSA"
      key_size = 2048
      key_opts = ["decrypt", "encrypt", "sign", "verify", "wrapKey", "unwrapKey"]
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
      key_type = "RSA"
      key_size = 2048
      key_opts = ["sign", "verify"]
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

# Output the Key Vault information
output "key_vault_uri" {
  description = "The URI of the created Key Vault"
  value       = module.key_vault.key_vault_uri
}

output "key_vault_id" {
  description = "The ID of the created Key Vault"
  value       = module.key_vault.key_vault_id
}

output "secret_ids" {
  description = "The IDs of created secrets"
  value       = module.key_vault.secret_ids
}

output "key_ids" {
  description = "The IDs of created keys"
  value       = module.key_vault.key_ids
}

output "certificate_ids" {
  description = "The IDs of created certificates"
  value       = module.key_vault.certificate_ids
}