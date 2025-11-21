# Azure Key Vault Module Variables

# Required Variables
variable "key_vault_name" {
  description = "The name of the Key Vault. Must be globally unique."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.key_vault_name))
    error_message = "Key Vault name must be between 3 and 24 characters long and contain only letters, numbers, and hyphens."
  }
}

variable "location" {
  description = "The Azure region where the Key Vault will be created."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Key Vault."
  type        = string
}

# Key Vault Configuration
variable "sku_name" {
  description = "The Name of the SKU used for this Key Vault. Possible values are standard and premium."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU name must be either 'standard' or 'premium'."
  }
}

variable "soft_delete_retention_days" {
  description = "The number of days that items should be retained for once soft-deleted. Minimum 30 days for security compliance."
  type        = number
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 30 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention days must be between 30 and 90 days for security compliance."
  }
}

variable "purge_protection_enabled" {
  description = "Is Purge Protection enabled for this Key Vault? Always enabled for security - cannot be disabled."
  type        = bool
  default     = true

  validation {
    condition     = var.purge_protection_enabled == true
    error_message = "Purge protection must be enabled for security compliance and cannot be disabled."
  }
}

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed for this Key Vault. Defaults to false for security. If enabled, network ACLs should be configured."
  type        = bool
  default     = false
}

# Network Access Control
variable "network_acls" {
  description = "Network ACL configuration for the Key Vault. Recommended to use 'Deny' as default_action for security."
  type = object({
    bypass                     = string
    default_action             = string
    ip_rules                   = optional(set(string))
    virtual_network_subnet_ids = optional(set(string))
  })
  default = {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = null
    virtual_network_subnet_ids = null
  }

  validation {
    condition = var.network_acls == null || (
      contains(["AzureServices", "None"], var.network_acls.bypass) &&
      contains(["Allow", "Deny"], var.network_acls.default_action)
    )
    error_message = "If network_acls is specified, bypass must be 'AzureServices' or 'None', and default_action must be 'Allow' or 'Deny'."
  }
}

# RBAC Role Assignments
variable "rbac_assignments" {
  description = "A map of RBAC role assignments for the Key Vault."
  type = map(object({
    principal_id         = string
    role_definition_name = string
    description          = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for assignment in var.rbac_assignments : contains([
        "Key Vault Administrator",
        "Key Vault Certificates Officer",
        "Key Vault Crypto Officer",
        "Key Vault Crypto Service Encryption User",
        "Key Vault Crypto User",
        "Key Vault Reader",
        "Key Vault Secrets Officer",
        "Key Vault Secrets User"
      ], assignment.role_definition_name)
    ])
    error_message = "Invalid role definition name. Must be one of the Key Vault built-in roles."
  }
}

# Secrets Configuration
variable "secrets" {
  description = "A map of secrets to create in the Key Vault."
  type = map(object({
    value           = string
    content_type    = optional(string)
    not_before_date = optional(string)
    expiration_date = optional(string)
    tags            = optional(map(string), {})
  }))
  default     = {}
  sensitive   = true
}

# Keys Configuration
variable "keys" {
  description = "A map of keys to create in the Key Vault."
  type = map(object({
    key_type        = string
    key_size        = optional(number)
    key_opts        = set(string)
    not_before_date = optional(string)
    expiration_date = optional(string)
    rotation_policy = optional(object({
      automatic = object({
        time_before_expiry = string
      })
      expire_after         = string
      notify_before_expiry = string
    }))
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for key in var.keys : contains(["EC", "EC-HSM", "RSA", "RSA-HSM"], key.key_type)
    ])
    error_message = "Key type must be one of: EC, EC-HSM, RSA, RSA-HSM."
  }

  validation {
    condition = alltrue([
      for key in var.keys : (
        key.key_size == null ||
        (key.key_type == "RSA" || key.key_type == "RSA-HSM") && key.key_size >= 2048 ||
        (key.key_type == "EC" || key.key_type == "EC-HSM")
      )
    ])
    error_message = "RSA keys must have a minimum size of 2048 bits for security compliance."
  }
}

# Certificates Configuration
variable "certificates" {
  description = "A map of certificates to create in the Key Vault."
  type = map(object({
    certificate_policy = optional(object({
      issuer_parameters = object({
        name = string
      })
      key_properties = object({
        exportable = bool
        key_size   = number
        key_type   = string
        reuse_key  = bool
      })
      lifetime_action = object({
        action = object({
          action_type = string
        })
        trigger = object({
          days_before_expiry  = optional(number)
          lifetime_percentage = optional(number)
        })
      })
      secret_properties = object({
        content_type = string
      })
      x509_certificate_properties = object({
        key_usage          = set(string)
        subject            = string
        validity_in_months = number
        subject_alternative_names = optional(object({
          dns_names = optional(set(string))
          emails    = optional(set(string))
          upns      = optional(set(string))
        }))
      })
    }))
    certificate_contents = optional(string)
    certificate_password = optional(string)
    tags                 = optional(map(string), {})
  }))
  default   = {}
  sensitive = true
}

# Common Tags
variable "tags" {
  description = "A map of tags to assign to all resources."
  type        = map(string)
  default     = {}
}