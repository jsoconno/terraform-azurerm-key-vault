# Azure Key Vault Module Outputs

# Key Vault Information
output "key_vault_id" {
  description = "The ID of the Key Vault."
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "The name of the Key Vault."
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "The URI of the Key Vault, used for performing operations on keys and secrets."
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_tenant_id" {
  description = "The Azure Active Directory tenant ID that should be used for authenticating requests to the Key Vault."
  value       = azurerm_key_vault.main.tenant_id
}

output "key_vault_location" {
  description = "The location of the Key Vault."
  value       = azurerm_key_vault.main.location
}

output "key_vault_resource_group_name" {
  description = "The name of the resource group containing the Key Vault."
  value       = azurerm_key_vault.main.resource_group_name
}

# Security Configuration
output "soft_delete_retention_days" {
  description = "The number of days that items should be retained for once soft-deleted."
  value       = azurerm_key_vault.main.soft_delete_retention_days
}

output "purge_protection_enabled" {
  description = "Is Purge Protection enabled for this Key Vault."
  value       = azurerm_key_vault.main.purge_protection_enabled
}

output "rbac_authorization_enabled" {
  description = "Is Role Based Access Control (RBAC) for authorization of data actions enabled on this Key Vault."
  value       = azurerm_key_vault.main.enable_rbac_authorization
}

# RBAC Assignments
output "rbac_assignment_ids" {
  description = "A map of RBAC assignment IDs."
  value       = { for k, v in azurerm_role_assignment.key_vault_rbac : k => v.id }
}

# Secrets Information
output "secret_ids" {
  description = "A map of secret names to their Key Vault secret IDs."
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.id }
}

output "secret_versions" {
  description = "A map of secret names to their current versions."
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.version }
}

output "secret_version_ids" {
  description = "A map of secret names to their current version IDs."
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.versionless_id }
}

# Keys Information
output "key_ids" {
  description = "A map of key names to their Key Vault key IDs."
  value       = { for k, v in azurerm_key_vault_key.keys : k => v.id }
}

output "key_versions" {
  description = "A map of key names to their current versions."
  value       = { for k, v in azurerm_key_vault_key.keys : k => v.version }
}

output "key_version_ids" {
  description = "A map of key names to their current version IDs."
  value       = { for k, v in azurerm_key_vault_key.keys : k => v.versionless_id }
}

# Certificates Information
output "certificate_ids" {
  description = "A map of certificate names to their Key Vault certificate IDs."
  value       = { for k, v in azurerm_key_vault_certificate.certificates : k => v.id }
}

output "certificate_versions" {
  description = "A map of certificate names to their current versions."
  value       = { for k, v in azurerm_key_vault_certificate.certificates : k => v.version }
}

output "certificate_version_ids" {
  description = "A map of certificate names to their current version IDs."
  value       = { for k, v in azurerm_key_vault_certificate.certificates : k => v.versionless_id }
}

output "certificate_thumbprints" {
  description = "A map of certificate names to their thumbprints."
  value       = { for k, v in azurerm_key_vault_certificate.certificates : k => v.thumbprint }
}

output "certificate_secret_ids" {
  description = "A map of certificate names to the secret IDs of their associated private keys."
  value       = { for k, v in azurerm_key_vault_certificate.certificates : k => v.secret_id }
}