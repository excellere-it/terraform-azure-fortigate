# =============================================================================
# FORTIGATE APPLIANCE CONFIGURATION
# =============================================================================
# This file configures the FortiGate appliance using the FortiOS provider.
# Configuration is applied after the Azure VM infrastructure is deployed.
#
# Configuration Sections:
# 1. FortiOS Provider Configuration
# 2. System Settings
# 3. Network Interface Configuration
# 4. Static Routes
# 5. HA Configuration
# 6. Azure SDN Connector
# 7. Firewall Policies
#
# IMPORTANT: FortiGate configuration requires:
# - FortiGate VM must be fully booted (3-5 minutes)
# - Management access must be reachable from Terraform execution environment
# - Admin credentials must be valid
# =============================================================================

# =============================================================================
# LOCALS FOR FORTIGATE CONFIGURATION
# =============================================================================

locals {
  # FortiOS resources are created when fortigate configuration is enabled
  # The FortiOS provider must be configured externally by the caller
  fortios_enabled = var.enable_fortigate_configuration
}

# =============================================================================
# FORTIOS PROVIDER CONFIGURATION
# =============================================================================
# NOTE: This module requires an external FortiOS provider to be configured
# by the caller. The provider should be configured with connection details
# to the FortiGate management interface.
#
# Example provider configuration (in calling module):
#
# provider "fortios" {
#   hostname = module.fortigate.port1_private_ip
#   username = "admin"
#   password = data.azurerm_key_vault_secret.fortigate_password.value
#   port     = "8443"
#   insecure = true
#   timeout  = 300
#   retries  = 30
# }
#
# For HA deployments, use provider aliases for each instance:
#
# provider "fortios" {
#   alias    = "active"
#   hostname = module.fortigate_active.port1_private_ip
#   # ... other settings
# }
#
# provider "fortios" {
#   alias    = "passive"
#   hostname = module.fortigate_passive.port1_private_ip
#   # ... other settings
# }
#
# Then pass the provider to the module:
# module "fortigate_active" {
#   providers = {
#     fortios = fortios.active
#   }
# }
# =============================================================================

# =============================================================================
# SYSTEM SETTINGS
# =============================================================================

# System global settings
resource "fortios_system_global" "this" {
  count = local.fortios_enabled ? 1 : 0


  hostname          = local.computer_name
  timezone          = "12"  # UTC
  admin_sport       = tonumber(var.adminsport)
  admin_ssh_port    = 22
  admin_scp         = "enable"
  admintimeout      = 480  # 8 hours
  gui_theme         = "blue"
  cfg_save          = "automatic"
  cfg_revert_timeout = 10

  # Depends on VM being created
  depends_on = [
    azurerm_linux_virtual_machine.fgtvm,
    azurerm_linux_virtual_machine.customfgtvm
  ]
}

# System DNS settings
resource "fortios_system_dns" "this" {
  count = local.fortios_enabled ? 1 : 0


  primary   = "168.63.129.16"  # Azure DNS
  secondary = "8.8.8.8"         # Google DNS as backup
  protocol  = "cleartext"

  depends_on = [fortios_system_global.this]
}

# System NTP settings
resource "fortios_system_ntp" "this" {
  count = local.fortios_enabled ? 1 : 0


  ntpsync     = "enable"
  type        = "custom"
  syncinterval = 60

  dynamic_sort_subtable = "false"

  # Azure Time Server
  ntpserver {
    id             = 1
    server         = "time.windows.com"
    ntpv3          = "enable"
    authentication = "disable"
  }

  depends_on = [fortios_system_global.this]
}

# =============================================================================
# NETWORK INTERFACE CONFIGURATION
# =============================================================================

# Port1 - Management Interface
resource "fortios_system_interface" "port1" {
  count = local.fortios_enabled ? 1 : 0


  name           = "port1"
  vdom           = "root"
  mode           = "static"
  ip             = "${var.port1}/${local.port1_cidr_prefix}"
  allowaccess    = "ping https ssh http"
  type           = "physical"
  alias          = "mgmt"
  role           = "lan"
  snmp_index     = 1
  description    = "Management Interface"

  depends_on = [fortios_system_global.this]
}

