# =============================================================================
# FORTIGATE MODULE - NETWORKING RESOURCES
# =============================================================================
# This file contains all networking-related resources for the FortiGate
# deployment including NSGs, NSG rules, network interfaces, and public IPs.
# =============================================================================

# =============================================================================
# PUBLIC IP ADDRESSES
# =============================================================================

# Management public IP for FortiGate port1 (HA MGMT interface)
# Standard SKU required for availability zone support
# Static allocation ensures IP doesn't change on VM restart
# Only created when var.create_management_public_ip = true
# Set to false for private-only deployments (VPN/ExpressRoute access)
resource "azurerm_public_ip" "mgmt_ip" {
  count               = var.create_management_public_ip ? 1 : 0
  name                = "${var.computer_name}mgmtip"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  allocation_method   = "Static"

  tags = local.common_tags
}

# =============================================================================
# NETWORK SECURITY GROUPS
# =============================================================================

# NSG for public-facing interfaces (port1 - HA MGMT, port4 - HA Sync)
# WARNING: Current rules allow all traffic - consider restricting for production
resource "azurerm_network_security_group" "publicnetworknsg" {
  name                = "${var.computer_name}-public"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = local.common_tags
}

# NSG for private interfaces (port2 - WAN/Public, port3 - LAN/Private)
# WARNING: Current rules allow all traffic - consider restricting for production
resource "azurerm_network_security_group" "privatenetworknsg" {
  name                = "${var.computer_name}-private"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = local.common_tags
}

# =============================================================================
# NETWORK SECURITY RULES
# =============================================================================

# Dynamic management access rules (port1)
# Creates one rule per CIDR/port combination when management restriction is enabled
# If no CIDRs specified or restriction disabled, falls back to unrestricted rule
resource "azurerm_network_security_rule" "management_access" {
  for_each = var.enable_management_access_restriction && length(var.management_access_cidrs) > 0 ? {
    for rule in local.management_access_rules :
    rule.name => rule
  } : {}

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.publicnetworknsg.name
}

# Fallback rule when management access restriction is disabled or no CIDRs specified
# WARNING: This allows management access from anywhere - only for development/testing
resource "azurerm_network_security_rule" "management_access_unrestricted" {
  count = !var.enable_management_access_restriction || length(var.management_access_cidrs) == 0 ? 1 : 0

  name                        = "Allow-Management-Unrestricted"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.publicnetworknsg.name
}

# Outbound rule for public NSG
# Allows all outbound traffic for management and HA sync communication
resource "azurerm_network_security_rule" "outgoing_public" {
  name                        = "egress"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.publicnetworknsg.name
}

# Inbound rule for private NSG
# Allows all inbound traffic on private interfaces for firewall processing
# This is typically acceptable as FortiGate handles the actual security policy
resource "azurerm_network_security_rule" "incoming_private" {
  name                        = "All"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.privatenetworknsg.name
}

# Outbound rule for private NSG
# Allows all outbound traffic for firewall processing
resource "azurerm_network_security_rule" "outgoing_private" {
  name                        = "egress-private"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.privatenetworknsg.name
}

# =============================================================================
# NETWORK INTERFACES
# =============================================================================
# FortiGate requires 4 network interfaces for HA deployment:
# - port1: HA Management interface (dedicated MGMT)
# - port2: WAN/Public interface (external traffic)
# - port3: LAN/Private interface (internal traffic)
# - port4: HA Sync interface (heartbeat and session sync)

# Port1 - HA Management Interface
# Used for FortiGate administrative access and monitoring
# Public IP attached only if var.create_management_public_ip = true
# For private-only deployments, access via VPN/ExpressRoute using private IP
# Accelerated networking enabled for better performance
resource "azurerm_network_interface" "port1" {
  name                           = "${var.computer_name}port1"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.hamgmtsubnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.port1
    primary                       = true
    public_ip_address_id          = var.create_management_public_ip ? azurerm_public_ip.mgmt_ip[0].id : null
  }

  tags = local.common_tags
}

# Port2 - WAN/Public Interface
# Used for external/internet-facing traffic
# IP forwarding enabled to allow routing through FortiGate
# Public IP association managed by HA failover (ignore_changes for public_ip_address_id)
resource "azurerm_network_interface" "port2" {
  name                           = "${var.computer_name}port2"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.publicsubnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.port2
    public_ip_address_id          = var.public_ip_id
  }

  lifecycle {
    ignore_changes = [ip_configuration[0].public_ip_address_id]
  }

  tags = local.common_tags
}

# Port3 - LAN/Private Interface
# Used for internal/private network traffic
# IP forwarding enabled to allow routing through FortiGate
resource "azurerm_network_interface" "port3" {
  name                           = "${var.computer_name}port3"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.privatesubnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.port3
  }

  tags = local.common_tags
}

# Port4 - HA Sync Interface
# Dedicated interface for HA heartbeat and session synchronization
# Critical for maintaining HA cluster state between active/passive nodes
resource "azurerm_network_interface" "port4" {
  name                           = "${var.computer_name}port4"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.hasyncsubnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.port4
  }

  tags = local.common_tags
}

# Port5 - Optional Additional Interface
# Created only when port5subnet_id and port5 are configured
# Use cases: DMZ zones, additional WAN connections, dedicated monitoring
resource "azurerm_network_interface" "port5" {
  count                          = var.port5subnet_id != null && var.port5 != null ? 1 : 0
  name                           = "${var.computer_name}port5"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.port5subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.port5
  }

  tags = local.common_tags
}

# Port6 - Optional Additional Interface
# Created only when port6subnet_id and port6 are configured
# Use cases: DMZ zones, additional WAN connections, dedicated monitoring
resource "azurerm_network_interface" "port6" {
  count                          = var.port6subnet_id != null && var.port6 != null ? 1 : 0
  name                           = "${var.computer_name}port6"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.port6subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.port6
  }

  tags = local.common_tags
}

# =============================================================================
# NSG TO NETWORK INTERFACE ASSOCIATIONS
# =============================================================================

# Associate public NSG with port1 (HA Management)
resource "azurerm_network_interface_security_group_association" "port1nsg" {
  depends_on                = [azurerm_network_interface.port1]
  network_interface_id      = azurerm_network_interface.port1.id
  network_security_group_id = azurerm_network_security_group.publicnetworknsg.id
}

# Associate public NSG with port4 (HA Sync)
resource "azurerm_network_interface_security_group_association" "port4nsg" {
  depends_on                = [azurerm_network_interface.port4]
  network_interface_id      = azurerm_network_interface.port4.id
  network_security_group_id = azurerm_network_security_group.publicnetworknsg.id
}

# Associate private NSG with port2 (WAN/Public)
# Note: Despite being "WAN", it uses private NSG to allow all traffic for firewall inspection
resource "azurerm_network_interface_security_group_association" "port2nsg" {
  depends_on                = [azurerm_network_interface.port2]
  network_interface_id      = azurerm_network_interface.port2.id
  network_security_group_id = azurerm_network_security_group.privatenetworknsg.id
}

# Associate private NSG with port3 (LAN/Private)
resource "azurerm_network_interface_security_group_association" "port3nsg" {
  depends_on                = [azurerm_network_interface.port3]
  network_interface_id      = azurerm_network_interface.port3.id
  network_security_group_id = azurerm_network_security_group.privatenetworknsg.id
}
