# =============================================================================
# FORTIGATE MODULE - OUTPUTS
# =============================================================================
# This file defines all output values for the FortiGate module.
# Outputs provide information about deployed resources that can be used by
# other Terraform configurations or displayed to users.
# =============================================================================

# =============================================================================
# NAMING & TAGGING OUTPUTS
# =============================================================================

output "naming_suffix" {
  description = "The standardized naming suffix from terraform-namer (e.g., 'firewall-centralus-prd-kmi-0')"
  value       = module.naming.resource_suffix
}

output "naming_suffix_short" {
  description = "The short naming suffix from terraform-namer (e.g., 'firewall-cu-prd-kmi-0')"
  value       = module.naming.resource_suffix_short
}

output "naming_suffix_vm" {
  description = "The VM-optimized naming suffix (max 15 chars) from terraform-namer"
  value       = module.naming.resource_suffix_vm
}

output "common_tags" {
  description = "The complete set of tags applied to all resources (terraform-namer + module-specific + user-provided)"
  value       = local.common_tags
}

# =============================================================================
# VIRTUAL MACHINE OUTPUTS
# =============================================================================

output "fortigate_vm_id" {
  description = "Azure resource ID of the FortiGate virtual machine"
  value       = local.vm_id
}

output "fortigate_vm_name" {
  description = "Name of the FortiGate virtual machine"
  value       = local.vm_name
}

output "fortigate_computer_name" {
  description = "Computer name (hostname) of the FortiGate VM"
  value       = local.computer_name
}

# =============================================================================
# MANAGEMENT & ACCESS
# =============================================================================

output "fortigate_management_url" {
  description = "HTTPS URL for FortiGate management interface (GUI access). Null if create_management_public_ip = false"
  value       = var.create_management_public_ip ? "https://${azurerm_public_ip.mgmt_ip[0].ip_address}:${var.adminsport}" : null
}

output "fortigate_admin_username" {
  description = "Administrator username for FortiGate login"
  value       = var.adminusername
}

output "management_public_ip" {
  description = "Public IP address for FortiGate management interface (port1). Null if create_management_public_ip = false (private-only deployment)"
  value       = var.create_management_public_ip ? azurerm_public_ip.mgmt_ip[0].ip_address : null
}

output "management_public_ip_id" {
  description = "Azure resource ID of the management public IP. Null if create_management_public_ip = false"
  value       = var.create_management_public_ip ? azurerm_public_ip.mgmt_ip[0].id : null
}

# =============================================================================
# NETWORK INTERFACE OUTPUTS
# =============================================================================

output "port1_id" {
  description = "Azure resource ID of port1 network interface (HA Management)"
  value       = azurerm_network_interface.port1.id
}

output "port1_private_ip" {
  description = "Private IP address of port1 (HA Management interface)"
  value       = azurerm_network_interface.port1.private_ip_address
}

output "port2_id" {
  description = "Azure resource ID of port2 network interface (WAN/Public)"
  value       = azurerm_network_interface.port2.id
}

output "port2_private_ip" {
  description = "Private IP address of port2 (WAN/Public interface)"
  value       = azurerm_network_interface.port2.private_ip_address
}

output "port3_id" {
  description = "Azure resource ID of port3 network interface (LAN/Private)"
  value       = azurerm_network_interface.port3.id
}

output "port3_private_ip" {
  description = "Private IP address of port3 (LAN/Private interface)"
  value       = azurerm_network_interface.port3.private_ip_address
}

output "port4_id" {
  description = "Azure resource ID of port4 network interface (HA Sync)"
  value       = azurerm_network_interface.port4.id
}

output "port4_private_ip" {
  description = "Private IP address of port4 (HA Sync interface)"
  value       = azurerm_network_interface.port4.private_ip_address
}

output "port5_id" {
  description = "Azure resource ID of port5 network interface (optional additional interface). Null if port5 not configured"
  value       = var.port5subnet_id != null && var.port5 != null ? azurerm_network_interface.port5[0].id : null
}

output "port5_private_ip" {
  description = "Private IP address of port5 (optional additional interface). Null if port5 not configured"
  value       = var.port5subnet_id != null && var.port5 != null ? azurerm_network_interface.port5[0].private_ip_address : null
}

output "port6_id" {
  description = "Azure resource ID of port6 network interface (optional additional interface). Null if port6 not configured"
  value       = var.port6subnet_id != null && var.port6 != null ? azurerm_network_interface.port6[0].id : null
}

output "port6_private_ip" {
  description = "Private IP address of port6 (optional additional interface). Null if port6 not configured"
  value       = var.port6subnet_id != null && var.port6 != null ? azurerm_network_interface.port6[0].private_ip_address : null
}

