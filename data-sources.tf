# Data sources for Azure Key Vault Module

# Current client configuration
data "azurerm_client_config" "current" {
  # This data source provides information about the current Azure client configuration
  # including tenant_id, subscription_id, and client_id
}