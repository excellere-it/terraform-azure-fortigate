# =============================================================================
# FORTIGATE MODULE - LOCAL VALUES
# =============================================================================
# This file contains computed local values used throughout the module.
# Local values help avoid repetition and make the code more maintainable.
# =============================================================================

locals {
  # Secret resolution logic
  # Prioritizes Key Vault secrets over direct variables
  # SECURITY: No default password - users MUST provide password or Key Vault
  resolved_admin_password = var.key_vault_id != null ? data.azurerm_key_vault_secret.admin_password[0].value : var.adminpassword

  resolved_client_secret = var.key_vault_id != null ? data.azurerm_key_vault_secret.client_secret[0].value : (
    var.client_secret != null ? var.client_secret : ""
  )

  # Determine which VM resource to use for data disk attachment
  # Returns the ID of either the custom VM or marketplace VM
  vm_id = var.custom ? azurerm_linux_virtual_machine.customfgtvm[0].id : azurerm_linux_virtual_machine.fgtvm[0].id

  # Bootstrap configuration template variables
  # These are passed to the cloud-init template for FortiGate initialization
  bootstrap_vars = {
    type            = var.license_type
    license_file    = var.license
    format          = var.license_format
    port1_ip        = var.port1
    port1_mask      = var.port1mask
    port2_ip        = var.port2
    port2_mask      = var.port2mask
    port3_ip        = var.port3
    port3_mask      = var.port3mask
    port4_ip        = var.port4
    port4_mask      = var.port4mask
    active_peerip   = var.active_peerip != null ? var.active_peerip : "169.254.0.1"
    passive_peerip  = var.passive_peerip != null ? var.passive_peerip : "169.254.0.2"
    mgmt_gateway_ip = var.port1gateway
    defaultgwy      = var.port2gateway
    tenant          = data.azurerm_client_config.current.tenant_id
    subscription    = data.azurerm_client_config.current.subscription_id
    clientid        = data.azurerm_client_config.current.client_id
    clientsecret    = local.resolved_client_secret
    adminsport      = var.adminsport
    rsg             = var.resource_group_name
    clusterip       = var.public_ip_name
  }

  # Network interface IDs in the correct order for FortiGate
  # Order matters: port1, port2, port3, port4, [port5], [port6]
  # port5 and port6 are conditionally appended if configured
  network_interface_ids = concat(
    [
      azurerm_network_interface.port1.id,
      azurerm_network_interface.port2.id,
      azurerm_network_interface.port3.id,
      azurerm_network_interface.port4.id
    ],
    var.port5subnet_id != null && var.port5 != null ? [azurerm_network_interface.port5[0].id] : [],
    var.port6subnet_id != null && var.port6 != null ? [azurerm_network_interface.port6[0].id] : []
  )

  # Simplified tagging using terraform-namer + module-specific metadata
  # terraform-namer already provides: company, contact, environment, location, repository, workload
  # We only add FortiGate-specific metadata
  common_tags = merge(
    module.naming.tags,
    {
      Module            = "terraform-azurerm-fortigate"
      FortiGateInstance = local.computer_name
    },
    var.tags # User-provided tags can override defaults
  )

  # Management access rules
  # Create a list of rules for each combination of CIDR and port
  management_access_rules = var.enable_management_access_restriction && length(var.management_access_cidrs) > 0 ? flatten([
    for idx, cidr in var.management_access_cidrs : [
      for port_idx, port in var.management_ports : {
        name                       = "Allow-Mgmt-${replace(cidr, "/", "_")}-Port${port}"
        priority                   = 1000 + (idx * 10) + port_idx
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = tostring(port)
        source_address_prefix      = cidr
        destination_address_prefix = "*"
      }
    ]
  ]) : []
}
