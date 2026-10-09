# Azure Key Vault Module Variables
# Variables are listed in alphabetical order

variable "certificates" {
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
  description = "A map of certificates to create in the Key Vault."
  default     = {}
  sensitive   = true
}

variable "key_vault_name" {
  type        = string
  description = "The name of the Key Vault. Must be globally unique."

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.key_vault_name))
    error_message = "Key Vault name must be between 3 and 24 characters long and contain only letters, numbers, and hyphens."
  }
}

variable "keys" {
  type = map(object({
    key_type        = string
    key_size        = optional(number)
    key_opts        = set(string)
    not_before_date = optional(string)
    expiration_date = string
    rotation_policy = object({
      automatic = object({
        time_before_expiry = string
      })
      expire_after         = string
      notify_before_expiry = string
    })
    tags = optional(map(string), {})
  }))
  description = "A map of keys to create in the Key Vault. Every key must set an expiration_date and a rotation_policy whose expire_after is no longer than 12 months."
  default     = {}

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

  validation {
    condition = alltrue([
      for key in var.keys : can(formatdate("YYYY", key.expiration_date))
    ])
    error_message = "Every key must set expiration_date as an RFC 3339 timestamp, e.g. 2027-01-01T00:00:00Z."
  }

  # Accepts ISO 8601 durations of the form PnD, PnM or PnY, capped at 12 months
  validation {
    condition = alltrue([
      for key in var.keys : (
        try(tonumber(regex("^P([0-9]+)D$", key.rotation_policy.expire_after)[0]) <= 365, false) ||
        try(tonumber(regex("^P([0-9]+)M$", key.rotation_policy.expire_after)[0]) <= 12, false) ||
        try(tonumber(regex("^P([0-9]+)Y$", key.rotation_policy.expire_after)[0]) <= 1, false)
      )
    ])
    error_message = "rotation_policy.expire_after must be an ISO 8601 duration (PnD, PnM or PnY) of no more than 12 months."
  }
}

variable "location" {
  type        = string
  description = "The Azure region where the Key Vault will be created."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "The ID of the Log Analytics workspace that receives the Key Vault's audit and resource logs."
}

variable "network_acls" {
  type = object({
    bypass                     = optional(string, "AzureServices")
    default_action             = optional(string, "Deny")
    ip_rules                   = optional(set(string))
    virtual_network_subnet_ids = set(string)
  })
  description = "Network ACL (firewall) configuration for the Key Vault. virtual_network_subnet_ids must list at least one subnet with the Microsoft.KeyVault service endpoint. default_action must be 'Deny'."

  validation {
    condition     = length(var.network_acls.virtual_network_subnet_ids) > 0
    error_message = "network_acls.virtual_network_subnet_ids must contain at least one subnet so access is restricted to your virtual networks."
  }

  validation {
    condition     = contains(["AzureServices", "None"], var.network_acls.bypass)
    error_message = "network_acls.bypass must be 'AzureServices' or 'None'."
  }

  validation {
    condition     = var.network_acls.default_action == "Deny"
    error_message = "network_acls.default_action must be 'Deny' so the Key Vault firewall blocks unlisted networks."
  }
}

variable "private_endpoint" {
  type = object({
    subnet_id            = string
    private_dns_zone_ids = optional(list(string), [])
  })
  description = "Private endpoint configuration. subnet_id is the subnet the endpoint is placed in; private_dns_zone_ids should contain the privatelink.vaultcore.azure.net zone ID."
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Whether public network access is allowed for this Key Vault. Defaults to false; access is expected over the private endpoint."
  default     = false
}

variable "purge_protection_enabled" {
  type        = bool
  description = "Is Purge Protection enabled for this Key Vault? Always enabled for security - cannot be disabled."
  default     = true

  validation {
    condition     = var.purge_protection_enabled == true
    error_message = "Purge protection must be enabled for security compliance and cannot be disabled."
  }
}

variable "rbac_assignments" {
  type = map(object({
    principal_id         = string
    role_definition_name = string
    description          = optional(string)
  }))
  description = "A map of RBAC role assignments for the Key Vault."
  default     = {}

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

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the Key Vault."
}

variable "secrets" {
  type = map(object({
    value           = string
    content_type    = optional(string)
    not_before_date = optional(string)
    expiration_date = optional(string)
    tags            = optional(map(string), {})
  }))
  description = "A map of secrets to create in the Key Vault."
  default     = {}
  sensitive   = true
}

variable "sku_name" {
  type        = string
  description = "The Name of the SKU used for this Key Vault. Possible values are standard and premium."
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU name must be either 'standard' or 'premium'."
  }
}

variable "soft_delete_retention_days" {
  type        = number
  description = "The number of days that items should be retained for once soft-deleted. Minimum 30 days for security compliance."
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 30 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention days must be between 30 and 90 days for security compliance."
  }
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to all resources."
  default     = {}
}
