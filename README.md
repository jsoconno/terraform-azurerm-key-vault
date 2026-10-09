# Azure Key Vault Terraform Module

This Terraform module creates an Azure Key Vault with RBAC authorization and manages secrets, keys, and certificates. It follows security best practices including soft delete, purge protection, and Role-Based Access Control (RBAC) instead of traditional access policies.

## Features

- **RBAC Authorization**: Uses Azure RBAC for access control instead of traditional access policies
- **Comprehensive Management**: Create and manage secrets, keys, and certificates
- **Security-First Approach**: Opinionated defaults that enforce security best practices
- **Mandatory Security Controls**: Purge protection always enabled, minimum 30-day soft delete retention
- **Network Security**: Private by default with configurable network access controls
- **Flexible Role Assignments**: Support for all Key Vault built-in roles
- **Key Rotation**: Support for automatic key rotation policies
- **Certificate Management**: Support for both self-signed and imported certificates
- **Compliance Ready**: Enforces minimum security standards for enterprise use

## Usage

### Basic Example

```hcl
module "key_vault" {
  source = "./azure-key-vault"

  key_vault_name      = "my-company-kv-prod"
  location            = "East US"
  resource_group_name = "my-resource-group"

  # Private Link access and audit logging (both required)
  private_endpoint = {
    subnet_id            = azurerm_subnet.private_endpoints.id
    private_dns_zone_ids = [azurerm_private_dns_zone.key_vault.id]
  }
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # RBAC role assignments
  rbac_assignments = {
    "admin-assignment" = {
      principal_id         = "12345678-1234-1234-1234-123456789012"
      role_definition_name = "Key Vault Administrator"
      description          = "Admin access for DevOps team"
    }
    "secrets-user-assignment" = {
      principal_id         = "87654321-4321-4321-4321-210987654321"
      role_definition_name = "Key Vault Secrets User"
      description          = "Read access for application service principal"
    }
  }

  tags = {
    Environment = "Production"
    Owner       = "DevOps Team"
  }
}
```

### Complete Example with Secrets, Keys, and Certificates

```hcl
module "key_vault" {
  source = "./azure-key-vault"

  key_vault_name      = "my-company-kv-prod"
  location            = "East US"
  resource_group_name = "my-resource-group"
  sku_name            = "premium"

  # Network security
  public_network_access_enabled = false
  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = ["203.0.113.0/24", "198.51.100.0/24"]
  }

  # Private Link access and audit logging (both required)
  private_endpoint = {
    subnet_id            = azurerm_subnet.private_endpoints.id
    private_dns_zone_ids = [azurerm_private_dns_zone.key_vault.id]
  }
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # RBAC assignments
  rbac_assignments = {
    "admin-assignment" = {
      principal_id         = "12345678-1234-1234-1234-123456789012"
      role_definition_name = "Key Vault Administrator"
      description          = "Full administrative access"
    }
    "secrets-officer-assignment" = {
      principal_id         = "11111111-2222-3333-4444-555555555555"
      role_definition_name = "Key Vault Secrets Officer"
      description          = "Secrets management for DevOps"
    }
    "app-secrets-user" = {
      principal_id         = "87654321-4321-4321-4321-210987654321"
      role_definition_name = "Key Vault Secrets User"
      description          = "Application read access"
    }
  }

  # Pass secret values in through sensitive variables and never hardcode them
  secrets = {
    "database-connection-string" = {
      value        = var.database_connection_string
      content_type = "text/plain"
      tags = {
        Application = "WebApp"
        SecretType  = "ConnectionString"
      }
    }
    "api-key" = {
      value           = var.api_key
      expiration_date = "2027-12-31T23:59:59Z"
      tags = {
        Application = "WebApp"
        SecretType  = "APIKey"
      }
    }
  }

  # Keys
  keys = {
    "encryption-key" = {
      key_type = "RSA"
      key_size = 2048
      key_opts = ["decrypt", "encrypt", "sign", "verify", "wrapKey", "unwrapKey"]
      # Every key needs an expiry and a rotation policy with expire_after of 12 months or less
      expiration_date = "2027-10-01T00:00:00Z"
      rotation_policy = {
        automatic = {
          time_before_expiry = "P30D"
        }
        expire_after         = "P90D"
        notify_before_expiry = "P15D"
      }
      tags = {
        Usage = "DataEncryption"
      }
    }
  }

  # Certificates
  certificates = {
    "web-app-cert" = {
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
            dns_names = ["webapp.example.com", "www.webapp.example.com"]
          }
        }
      }
      tags = {
        Usage = "WebApp"
      }
    }
  }

  tags = {
    Environment = "Production"
    Owner       = "DevOps Team"
    Project     = "WebApp"
  }
}
```

