# =============================================================================
# TERRAFORM AZURE FORTIGATE MODULE
# =============================================================================
# This is the main entry point for the FortiGate Azure Terraform module.
#
# This module deploys a FortiGate Next-Generation Firewall VM in Microsoft
# Azure with High Availability (HA) support. It provides a complete 4-port
# network architecture suitable for production enterprise environments.
#
# Key Features:
# - High Availability (HA) support with active-passive configuration
# - Flexible licensing: BYOL (Bring Your Own License) and PAYG (Pay As You Go)
# - Multiple architectures: x86 and ARM64 support
# - Custom images: Deploy from Azure Marketplace or custom VHD images
# - 4-port network architecture: Management, WAN, LAN, and HA sync
# - Azure SDN integration: Automatic failover using Azure SDN connector
# - Bootstrap configuration: Automated initial configuration via cloud-init
#
# Module Structure:
# - data.tf: Data source declarations
# - locals.tf: Local computed values
# - network.tf: Network resources (NSGs, NICs, Public IPs)
# - compute.tf: Compute resources (VMs, Managed Disks)
# - main.tf: Custom image resource (this file)
# - variables.tf: Input variable definitions
# - outputs.tf: Output value definitions
# - versions.tf: Provider version requirements
# - fortinet_agreement.tf: Azure Marketplace agreement
#
# Usage:
# See examples/ directory for detailed usage examples and README.md for
# comprehensive documentation.
# =============================================================================

# =============================================================================
# CUSTOM IMAGE (OPTIONAL)
# =============================================================================

# Create a custom FortiGate image from a VHD blob URI
# Only created when var.custom is set to true
# Useful for deploying custom or pre-configured FortiGate images
resource "azurerm_image" "custom" {
  count               = var.custom ? 1 : 0
  name                = var.custom_image_name
  resource_group_name = var.custom_image_resource_group_name
  location            = var.location

  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = var.customuri
    size_gb  = 2
  }
}
