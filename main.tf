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
# - Consistent naming and tagging via terraform-namer integration
#
# Module Structure:
# - data.tf: Data source declarations
# - locals.tf: Local computed values
# - network.tf: Network resources (NSGs, NICs, Public IPs)
# - compute.tf: Compute resources (VMs, Managed Disks)
# - main.tf: Naming module and custom image resource (this file)
# - variables.tf: Input variable definitions
# - outputs.tf: Output value definitions
# - versions.tf: Provider version requirements
# - fortinet_agreement.tf: Azure Marketplace agreement
#
# Dependencies:
# - terraform-terraform-namer (required for consistent naming and tagging)
#
# Usage:
# See examples/ directory for detailed usage examples and README.md for
# comprehensive documentation.
# =============================================================================

# =============================================================================
# NAMING AND TAGGING
# =============================================================================

module "naming" {
  source = "../terraform-terraform-namer"

  contact     = var.contact
  environment = var.environment
  location    = var.location
  repository  = var.repository
  workload    = var.workload
}

# Standardized resource names using terraform-namer outputs with Azure prefixes
# This ensures consistent naming across all FortiGate resources
locals {
  # Base name from terraform-namer (e.g., "firewall-centralus-prd-kmi-0")
  base_name = module.naming.resource_suffix

  # Azure resource naming with standard prefixes
  # VM names use resource_suffix_vm (max 15 chars for Windows compatibility)
  vm_name = "vm-${module.naming.resource_suffix_vm}"

  # Network interface names (one per port)
  nic_port1_name = "nic-${local.base_name}-port1"
  nic_port2_name = "nic-${local.base_name}-port2"
  nic_port3_name = "nic-${local.base_name}-port3"
  nic_port4_name = "nic-${local.base_name}-port4"
  nic_port5_name = "nic-${local.base_name}-port5"
  nic_port6_name = "nic-${local.base_name}-port6"

  # Network Security Group names
  nsg_public_name  = "nsg-${local.base_name}-public"
  nsg_private_name = "nsg-${local.base_name}-private"

  # Public IP names
  pip_mgmt_name = "pip-${local.base_name}-mgmt"

  # Disk names
  disk_data_name = "disk-${local.base_name}-data"

  # Custom image name (if used)
  custom_image_name = "img-${local.base_name}-custom"

  # Computer name for VM (hostname) - limited to 15 characters for compatibility
  # Uses the short compact format to stay within limits
  computer_name = module.naming.resource_suffix_vm
}

# =============================================================================
# CUSTOM IMAGE (OPTIONAL)
# =============================================================================

# Create a custom FortiGate image from a VHD blob URI
# Only created when var.custom is set to true
# Useful for deploying custom or pre-configured FortiGate images
resource "azurerm_image" "custom" {
  count               = var.custom ? 1 : 0
  name                = local.custom_image_name
  resource_group_name = var.custom_image_resource_group_name != null ? var.custom_image_resource_group_name : var.resource_group_name
  location            = var.location

  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = var.customuri
    size_gb  = 2
  }

  tags = module.naming.tags
}
