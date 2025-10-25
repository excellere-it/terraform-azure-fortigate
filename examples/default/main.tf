# =============================================================================
# FORTIGATE DEPLOYMENT EXAMPLE - SINGLE INSTANCE
# =============================================================================
# This example demonstrates deploying a single FortiGate VM in Azure with
# Pay-As-You-Go (PAYG) licensing. Suitable for development, testing, or
# small office deployments.
#
# Prerequisites:
# - Existing Resource Group
# - Virtual Network with 4 subnets (management, sync, public, private)
# - Public IP for cluster VIP
# - Storage account for boot diagnostics
# - Service principal for Azure SDN connector
# =============================================================================

# =============================================================================
# DATA SOURCES
# =============================================================================

# Get information about existing resource group
data "azurerm_resource_group" "example" {
  name = "rg-network-example"
}

# Get information about existing virtual network
data "azurerm_virtual_network" "example" {
  name                = "vnet-example"
  resource_group_name = data.azurerm_resource_group.example.name
}

# Get subnet information
data "azurerm_subnet" "mgmt" {
  name                 = "snet-mgmt"
  virtual_network_name = data.azurerm_virtual_network.example.name
  resource_group_name  = data.azurerm_resource_group.example.name
}

data "azurerm_subnet" "sync" {
  name                 = "snet-sync"
  virtual_network_name = data.azurerm_virtual_network.example.name
  resource_group_name  = data.azurerm_resource_group.example.name
}

data "azurerm_subnet" "public" {
  name                 = "snet-public"
  virtual_network_name = data.azurerm_virtual_network.example.name
  resource_group_name  = data.azurerm_resource_group.example.name
}

data "azurerm_subnet" "private" {
  name                 = "snet-private"
  virtual_network_name = data.azurerm_virtual_network.example.name
  resource_group_name  = data.azurerm_resource_group.example.name
}

# Get existing public IP for cluster VIP
data "azurerm_public_ip" "cluster_vip" {
  name                = "pip-fortigate-cluster"
  resource_group_name = data.azurerm_resource_group.example.name
}

# Get storage account for boot diagnostics
data "azurerm_storage_account" "diag" {
  name                = "stdiagexample"
  resource_group_name = data.azurerm_resource_group.example.name
}

# =============================================================================
# FORTIGATE MODULE
# =============================================================================

module "fortigate" {
  source = "../.."

  # VM Configuration
  name          = "fortigate-example"
  computer_name = "fgt-example"
  location      = data.azurerm_resource_group.example.location
  size          = "Standard_F8s_v2" # Must support 4 NICs
  zone          = "1"               # Availability zone

  # Resource Group
  resource_group_name = data.azurerm_resource_group.example.name

  # Network Configuration - 4 Subnets Required
  hamgmtsubnet_id  = data.azurerm_subnet.mgmt.id    # port1 - Management
  hasyncsubnet_id  = data.azurerm_subnet.sync.id    # port4 - HA Sync
  publicsubnet_id  = data.azurerm_subnet.public.id  # port2 - WAN/Public
  privatesubnet_id = data.azurerm_subnet.private.id # port3 - LAN/Private

  # Public IP for port2 (cluster VIP)
  public_ip_id   = data.azurerm_public_ip.cluster_vip.id
  public_ip_name = data.azurerm_public_ip.cluster_vip.name

  # Management Public IP (port1)
  # Set to false for private-only deployments (VPN/ExpressRoute access)
  # When false, access FortiGate via port1 private IP (10.0.1.10)
  create_management_public_ip = true # Set to false for production with VPN access

  # Static IP Addresses (must be within subnet ranges)
  port1 = "10.0.1.10" # Management subnet
  port2 = "10.0.2.10" # Public subnet
  port3 = "10.0.3.10" # Private subnet
  port4 = "10.0.4.10" # Sync subnet

  # Subnet Masks
  port1mask = "255.255.255.0"
  port2mask = "255.255.255.0"
  port3mask = "255.255.255.0"
  port4mask = "255.255.255.0"