# Convenience output with all interface IPs
output "all_private_ips" {
  description = "Map of all FortiGate private IP addresses by port (includes optional port5/port6)"
  value = merge(
    {
      port1 = azurerm_network_interface.port1.private_ip_address
      port2 = azurerm_network_interface.port2.private_ip_address
      port3 = azurerm_network_interface.port3.private_ip_address
      port4 = azurerm_network_interface.port4.private_ip_address
    },
    var.port5subnet_id != null && var.port5 != null ? { port5 = azurerm_network_interface.port5[0].private_ip_address } : {},
    var.port6subnet_id != null && var.port6 != null ? { port6 = azurerm_network_interface.port6[0].private_ip_address } : {}
  )
}

# =============================================================================
# NETWORK SECURITY GROUP OUTPUTS
# =============================================================================

output "public_nsg_id" {
  description = "Azure resource ID of the public network security group (port1, port4)"
  value       = azurerm_network_security_group.publicnetworknsg.id
}

output "public_nsg_name" {
  description = "Name of the public network security group"
  value       = azurerm_network_security_group.publicnetworknsg.name
}

output "private_nsg_id" {
  description = "Azure resource ID of the private network security group (port2, port3)"
  value       = azurerm_network_security_group.privatenetworknsg.id
}

output "private_nsg_name" {
  description = "Name of the private network security group"
  value       = azurerm_network_security_group.privatenetworknsg.name
}

# =============================================================================
# STORAGE OUTPUTS
# =============================================================================

output "data_disk_id" {
  description = "Azure resource ID of the FortiGate data disk (used for logs)"
  value       = azurerm_managed_disk.fgt_data_drive.id
}

output "data_disk_name" {
  description = "Name of the FortiGate data disk"
  value       = azurerm_managed_disk.fgt_data_drive.name
}

# =============================================================================
# MONITORING & DIAGNOSTICS OUTPUTS
# =============================================================================

output "diagnostics_enabled" {
  description = "Indicates if Azure Monitor diagnostics are enabled"
  value       = var.enable_diagnostics
}

output "nsg_flow_logs_enabled" {
  description = "Indicates if NSG flow logs are enabled"
  value       = var.enable_nsg_flow_logs
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID used for diagnostics (if configured)"
  value       = var.log_analytics_workspace_id
}

# =============================================================================
# FORTIGATE CONFIGURATION OUTPUTS (FORTIOS PROVIDER)
# =============================================================================

output "fortigate_configuration_enabled" {
  description = "Indicates if FortiGate appliance configuration via FortiOS provider is enabled"
  value       = var.enable_fortigate_configuration
}

output "fortigate_management_host" {
  description = "Hostname/IP used for FortiOS provider connection to FortiGate management interface. Null if configuration is disabled"
  value       = local.fortigate_management_host
  sensitive   = false
}

output "fortigate_system_hostname" {
  description = "FortiGate system hostname configured via FortiOS provider. Null if configuration is disabled"
  value       = var.enable_fortigate_configuration ? local.computer_name : null
}

output "fortigate_ha_enabled" {
  description = "Indicates if FortiGate HA configuration is enabled (based on peer IP configuration)"
  value       = var.active_peerip != null || var.passive_peerip != null
}

output "fortigate_ha_mode" {
  description = "FortiGate HA mode: 'active' or 'passive'. Null if HA is not configured"
  value = (var.active_peerip != null || var.passive_peerip != null) ? (
    var.is_passive ? "passive" : "active"
  ) : null
}

output "fortigate_interfaces_configured" {
  description = "List of FortiGate interfaces configured via FortiOS provider"
  value = var.enable_fortigate_configuration ? [
    "port1 (mgmt)",
    "port2 (wan)",
    "port3 (lan)",
    "port4 (hasync)",
    var.port5 != null ? "port5 (dmz)" : null,
    var.port6 != null ? "port6 (dmz2)" : null
  ] : []
}

output "fortigate_azure_sdn_connector_enabled" {
  description = "Indicates if FortiGate Azure SDN connector is configured for HA failover"
  value       = var.enable_fortigate_configuration && var.user_assigned_identity_id != null
}

output "fortigate_configuration_summary" {
  description = "Summary of FortiGate configuration applied via FortiOS provider"
  value = var.enable_fortigate_configuration ? {
    hostname                = local.computer_name
    management_url          = var.create_management_public_ip ? "https://${azurerm_public_ip.mgmt_ip[0].ip_address}:${var.adminsport}" : "https://${var.port1}:${var.adminsport}"
    admin_username          = var.adminusername
    ha_enabled              = var.active_peerip != null || var.passive_peerip != null
    ha_role                 = var.is_passive ? "passive" : "active"
    azure_sdn_enabled       = var.user_assigned_identity_id != null
    interfaces_count        = 4 + (var.port5 != null ? 1 : 0) + (var.port6 != null ? 1 : 0)
    fortios_provider_host   = local.fortigate_management_host
    configuration_applied   = true
  } : {
    hostname                = null
    management_url          = null
    admin_username          = null
    ha_enabled              = false
    ha_role                 = null
    azure_sdn_enabled       = false
    interfaces_count        = 0
    fortios_provider_host   = null
    configuration_applied   = false
  }
}
