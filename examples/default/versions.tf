# =============================================================================
# TERRAFORM VERSION REQUIREMENTS - EXAMPLE
# =============================================================================
# Version requirements for the FortiGate deployment example.
# These should match the module's version requirements.

terraform {
  # Minimum Terraform version required
  required_version = ">= 1.13.4"

  # Required providers
  required_providers {
    # Azure Resource Manager provider for Azure resources
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}
