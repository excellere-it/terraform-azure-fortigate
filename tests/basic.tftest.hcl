# =============================================================================
# BASIC CONFIGURATION TESTS
# =============================================================================
# Tests basic FortiGate deployment with minimal required configuration
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
  zone                              = "1"
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
  arch                              = "x86"
  fgtversion                        = "7.6.3"
  management_access_cidrs           = ["10.0.0.0/8"]
}

run "verify_basic_deployment" {
  command = plan

  # Verify VM is created with correct properties
  assert {
    condition     = length(azurerm_linux_virtual_machine.fgtvm) == 1
    error_message = "FortiGate VM should be created for marketplace deployment"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.fgtvm[0].size == "Standard_F8s_v2"
    error_message = "VM size should be Standard_F8s_v2"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.fgtvm[0].zone == "1"
    error_message = "VM should be in availability zone 1"
  }

  # Verify 4 network interfaces are created with terraform-namer naming
  assert {
    condition     = can(regex("^nic-.*-port1$", azurerm_network_interface.port1.name))
    error_message = "Port1 NIC should be created with terraform-namer naming pattern"
  }

  assert {
    condition     = can(regex("^nic-.*-port2$", azurerm_network_interface.port2.name))
    error_message = "Port2 NIC should be created with terraform-namer naming pattern"
  }

  assert {
    condition     = can(regex("^nic-.*-port3$", azurerm_network_interface.port3.name))
    error_message = "Port3 NIC should be created with terraform-namer naming pattern"
  }

  assert {
    condition     = can(regex("^nic-.*-port4$", azurerm_network_interface.port4.name))
    error_message = "Port4 NIC should be created with terraform-namer naming pattern"
  }

  # Verify management public IP is created by default
  assert {
    condition     = length(azurerm_public_ip.mgmt_ip) == 1
    error_message = "Management public IP should be created by default"
  }

  # Verify NSGs are created with terraform-namer naming
  assert {
    condition     = can(regex("^nsg-.*-public$", azurerm_network_security_group.publicnetworknsg.name))
    error_message = "Public NSG should use terraform-namer naming pattern"
  }

  assert {
    condition     = can(regex("^nsg-.*-private$", azurerm_network_security_group.privatenetworknsg.name))
    error_message = "Private NSG should use terraform-namer naming pattern"
  }

  # Verify data disk is created
  assert {
    condition     = azurerm_managed_disk.fgt_data_drive.disk_size_gb == 30
    error_message = "Data disk should be 30 GB by default"
  }

  assert {
    condition     = azurerm_managed_disk.fgt_data_drive.storage_account_type == "Standard_LRS"
    error_message = "Data disk should use Standard_LRS by default"
  }
}

run "verify_terraform_namer_outputs" {
  command = plan

  # Verify terraform-namer outputs are available
  assert {
    condition     = output.naming_suffix != null
    error_message = "naming_suffix output should be available"
  }

  assert {
    condition     = output.naming_suffix_short != null
    error_message = "naming_suffix_short output should be available"
  }

  assert {
    condition     = output.naming_suffix_vm != null
    error_message = "naming_suffix_vm output should be available"
  }

  assert {
    condition     = output.common_tags != null
    error_message = "common_tags output should be available"
  }
}

run "verify_outputs" {
  command = plan

  # Verify key outputs are present with terraform-namer patterns
  assert {
    condition     = can(regex("^vm-", output.fortigate_vm_name))
    error_message = "VM name output should use terraform-namer pattern (vm-*)"
  }

  assert {
    condition     = output.fortigate_computer_name != null && length(output.fortigate_computer_name) <= 15
    error_message = "Computer name output should be available and within 15 character limit"
  }

  assert {
    condition     = output.naming_suffix != null
    error_message = "naming_suffix output should be available"
  }

  # Note: Other output assertions removed because they depend on computed resource
  # attributes which are not known during `terraform plan`
}
