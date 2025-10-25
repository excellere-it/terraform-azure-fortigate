# =============================================================================
# FORTIGATE MODULE - DATA SOURCES
# =============================================================================
# This file contains all data source declarations for the FortiGate module.
# Data sources are used to fetch information from Azure that is needed for
# configuring FortiGate resources.
# =============================================================================

# =============================================================================
# AZURE CLIENT CONFIGURATION
# =============================================================================

# Get current Azure client configuration including tenant ID, subscription ID,
# and client ID. This information is used in the FortiGate bootstrap
# configuration to enable the Azure SDN connector for HA failover automation.
data "azurerm_client_config" "current" {}

# =============================================================================
# AZURE KEY VAULT SECRETS (OPTIONAL)
# =============================================================================
# These data sources retrieve secrets from Azure Key Vault when configured.
# Only active when var.key_vault_id is provided.

# Retrieve FortiGate admin password from Key Vault
data "azurerm_key_vault_secret" "admin_password" {
  count        = var.key_vault_id != null ? 1 : 0
  name         = var.admin_password_secret_name
  key_vault_id = var.key_vault_id
}

# Retrieve Azure service principal client secret from Key Vault
data "azurerm_key_vault_secret" "client_secret" {
  count        = var.key_vault_id != null ? 1 : 0
  name         = var.client_secret_secret_name
  key_vault_id = var.key_vault_id
}
