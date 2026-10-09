# Variables for the complete Azure Key Vault example
# Variables are listed in alphabetical order

variable "admin_user_principal_name" {
  type        = string
  description = "The User Principal Name (UPN) of the admin user for RBAC assignment."
  default     = "admin@yourdomain.com"
}

variable "allowed_ip_ranges" {
  type        = set(string)
  description = "List of IP ranges allowed through the Key Vault firewall."
  default     = []
}

variable "allowed_subnet_ids" {
  type        = set(string)
  description = "Subnet IDs allowed through the Key Vault firewall. Each subnet needs the Microsoft.KeyVault service endpoint. At least one is required."
}

variable "app_service_principal_name" {
  type        = string
  description = "The display name of the application service principal for RBAC assignment."
  default     = "MyApp"
}

variable "create_sample_certificates" {
  type        = bool
  description = "Whether to create sample certificates in the Key Vault."
  default     = true
}

variable "create_sample_keys" {
  type        = bool
  description = "Whether to create sample keys in the Key Vault."
  default     = true
}

variable "environment" {
  type        = string
  description = "The environment name (dev, staging, prod)."
  default     = "dev"
}

variable "key_expiration_date" {
  type        = string
  description = "Expiration date (RFC 3339) applied to the sample keys."
  default     = "2027-10-01T00:00:00Z"
}

variable "key_vault_name_prefix" {
  type        = string
  description = "Prefix for the Key Vault name. A random suffix is appended to make it globally unique."
  default     = "example-kv"
}

variable "key_vault_sku" {
  type        = string
  description = "The SKU of the Key Vault (standard or premium)."
  default     = "standard"
}

variable "location" {
  type        = string
  description = "The Azure region where resources will be created."
  default     = "East US"
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "The ID of an existing Log Analytics workspace that receives Key Vault audit logs."
}

variable "private_dns_zone_ids" {
  type        = list(string)
  description = "IDs of existing privatelink.vaultcore.azure.net private DNS zones to register the private endpoint in."
  default     = []
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "The ID of an existing subnet to place the Key Vault private endpoint in."
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Allow public network access to the Key Vault. Access is expected over the private endpoint."
  default     = false
}

variable "purge_protection_enabled" {
  type        = bool
  description = "Enable purge protection for the Key Vault."
  default     = true
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group to create."
  default     = "rg-keyvault-example"
}

variable "secrets" {
  type = map(object({
    value           = string
    content_type    = optional(string)
    not_before_date = optional(string)
    expiration_date = optional(string)
    tags            = optional(map(string), {})
  }))
  description = "Secrets to store in the Key Vault. Supply values at runtime (TF_VAR_secrets or an untracked tfvars file), never in code."
  default     = {}
  sensitive   = true
}

variable "soft_delete_retention_days" {
  type        = number
  description = "Number of days to retain deleted items."
  default     = 90
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to all resources."
  default = {
    Environment = "Development"
    Project     = "KeyVault-Example"
    Owner       = "DevOps Team"
    CreatedBy   = "Terraform"
  }
}
