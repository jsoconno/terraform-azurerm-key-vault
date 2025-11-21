# Variables for the complete Azure Key Vault example

# Required Variables
variable "key_vault_name" {
  description = "The name of the Key Vault. Must be globally unique."
  type        = string
  default     = "example-kv-${random_string.suffix.result}"
}

variable "resource_group_name" {
  description = "The name of the resource group to create."
  type        = string
  default     = "rg-keyvault-example"
}

variable "location" {
  description = "The Azure region where resources will be created."
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "The environment name (dev, staging, prod)."
  type        = string
  default     = "dev"
}

# Key Vault Configuration
variable "key_vault_sku" {
  description = "The SKU of the Key Vault (standard or premium)."
  type        = string
  default     = "standard"
}

variable "soft_delete_retention_days" {
  description = "Number of days to retain deleted items."
  type        = number
  default     = 90
}

variable "purge_protection_enabled" {
  description = "Enable purge protection for the Key Vault."
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Allow public network access to the Key Vault."
  type        = bool
  default     = true
}

# Network Security
variable "allowed_ip_ranges" {
  description = "List of IP ranges allowed to access the Key Vault. Network ACLs are always configured for security."
  type        = set(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "List of virtual network subnet IDs allowed to access the Key Vault."
  type        = set(string)
  default     = []
}

# RBAC Configuration
variable "admin_user_principal_name" {
  description = "The User Principal Name (UPN) of the admin user for RBAC assignment."
  type        = string
  default     = "admin@yourdomain.com"
}

variable "app_service_principal_name" {
  description = "The display name of the application service principal for RBAC assignment."
  type        = string
  default     = "MyApp"
}

# Resource Creation Flags
variable "create_sample_secrets" {
  description = "Whether to create sample secrets in the Key Vault."
  type        = bool
  default     = true
}

variable "create_sample_keys" {
  description = "Whether to create sample keys in the Key Vault."
  type        = bool
  default     = true
}

variable "create_sample_certificates" {
  description = "Whether to create sample certificates in the Key Vault."
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "A map of tags to assign to all resources."
  type        = map(string)
  default = {
    Environment = "Development"
    Project     = "KeyVault-Example"
    Owner       = "DevOps Team"
    CreatedBy   = "Terraform"
  }
}

# Random string for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}