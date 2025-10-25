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
  name                              = "fgt-test-basic"
  computer_name                     = "fgt-basic"
  location                          = "eastus"
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
  client_secret                     = "test-secret-value"
  license_type                      = "payg"
  arch                              = "x86"
  fgtversion                        = "7.6.3"
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

  # Verify 4 network interfaces are created
  assert {
    condition     = azurerm_network_interface.port1.name == "fgt-basicport1"
    error_message = "Port1 NIC should be created"
  }

  assert {
    condition     = azurerm_network_interface.port2.name == "fgt-basicport2"
    error_message = "Port2 NIC should be created"
  }

  assert {
    condition     = azurerm_network_interface.port3.name == "fgt-basicport3"
    error_message = "Port3 NIC should be created"
  }

  assert {
    condition     = azurerm_network_interface.port4.name == "fgt-basicport4"
    error_message = "Port4 NIC should be created"
  }

  # Verify management public IP is created by default
  assert {
    condition     = length(azurerm_public_ip.mgmt_ip) == 1
    error_message = "Management public IP should be created by default"
  }

  # Verify NSGs are created
  assert {
    condition     = azurerm_network_security_group.publicnetworknsg.name == "fgt-basic-public"
    error_message = "Public NSG should be created"
  }

  assert {
    condition     = azurerm_network_security_group.privatenetworknsg.name == "fgt-basic-private"
    error_message = "Private NSG should be created"
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

run "verify_default_tags" {
  command = plan

  # Verify automatic tags are applied
  assert {
    condition     = azurerm_linux_virtual_machine.fgtvm[0].tags["ManagedBy"] == "Terraform"
    error_message = "ManagedBy tag should be set to Terraform"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.fgtvm[0].tags["Module"] == "terraform-azure-fortigate"
    error_message = "Module tag should be set"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.fgtvm[0].tags["FortiGateInstance"] == "fgt-basic"
    error_message = "FortiGateInstance tag should match computer_name"
  }
}

run "verify_outputs" {
  command = plan

  # Verify key outputs are present
  assert {
    condition     = output.fortigate_vm_name == "fgt-test-basic"
    error_message = "VM name output should match input"
  }

  assert {
    condition     = output.fortigate_computer_name == "fgt-basic"
    error_message = "Computer name output should match input"
  }

  # Note: Other output assertions removed because they depend on computed resource
  # attributes which are not known during `terraform plan`
}
