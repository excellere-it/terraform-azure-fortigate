# =============================================================================
# FORTIGATE MODULE - AZURE MARKETPLACE AGREEMENT
# =============================================================================
# This file manages the acceptance of Azure Marketplace legal terms for
# FortiGate VM images. This is required before deploying FortiGate from the
# Azure Marketplace when using BYOL licensing.
# =============================================================================

# =============================================================================
# MARKETPLACE AGREEMENT RESOURCE
# =============================================================================
# Accepts the legal terms and conditions for FortiGate VM in Azure Marketplace.
# Only created when var.accept = true
#
# USAGE:
# 1. Set var.accept = "true" to accept marketplace terms on first deployment
# 2. Run terraform apply to accept the agreement
# 3. Once accepted, set var.accept = "false" to prevent recreation
#
# NOTE:
# - Agreement acceptance is per Azure subscription
# - Only needs to be done once for each FortiGate SKU (publisher/offer/plan)
# - Required for BYOL deployments, not for PAYG
resource "azurerm_marketplace_agreement" "fortinet" {
  count     = var.accept ? 1 : 0
  publisher = var.publisher
  offer     = var.fgtoffer
  plan      = var.fgtsku[var.arch][var.license_type]
}