# =============================================================================
# FORTIGATE MODULE - COMPUTE RESOURCES
# =============================================================================
# This file contains all compute-related resources for the FortiGate deployment
# including virtual machines and managed disks.
# =============================================================================

# =============================================================================
# FORTIGATE VIRTUAL MACHINES
# =============================================================================
# Two VM resources are defined:
# 1. customfgtvm: For custom FortiGate images (when var.custom = true)
# 2. fgtvm: For marketplace FortiGate images (when var.custom = false)

# FortiGate VM from Custom Image
# Created when var.custom = true
# Uses a custom image created from a VHD blob
resource "azurerm_linux_virtual_machine" "customfgtvm" {
  count                 = var.custom ? 1 : 0
  name                  = local.vm_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = local.network_interface_ids
  size                  = var.size
  zone                  = var.zone # null for regional, "1"/"2"/"3" for zonal
  admin_username        = var.adminusername
  admin_password        = local.resolved_admin_password
  computer_name         = local.computer_name

  # Reference the custom image created in main.tf
  source_image_id = var.custom ? azurerm_image.custom[0].id : null

  # SECURITY: Enable encryption at host for double encryption
  encryption_at_host_enabled = var.enable_encryption_at_host

  # SECURITY: Managed identity for Azure SDN connector (replaces service principal)
  dynamic "identity" {
    for_each = var.user_assigned_identity_id != null || var.enable_system_assigned_identity ? [1] : []
    content {
      type = var.user_assigned_identity_id != null && var.enable_system_assigned_identity ? "SystemAssigned, UserAssigned" : (
        var.user_assigned_identity_id != null ? "UserAssigned" : "SystemAssigned"
      )
      identity_ids = var.user_assigned_identity_id != null ? [var.user_assigned_identity_id] : null
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_storage_type

    # SECURITY: Customer-managed key encryption (optional)
    disk_encryption_set_id = var.disk_encryption_set_id
  }

  # Bootstrap configuration using cloud-init
  # Configured via template file with network, HA, and Azure SDN settings
  # custom_data is ignored after initial deployment to prevent VM recreation
  custom_data = base64encode(templatefile("${path.module}/${var.bootstrap}", local.bootstrap_vars))

  disable_password_authentication = false

  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics_storage_endpoint
  }

  lifecycle {
    ignore_changes = [custom_data]
  }

  tags = local.common_tags
}

# FortiGate VM from Azure Marketplace
# Created when var.custom = false (default)
# Supports both BYOL and PAYG licensing models
# Supports both x86 and ARM64 architectures
resource "azurerm_linux_virtual_machine" "fgtvm" {
  count                 = var.custom ? 0 : 1
  name                  = local.vm_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = local.network_interface_ids
  size                  = var.size
  zone                  = var.zone # null for regional, "1"/"2"/"3" for zonal
  admin_username        = var.adminusername
  admin_password        = local.resolved_admin_password
  computer_name         = local.computer_name

  # Reference Azure Marketplace image
  # SKU is selected based on architecture (x86/arm) and license type (byol/payg)
  source_image_reference {
    publisher = var.publisher
    offer     = var.fgtoffer
    sku       = var.fgtsku[var.arch][var.license_type]
    version   = var.fgtversion
  }

  # Required for Azure Marketplace images
  # Must match the image reference SKU
  plan {
    name      = var.fgtsku[var.arch][var.license_type]
    publisher = var.publisher
    product   = var.fgtoffer
  }

  # SECURITY: Enable encryption at host for double encryption
  encryption_at_host_enabled = var.enable_encryption_at_host

  # SECURITY: Managed identity for Azure SDN connector (replaces service principal)
  dynamic "identity" {
    for_each = var.user_assigned_identity_id != null || var.enable_system_assigned_identity ? [1] : []
    content {
      type = var.user_assigned_identity_id != null && var.enable_system_assigned_identity ? "SystemAssigned, UserAssigned" : (
        var.user_assigned_identity_id != null ? "UserAssigned" : "SystemAssigned"
      )
      identity_ids = var.user_assigned_identity_id != null ? [var.user_assigned_identity_id] : null
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_storage_type

    # SECURITY: Customer-managed key encryption (optional)
    disk_encryption_set_id = var.disk_encryption_set_id
  }

  # Bootstrap configuration using cloud-init
  # Identical to custom VM configuration for consistency
  custom_data = base64encode(templatefile("${path.module}/${var.bootstrap}", local.bootstrap_vars))

  disable_password_authentication = false

  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics_storage_endpoint
  }

  lifecycle {
    ignore_changes = [custom_data]
  }

  tags = local.common_tags
}

# =============================================================================
# MANAGED DISKS
# =============================================================================

# Additional data disk for FortiGate logs and FortiAnalyzer storage
# Configurable size and storage type to match performance requirements
# Must be in the same availability zone as the VM (or regional if VM is regional)
resource "azurerm_managed_disk" "fgt_data_drive" {
  name                 = local.disk_data_name
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.data_disk_storage_type
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
  zone                 = var.zone # null for regional, "1"/"2"/"3" for zonal (must match VM)

  # SECURITY: Customer-managed key encryption for log data
  disk_encryption_set_id = var.disk_encryption_set_id

  tags = local.common_tags
}

# Attach data disk to FortiGate VM
# Works with both custom and marketplace VMs
# LUN 10 is a safe choice to avoid conflicts with OS disk (LUN 0)
# Caching mode is configurable based on workload requirements
resource "azurerm_virtual_machine_data_disk_attachment" "fgt_log_drive_attachment" {
  managed_disk_id    = azurerm_managed_disk.fgt_data_drive.id
  virtual_machine_id = local.vm_id
  lun                = 10
  caching            = var.data_disk_caching
}
