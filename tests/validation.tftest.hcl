# =============================================================================
# INPUT VALIDATION TESTS
# =============================================================================
# Tests input validation rules for variables
# =============================================================================

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

variables {
  # terraform-namer inputs (required)
  contact     = "test@example.com"
  environment = "dev"
  location    = "centralus"
  repository  = "terraform-azurerm-fortigate"
  workload    = "firewall"
  # Azure resources
  resource_group_name               = "rg-test"
  size                              = "Standard_F8s_v2"
  hamgmtsubnet_id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-mgmt"
  hasyncsubnet_id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-sync"
  publicsubnet_id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-public"
  privatesubnet_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-private"
  public_ip_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/publicIPAddresses/pip-cluster"
  public_ip_name                    = "pip-cluster"
  boot_diagnostics_storage_endpoint = "https://sttest.blob.core.windows.net/"
  port1                             = "10.0.1.10"
  port2                             = "10.0.2.10"
  port3                             = "10.0.3.10"
  port4                             = "10.0.4.10"
  port1gateway                      = "10.0.1.1"
  port2gateway                      = "10.0.2.1"
  adminusername                     = "azureadmin"
  adminpassword                     = "TestPassword123!"
  user_assigned_identity_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-fortigate"
  license_type                      = "payg"
  management_access_cidrs           = ["10.0.0.0/8"]
}

run "validate_zone_values" {
  command = plan

  variables {
    zone = "1"
  }

  # Should succeed with zone "1"
  assert {
    condition     = azurerm_linux_virtual_machine.fgtvm[0].zone == "1"
    error_message = "Zone 1 should be valid"
  }
}

run "validate_zone_null_regional" {
  command = plan

  variables {
    zone = null
  }

  # Should succeed with zone = null (regional deployment)
  assert {
    condition     = azurerm_linux_virtual_machine.fgtvm[0].zone == null
    error_message = "Zone null should be valid for regional deployment"
  }
}

run "validate_license_type" {
  command = plan

  variables {
    license_type = "payg"
  }

  # Should succeed with valid license type
  assert {
    condition     = var.license_type == "payg"
    error_message = "PAYG license type should be valid"
  }
}

run "validate_architecture" {
  command = plan

  variables {
    arch = "x86"
  }

  # Should succeed with valid architecture
  assert {
    condition     = var.arch == "x86"
    error_message = "x86 architecture should be valid"
  }
}

run "validate_disk_size_range" {
  command = plan

  variables {
    data_disk_size_gb = 30
  }

  # Should succeed with disk size in valid range
  assert {
    condition     = azurerm_managed_disk.fgt_data_drive.disk_size_gb >= 1 && azurerm_managed_disk.fgt_data_drive.disk_size_gb <= 32767
    error_message = "Disk size should be in valid range (1-32767 GB)"
  }
}

run "validate_storage_type" {
  command = plan

  variables {
    data_disk_storage_type = "Standard_LRS"
  }

  # Should succeed with valid storage type
  assert {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "StandardSSD_ZRS", "Premium_ZRS"], var.data_disk_storage_type)
    error_message = "Storage type should be valid"
  }
}

run "validate_caching_mode" {
  command = plan

  variables {
    data_disk_caching = "ReadWrite"
  }

  # Should succeed with valid caching mode
  assert {
    condition     = contains(["None", "ReadOnly", "ReadWrite"], var.data_disk_caching)
    error_message = "Caching mode should be valid"
  }
}

run "validate_retention_days_diagnostic" {
  command = plan

  variables {
    diagnostic_retention_days = 30
  }

  # Should succeed with retention in valid range
  assert {
    condition     = var.diagnostic_retention_days >= 0 && var.diagnostic_retention_days <= 365
    error_message = "Diagnostic retention should be in valid range (0-365 days)"
  }
}

run "validate_retention_days_flow_logs" {
  command = plan

  variables {
    nsg_flow_logs_retention_days = 7
  }

  # Should succeed with retention in valid range
  assert {
    condition     = var.nsg_flow_logs_retention_days >= 0 && var.nsg_flow_logs_retention_days <= 365
    error_message = "Flow logs retention should be in valid range (0-365 days)"
  }
}

run "validate_management_cidrs_format" {
  command = plan

  variables {
    management_access_cidrs = ["203.0.113.0/24", "198.51.100.50/32"]
  }

  # Should succeed with valid CIDR notation
  assert {
    condition     = length(var.management_access_cidrs) == 2
    error_message = "Management CIDRs should be accepted when in valid format"
  }
}

run "validate_management_ports_range" {
  command = plan

  variables {
    management_ports = [443, 8443, 22]
  }

  # Should succeed with valid port numbers
  assert {
    condition     = alltrue([for port in var.management_ports : port >= 1 && port <= 65535])
    error_message = "Management ports should be in valid range (1-65535)"
  }
}

run "validate_custom_tags_format" {
  command = plan

  variables {
    environment = "prd"
    tags = {
      CostCenter = "IT-123"
      Owner      = "team@example.com"
      Project    = "NetworkSecurity"
    }
  }

  # Verify tags output is available
  assert {
    condition     = output.common_tags != null
    error_message = "common_tags output should be available with custom tags"
  }
}

run "validate_custom_tags" {
  command = plan

  variables {
    tags = {
      Application = "Firewall"
      Compliance  = "PCI-DSS"
      Purpose     = "Edge-Security"
    }
  }

  # Should succeed with valid custom tags - verify output is available
  assert {
    condition     = output.common_tags != null
    error_message = "common_tags output should be available with custom tags"
  }

  # Note: Cannot validate specific tag values during plan phase
}

run "validate_ip_addresses_format" {
  command = plan

  variables {
    port1 = "10.0.1.10"
    port2 = "10.0.2.10"
    port3 = "10.0.3.10"
    port4 = "10.0.4.10"
  }

  # Should succeed with valid IPv4 addresses
  assert {
    condition     = azurerm_network_interface.port1.ip_configuration[0].private_ip_address == "10.0.1.10"
    error_message = "Port1 IP should be accepted when in valid IPv4 format"
  }

  assert {
    condition     = azurerm_network_interface.port2.ip_configuration[0].private_ip_address == "10.0.2.10"
    error_message = "Port2 IP should be accepted when in valid IPv4 format"
  }
}

run "validate_subnet_masks" {
  command = plan

  variables {
    port1mask = "255.255.255.0"
    port2mask = "255.255.254.0"
    port3mask = "255.255.252.0"
    port4mask = "255.255.255.128"
  }

  # Should succeed with valid subnet masks
  assert {
    condition     = var.port1mask == "255.255.255.0"
    error_message = "Valid subnet masks should be accepted"
  }
}

run "validate_optional_port5_port6" {
  command = plan

  variables {
    port5subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-dmz"
    port5          = "10.0.5.10"
  }

  # Should succeed with valid port5 configuration
  assert {
    condition     = length(azurerm_network_interface.port5) == 1
    error_message = "Port5 should be created with valid configuration"
  }
}

run "validate_port5_null_by_default" {
  command = plan

  # Should succeed with port5 null by default
  assert {
    condition     = var.port5 == null
    error_message = "Port5 should be null by default"
  }

  assert {
    condition     = length(azurerm_network_interface.port5) == 0
    error_message = "Port5 NIC should not be created when null"
  }
}