  # Gateway IPs
  port1gateway = "10.0.1.1" # Management gateway
  port2gateway = "10.0.2.1" # Default route gateway

  # Optional Additional Network Interfaces (port5, port6)
  # Uncomment to enable additional interfaces for DMZ, additional WANs, etc.
  # Ensure VM size supports 6 NICs (e.g., Standard_F8s_v2 supports 8 NICs)
  # port5subnet_id = data.azurerm_subnet.dmz.id
  # port5          = "10.0.5.10"
  #
  # port6subnet_id = data.azurerm_subnet.wan2.id
  # port6          = "10.0.6.10"

  # Authentication (CHANGE THESE IN PRODUCTION!)
  adminusername = "azureadmin"
  adminsport    = "8443" # HTTPS management port

  # Method 1: Azure Key Vault (Recommended for Production)
  # Uncomment these lines and comment out Method 2 to use Key Vault
  # key_vault_id                 = data.azurerm_key_vault.main.id
  # admin_password_secret_name   = "fortigate-admin-password"
  # client_secret_secret_name    = "fortigate-client-secret"

  # Method 2: Direct Variables (Development Only)
  # For production, use Key Vault integration above
  adminpassword = "ChangeMe123!" # WARNING: Change this!
  client_secret = var.service_principal_secret

  # Bootstrap Configuration
  bootstrap = "config-active.conf"

  # Boot Diagnostics
  boot_diagnostics_storage_endpoint = data.azurerm_storage_account.diag.primary_blob_endpoint

  # Licensing
  license_type = "payg" # Pay-As-You-Go
  arch         = "x86"  # x86 or arm

  # FortiOS Version
  fgtversion = "7.6.3"

  # HA Configuration (null for standalone)
  active_peerip  = null # Set for HA pair
  passive_peerip = null # Set for HA pair

  # Disk Configuration (optional)
  data_disk_size_gb      = 30             # 30 GB data disk
  data_disk_storage_type = "Standard_LRS" # Standard HDD
  data_disk_caching      = "ReadWrite"    # ReadWrite caching

  # Network Security Configuration
  # For production, restrict management access to specific CIDRs
  enable_management_access_restriction = false # Set to true for production
  management_access_cidrs              = []    # Add your admin IPs/networks here
  management_ports                     = [443, 8443, 22]

  # Monitoring & Diagnostics (optional)
  # Uncomment to enable Azure Monitor integration for VM and network metrics
  # enable_diagnostics            = true
  # log_analytics_workspace_id    = data.azurerm_log_analytics_workspace.main.id
  # diagnostic_retention_days     = 30
  #
  # # NSG Flow Logs (optional - requires enable_diagnostics)
  # enable_nsg_flow_logs              = true
  # nsg_flow_logs_storage_account_id  = data.azurerm_storage_account.flow_logs.id
  # nsg_flow_logs_retention_days      = 7

  # Structured Tagging (optional)
  environment = "Development"
  cost_center = "IT-Network"
  owner       = "network-team@example.com"
  project     = "Network-Security"

  # Additional Custom Tags
  tags = {
    Purpose     = "Testing"
    Backup      = "Daily"
    Application = "Firewall"
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "fortigate_vm_id" {
  description = "Azure resource ID of the FortiGate VM"
  value       = module.fortigate.fortigate_vm_id
}

output "fortigate_management_url" {
  description = "HTTPS URL for FortiGate management interface"
  value       = module.fortigate.fortigate_management_url
}

output "management_public_ip" {
  description = "Public IP address for FortiGate management"
  value       = module.fortigate.management_public_ip
}

output "port1_private_ip" {
  description = "Port1 (Management) private IP address"
  value       = module.fortigate.port1_private_ip
}

output "port2_private_ip" {
  description = "Port2 (WAN/Public) private IP address"
  value       = module.fortigate.port2_private_ip
}

output "port3_private_ip" {
  description = "Port3 (LAN/Private) private IP address"
  value       = module.fortigate.port3_private_ip
}

output "port4_private_ip" {
  description = "Port4 (HA Sync) private IP address"
  value       = module.fortigate.port4_private_ip
}
