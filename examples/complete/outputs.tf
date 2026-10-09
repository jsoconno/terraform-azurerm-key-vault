# Outputs are listed in alphabetical order

output "certificate_ids" {
  description = "The IDs of created certificates"
  value       = module.key_vault.certificate_ids
}

output "key_ids" {
  description = "The IDs of created keys"
  value       = module.key_vault.key_ids
}

output "key_vault_id" {
  description = "The ID of the created Key Vault"
  value       = module.key_vault.key_vault_id
}

output "key_vault_uri" {
  description = "The URI of the created Key Vault"
  value       = module.key_vault.key_vault_uri
}

output "private_endpoint_ip_address" {
  description = "The private IP address of the Key Vault private endpoint"
  value       = module.key_vault.private_endpoint_ip_address
}

output "secret_ids" {
  description = "The IDs of created secrets"
  value       = module.key_vault.secret_ids
}
