# =============================================================================
# FORTIGATE MODULE - MONITORING & DIAGNOSTICS
# =============================================================================
# This file contains monitoring and diagnostic resources for the FortiGate
# deployment including Azure Monitor diagnostic settings and NSG flow logs.
# =============================================================================

# =============================================================================
# VM DIAGNOSTIC SETTINGS
# =============================================================================

# Diagnostic settings for FortiGate VM
# Collects metrics and sends to Log Analytics workspace
# Only created when enable_diagnostics = true
resource "azurerm_monitor_diagnostic_setting" "vm" {
  count                      = var.enable_diagnostics && var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${local.computer_name}-vm-diagnostics"
  target_resource_id         = local.vm_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # VM Metrics
  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = var.diagnostic_retention_days > 0
      days    = var.diagnostic_retention_days
    }
  }
}

# =============================================================================
# NETWORK INTERFACE DIAGNOSTIC SETTINGS
# =============================================================================

# Diagnostic settings for port1 (Management) NIC
resource "azurerm_monitor_diagnostic_setting" "port1" {
  count                      = var.enable_diagnostics && var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${local.computer_name}-port1-diagnostics"
  target_resource_id         = azurerm_network_interface.port1.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = var.diagnostic_retention_days > 0
      days    = var.diagnostic_retention_days
    }
  }
}

# Diagnostic settings for port2 (WAN/Public) NIC
resource "azurerm_monitor_diagnostic_setting" "port2" {
  count                      = var.enable_diagnostics && var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${local.computer_name}-port2-diagnostics"
  target_resource_id         = azurerm_network_interface.port2.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = var.diagnostic_retention_days > 0
      days    = var.diagnostic_retention_days
    }
  }
}

# Diagnostic settings for port3 (LAN/Private) NIC
resource "azurerm_monitor_diagnostic_setting" "port3" {
  count                      = var.enable_diagnostics && var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${local.computer_name}-port3-diagnostics"
  target_resource_id         = azurerm_network_interface.port3.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = var.diagnostic_retention_days > 0
      days    = var.diagnostic_retention_days
    }
  }
}

# Diagnostic settings for port4 (HA Sync) NIC
resource "azurerm_monitor_diagnostic_setting" "port4" {
  count                      = var.enable_diagnostics && var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${local.computer_name}-port4-diagnostics"
  target_resource_id         = azurerm_network_interface.port4.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = var.diagnostic_retention_days > 0
      days    = var.diagnostic_retention_days
    }
  }
}

# =============================================================================
# NSG DIAGNOSTIC SETTINGS
# =============================================================================

# Diagnostic settings for public NSG (port1, port4)
resource "azurerm_monitor_diagnostic_setting" "public_nsg" {
  count                      = var.enable_diagnostics && var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${local.computer_name}-public-nsg-diagnostics"
  target_resource_id         = azurerm_network_security_group.publicnetworknsg.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "NetworkSecurityGroupEvent"

    retention_policy {
      enabled = var.diagnostic_retention_days > 0
      days    = var.diagnostic_retention_days
    }
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"

    retention_policy {
      enabled = var.diagnostic_retention_days > 0
      days    = var.diagnostic_retention_days
    }
  }
}

# Diagnostic settings for private NSG (port2, port3)
resource "azurerm_monitor_diagnostic_setting" "private_nsg" {
  count                      = var.enable_diagnostics && var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${local.computer_name}-private-nsg-diagnostics"
  target_resource_id         = azurerm_network_security_group.privatenetworknsg.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "NetworkSecurityGroupEvent"

    retention_policy {
      enabled = var.diagnostic_retention_days > 0
      days    = var.diagnostic_retention_days
    }
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"

    retention_policy {
      enabled = var.diagnostic_retention_days > 0
      days    = var.diagnostic_retention_days
    }
  }
}

# =============================================================================
# NSG FLOW LOGS
# =============================================================================

# NSG Flow Logs for public NSG
# Requires Network Watcher to be enabled in the region
resource "azurerm_network_watcher_flow_log" "public_nsg" {
  count                     = var.enable_nsg_flow_logs && var.nsg_flow_logs_storage_account_id != null ? 1 : 0
  name                      = "${local.computer_name}-public-nsg-flow-log"
  network_watcher_name      = "NetworkWatcher_${var.location}"
  resource_group_name       = "NetworkWatcherRG"
  network_security_group_id = azurerm_network_security_group.publicnetworknsg.id
  storage_account_id        = var.nsg_flow_logs_storage_account_id
  enabled                   = true

  retention_policy {
    enabled = var.nsg_flow_logs_retention_days > 0
    days    = var.nsg_flow_logs_retention_days
  }

  # Traffic Analytics integration (optional)
  dynamic "traffic_analytics" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      enabled               = true
      workspace_id          = split("/", var.log_analytics_workspace_id)[8]
      workspace_region      = var.location
      workspace_resource_id = var.log_analytics_workspace_id
      interval_in_minutes   = 10
    }
  }

  tags = local.common_tags
}

# NSG Flow Logs for private NSG
resource "azurerm_network_watcher_flow_log" "private_nsg" {
  count                     = var.enable_nsg_flow_logs && var.nsg_flow_logs_storage_account_id != null ? 1 : 0
  name                      = "${local.computer_name}-private-nsg-flow-log"
  network_watcher_name      = "NetworkWatcher_${var.location}"
  resource_group_name       = "NetworkWatcherRG"
  network_security_group_id = azurerm_network_security_group.privatenetworknsg.id
  storage_account_id        = var.nsg_flow_logs_storage_account_id
  enabled                   = true

  retention_policy {
    enabled = var.nsg_flow_logs_retention_days > 0
    days    = var.nsg_flow_logs_retention_days
  }

  # Traffic Analytics integration (optional)
  dynamic "traffic_analytics" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      enabled               = true
      workspace_id          = split("/", var.log_analytics_workspace_id)[8]
      workspace_region      = var.location
      workspace_resource_id = var.log_analytics_workspace_id
      interval_in_minutes   = 10
    }
  }

  tags = local.common_tags
}