## Available RBAC Roles

The module supports the following built-in Azure Key Vault roles:

- `Key Vault Administrator` - Full access to all Key Vault operations
- `Key Vault Certificates Officer` - Manage certificates
- `Key Vault Crypto Officer` - Manage cryptographic keys
- `Key Vault Crypto Service Encryption User` - Use keys for service encryption
- `Key Vault Crypto User` - Use cryptographic keys
- `Key Vault Reader` - Read metadata of Key Vault resources
- `Key Vault Secrets Officer` - Manage secrets
- `Key Vault Secrets User` - Read secret contents

## Key Types and Options

### Supported Key Types
- `RSA` - RSA keys (software-backed)
- `RSA-HSM` - RSA keys (HSM-backed, requires Premium SKU)
- `EC` - Elliptic Curve keys (software-backed)
- `EC-HSM` - Elliptic Curve keys (HSM-backed, requires Premium SKU)

### Key Operations
Available key operations for the `key_opts` parameter:
- `decrypt` - Allow decryption operations
- `encrypt` - Allow encryption operations
- `sign` - Allow signing operations
- `verify` - Allow verification operations
- `wrapKey` - Allow key wrapping
- `unwrapKey` - Allow key unwrapping

## Network Access Control

Configure network access using the `network_acls` variable:

```hcl
network_acls = {
  bypass         = "AzureServices"  # or "None"
  default_action = "Deny"           # must be "Deny"; the firewall is always on
  ip_rules       = ["203.0.113.0/24"]
  virtual_network_subnet_ids = ["/subscriptions/.../subnets/subnet1"]
}
```

## Private Endpoint and Logging

Every deployment gets a private endpoint (`vault` sub-resource) in the subnet you pass as `private_endpoint.subnet_id`. Pass the ID of a `privatelink.vaultcore.azure.net` private DNS zone in `private_endpoint.private_dns_zone_ids` so the vault name resolves to the private IP.

A diagnostic setting sends the `audit` and `allLogs` category groups and `AllMetrics` to the Log Analytics workspace in `log_analytics_workspace_id`.

