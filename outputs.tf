# =============================================================================
# FORTIGATE MODULE - OUTPUTS
# =============================================================================
# This file defines all output values for the FortiGate module.
# Outputs provide information about deployed resources that can be used by
# other Terraform configurations or displayed to users.
# =============================================================================

# =============================================================================
# VIRTUAL MACHINE OUTPUTS
# =============================================================================

output "fortigate_vm_id" {
  description = "Azure resource ID of the FortiGate virtual machine"
  value       = local.vm_id
}

output "fortigate_vm_name" {
  description = "Name of the FortiGate virtual machine"
  value       = var.name
}

output "fortigate_computer_name" {
  description = "Computer name (hostname) of the FortiGate VM"
  value       = var.computer_name
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