# Port2 - WAN/Public Interface
resource "fortios_system_interface" "port2" {
  count = local.fortios_enabled ? 1 : 0


  name           = "port2"
  vdom           = "root"
  mode           = "static"
  ip             = "${var.port2}/${local.port2_cidr_prefix}"
  allowaccess    = "ping"
  type           = "physical"
  alias          = "wan"
  role           = "wan"
  snmp_index     = 2
  description    = "WAN/Public Interface"

  depends_on = [fortios_system_global.this]
}

# Port3 - LAN/Private Interface
resource "fortios_system_interface" "port3" {
  count = local.fortios_enabled ? 1 : 0


  name           = "port3"
  vdom           = "root"
  mode           = "static"
  ip             = "${var.port3}/${local.port3_cidr_prefix}"
  allowaccess    = "ping"
  type           = "physical"
  alias          = "lan"
  role           = "lan"
  snmp_index     = 3
  description    = "LAN/Private Interface"

  depends_on = [fortios_system_global.this]
}

# Port4 - HA Sync Interface
resource "fortios_system_interface" "port4" {
  count = local.fortios_enabled ? 1 : 0


  name           = "port4"
  vdom           = "root"
  mode           = "static"
  ip             = "${var.port4}/${local.port4_cidr_prefix}"
  allowaccess    = "ping"
  type           = "physical"
  alias          = "hasync"
  role           = "lan"
  snmp_index     = 4
  description    = "HA Sync Interface"

  depends_on = [fortios_system_global.this]
}

# Port5 - Optional Interface
resource "fortios_system_interface" "port5" {
  count = local.fortios_enabled && var.port5 != null ? 1 : 0


  name           = "port5"
  vdom           = "root"
  mode           = "static"
  ip             = "${var.port5}/${local.port5_cidr_prefix}"
  allowaccess    = "ping"
  type           = "physical"
  alias          = "dmz"
  role           = "lan"
  snmp_index     = 5
  description    = "Optional DMZ/Additional Interface"

  depends_on = [fortios_system_global.this]
}

# Port6 - Optional Interface
resource "fortios_system_interface" "port6" {
  count = local.fortios_enabled && var.port6 != null ? 1 : 0


  name           = "port6"
  vdom           = "root"
  mode           = "static"
  ip             = "${var.port6}/${local.port6_cidr_prefix}"
  allowaccess    = "ping"
  type           = "physical"
  alias          = "dmz2"
  role           = "lan"
  snmp_index     = 6
  description    = "Optional DMZ/Additional Interface"

  depends_on = [fortios_system_global.this]
}

# =============================================================================
# STATIC ROUTES
# =============================================================================

# Default route via port2 (WAN)
resource "fortios_router_static" "default_route" {
  count = local.fortios_enabled ? 1 : 0


  seq_num  = 1
  dst      = "0.0.0.0/0"
  gateway  = var.port2gateway
  device   = "port2"
  distance = 10
  priority = 0
  comment  = "Default route via WAN gateway"

  depends_on = [
    fortios_system_interface.port2
  ]
}

# Management network route via port1
resource "fortios_router_static" "mgmt_route" {
  count = local.fortios_enabled ? 1 : 0


  seq_num  = 2
  dst      = "168.63.129.16/32"  # Azure Metadata Service
  gateway  = var.port1gateway
  device   = "port1"
  distance = 5
  priority = 0
  comment  = "Route to Azure Metadata Service via Management"

  depends_on = [
    fortios_system_interface.port1
  ]
}

# =============================================================================
# HIGH AVAILABILITY CONFIGURATION
# =============================================================================

# HA configuration (only if peer IPs are provided)
resource "fortios_system_ha" "this" {
  count = local.fortios_enabled && (var.active_peerip != null || var.passive_peerip != null) ? 1 : 0


  group_name           = "azure-ha-cluster"
  mode                 = "a-p"  # Active-Passive
  password             = local.admin_password
  hbdev                = "port4 0"  # HA heartbeat on port4
  session_pickup       = "enable"
  session_pickup_connectionless = "enable"
  session_pickup_nat   = "enable"
  session_pickup_expectation = "enable"
  override             = var.is_passive ? "disable" : "enable"
  priority             = var.is_passive ? 100 : 200  # Active has higher priority
  monitor              = "port2 port3"  # Monitor WAN and LAN interfaces

  dynamic_sort_subtable = "false"

  depends_on = [
    fortios_system_interface.port1,
    fortios_system_interface.port2,
    fortios_system_interface.port3,
    fortios_system_interface.port4
  ]
}

