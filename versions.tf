# =============================================================================
# FORTIGATE MODULE - VERSION REQUIREMENTS
# =============================================================================
# This file defines Terraform and provider version constraints for the module.
# Version constraints ensure compatibility and consistent behavior across
# different environments.
# =============================================================================

terraform {
  # Minimum Terraform version required for this module
  # Version 1.13.4+ is required for the features used in this module
  required_version = ">= 1.13.4"

  # Required providers and their version constraints
  required_providers {
    # Azure Resource Manager provider for all Azure resources
    # Version 3.x provides the necessary features for FortiGate deployment
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}