Terraform itself talks to the vault's data plane to create secrets, keys and certificates. With public network access disabled, run Terraform from a network that can reach the private endpoint, or allow the runner's IP through `network_acls.ip_rules`.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| azurerm | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| certificates | A map of certificates to create in the Key Vault. | `map(object)` | `{}` | no |
| key_vault_name | The name of the Key Vault. Must be globally unique. | `string` | n/a | yes |
| keys | A map of keys to create. Each key requires `expiration_date` and `rotation_policy` (`expire_after` <= 12 months). | `map(object)` | `{}` | no |
| location | The Azure region where the Key Vault will be created. | `string` | n/a | yes |
| log_analytics_workspace_id | Log Analytics workspace that receives audit and resource logs. | `string` | n/a | yes |
| network_acls | Firewall configuration. `default_action` must be `Deny`. | `object` | deny, bypass AzureServices | no |
| private_endpoint | `subnet_id` for the private endpoint and optional `private_dns_zone_ids`. | `object` | n/a | yes |
| public_network_access_enabled | Whether public network access is allowed for this Key Vault. | `bool` | `false` | no |
| purge_protection_enabled | Is Purge Protection enabled for this Key Vault? Must be true. | `bool` | `true` | no |
| rbac_assignments | A map of RBAC role assignments for the Key Vault. | `map(object)` | `{}` | no |
| resource_group_name | The name of the resource group in which to create the Key Vault. | `string` | n/a | yes |
| secrets | A map of secrets to create in the Key Vault. | `map(object)` | `{}` | no |
| sku_name | The Name of the SKU used for this Key Vault. Possible values are standard and premium. | `string` | `"standard"` | no |
| soft_delete_retention_days | The number of days that items should be retained for once soft-deleted. | `number` | `90` | no |
| tags | A map of tags to assign to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| key_vault_id | The ID of the Key Vault |
| key_vault_name | The name of the Key Vault |
| key_vault_uri | The URI of the Key Vault |
| key_vault_tenant_id | The tenant ID of the Key Vault |
| rbac_assignment_ids | A map of RBAC assignment IDs |
| secret_ids | A map of secret names to their IDs |
| key_ids | A map of key names to their IDs |
| certificate_ids | A map of certificate names to their IDs |
| private_endpoint_id | The ID of the Key Vault private endpoint |
| private_endpoint_ip_address | The private IP address of the private endpoint |
| diagnostic_setting_id | The ID of the Key Vault diagnostic setting |

## Security-First Design

This module is **security-opinionated** and enforces several security best practices that cannot be disabled:

### Mandatory Security Controls
- **Purge Protection**: Always enabled and cannot be disabled to prevent accidental permanent deletion
- **Soft Delete Retention**: Minimum 30 days (instead of Azure's 7-day minimum) for better recovery options
- **Network ACLs**: Firewall always on; `default_action` must be `Deny` (allow Azure services by default)
- **Public Access**: Disabled by default to promote private endpoint usage
- **Key Size Validation**: RSA keys must be at least 2048 bits for cryptographic security
- **Key Lifecycle**: Every key must have an expiration date and a rotation policy that expires versions within 12 months
- **Private Endpoint**: Always deployed so the vault is reachable over Private Link
- **Audit Logging**: Diagnostic settings always send audit logs to Log Analytics

### Opinionated Defaults
- `purge_protection_enabled = true` (cannot be changed)
- `public_network_access_enabled = false` (private by default)
- `soft_delete_retention_days = 90` (minimum 30 days enforced)
- `network_acls.default_action = "Deny"` (deny by default)
- `network_acls.bypass = "AzureServices"` (allow trusted Azure services)

### Why These Decisions?
1. **Compliance**: Meets most enterprise security and compliance requirements out of the box
2. **Defense in Depth**: Multiple layers of protection prevent accidental data loss or unauthorized access
3. **Best Practices**: Aligns with Microsoft's security recommendations and industry standards
4. **Audit Readiness**: Configuration choices that satisfy security audits and governance requirements

## Security Considerations

1. **RBAC vs Access Policies**: This module uses RBAC authorization which is the recommended approach for new Key Vault deployments.

2. **Purge Protection**: Always enabled and cannot be disabled to prevent accidental permanent deletion of the Key Vault.

3. **Soft Delete**: Enabled with a 90-day retention period by default, with a minimum of 30 days enforced.

4. **Network Access**: Private by default with network ACLs always configured for defense in depth.

5. **Principal IDs**: When assigning RBAC roles, use the Object ID of users, groups, or service principals, not their display names.

## Common Issues

### Authentication
Ensure you have the appropriate permissions in Azure Active Directory to create Key Vaults and assign RBAC roles. The executing user or service principal needs:
- Contributor role on the resource group
- User Access Administrator role for RBAC assignments

### Principal ID Format
Make sure to use the correct Object ID (UUID format) when specifying `principal_id` in RBAC assignments.

## Contributing

Please follow standard Terraform module conventions and ensure all examples in this README are tested and working.

## License

This module is provided under the MIT License. See LICENSE file for details.