# =============================================================================
# AZURE SDN CONNECTOR
# =============================================================================

# Azure SDN Connector (for HA failover)
resource "fortios_system_sdnconnector" "azure" {
  count = local.fortios_enabled && var.user_assigned_identity_id != null ? 1 : 0


  name            = "azure-sdn"
  type            = "azure"
  status          = "enable"
  update_interval = 60
  use_metadata_iam = "enable"  # Use managed identity

  # Azure configuration
  tenant_id       = data.azurerm_client_config.current.tenant_id
  subscription_id = data.azurerm_client_config.current.subscription_id
  resource_group  = var.resource_group_name

  # HA configuration - sync public IP on failover
  dynamic "route_table" {
    for_each = var.active_peerip != null || var.passive_peerip != null ? [1] : []
    content {
      name                = var.public_ip_name
      subscription_id     = data.azurerm_client_config.current.subscription_id
      resource_group      = var.resource_group_name
    }
  }

  depends_on = [
    fortios_system_global.this,
    azurerm_linux_virtual_machine.fgtvm,
    azurerm_linux_virtual_machine.customfgtvm
  ]
}

# =============================================================================
# FIREWALL OBJECTS
# =============================================================================

# Address object for Azure Virtual Network
resource "fortios_firewall_address" "azure_vnet" {
  count = local.fortios_enabled ? 1 : 0


  name    = "azure-vnet"
  type    = "subnet"
  subnet  = "10.0.0.0/8"
  comment = "Azure Virtual Network address space"

  depends_on = [fortios_system_global.this]
}

# Address object for RFC1918 private networks
resource "fortios_firewall_address" "rfc1918" {
  count = local.fortios_enabled ? 1 : 0


  name    = "rfc1918-all"
  type    = "subnet"
  subnet  = "10.0.0.0/8"
  comment = "RFC1918 private network - 10.0.0.0/8"

  depends_on = [fortios_system_global.this]
}

# =============================================================================
# FIREWALL POLICIES
# =============================================================================

# Policy: LAN to WAN (Outbound)
resource "fortios_firewall_policy" "lan_to_wan" {
  count = local.fortios_enabled ? 1 : 0


  name        = "lan-to-wan-outbound"
  action      = "accept"
  status      = "enable"
  schedule    = "always"
  logtraffic  = "all"
  nat         = "enable"
  comments    = "Allow LAN to WAN outbound traffic with NAT"

  srcintf {
    name = "port3"
  }

  dstintf {
    name = "port2"
  }

  srcaddr {
    name = fortios_firewall_address.azure_vnet[0].name
  }

  dstaddr {
    name = "all"
  }

  service {
    name = "ALL"
  }

  depends_on = [
    fortios_system_interface.port2,
    fortios_system_interface.port3,
    fortios_firewall_address.azure_vnet
  ]
}

# Policy: WAN to LAN (Inbound) - DENY by default
resource "fortios_firewall_policy" "wan_to_lan_deny" {
  count = local.fortios_enabled ? 1 : 0


  name        = "wan-to-lan-deny"
  action      = "deny"
  status      = "enable"
  schedule    = "always"
  logtraffic  = "all"
  comments    = "Explicit deny for WAN to LAN traffic (default deny)"

  srcintf {
    name = "port2"
  }

  dstintf {
    name = "port3"
  }

  srcaddr {
    name = "all"
  }

  dstaddr {
    name = fortios_firewall_address.azure_vnet[0].name
  }

  service {
    name = "ALL"
  }

  depends_on = [
    fortios_system_interface.port2,
    fortios_system_interface.port3,
    fortios_firewall_address.azure_vnet,
    fortios_firewall_policy.lan_to_wan
  ]
}
