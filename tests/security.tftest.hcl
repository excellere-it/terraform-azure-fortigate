# =============================================================================
# SECURITY FEATURES TESTS
# =============================================================================
# Tests security features: Key Vault, NSG rules, private deployment
# =============================================================================

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

variables {
  name                              = "fgt-test-security"
  computer_name                     = "fgt-security"
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
  license_type                      = "payg"
}

run "verify_private_deployment" {
  command = plan

  variables {
    create_management_public_ip = false
    adminpassword               = "TestPassword123!"
    client_secret               = "test-secret"
  }

  # Verify no management public IP is created
  assert {
    condition     = length(azurerm_public_ip.mgmt_ip) == 0
    error_message = "Management public IP should not be created when disabled"
  }

  # Verify port1 NIC has no public IP
  assert {
    condition     = azurerm_network_interface.port1.ip_configuration[0].public_ip_address_id == null
    error_message = "Port1 should not have public IP when create_management_public_ip is false"
  }

  # Verify outputs are null
  assert {
    condition     = output.management_public_ip == null
    error_message = "Management public IP output should be null when disabled"
  }

  assert {
    condition     = output.fortigate_management_url == null
    error_message = "Management URL output should be null when public IP is disabled"
  }
}

run "verify_nsg_restrictions" {
  command = plan

  variables {
    enable_management_access_restriction = true
    management_access_cidrs              = ["203.0.113.0/24", "198.51.100.0/24"]
    management_ports                     = [8443, 22]
    adminpassword                        = "TestPassword123!"
    client_secret                        = "test-secret"
  }

  # Verify dynamic NSG rules are created (2 CIDRs × 2 ports = 4 rules)
  assert {
    condition     = length(azurerm_network_security_rule.management_access) == 4
    error_message = "Should create 4 dynamic NSG rules (2 CIDRs × 2 ports)"
  }

  # Verify unrestricted rule is NOT created
  assert {
    condition     = length(azurerm_network_security_rule.management_access_unrestricted) == 0
    error_message = "Unrestricted rule should not be created when management_access_cidrs is provided"
  }
}

run "verify_nsg_unrestricted_fallback" {
  command = plan

  variables {
    enable_management_access_restriction = false
    management_access_cidrs              = []
    adminpassword                        = "TestPassword123!"
    client_secret                        = "test-secret"
  }

  # Verify no dynamic rules created
  assert {
    condition     = length(azurerm_network_security_rule.management_access) == 0
    error_message = "No dynamic NSG rules should be created when restriction is disabled"
  }

  # Verify unrestricted fallback rule is created
  assert {
    condition     = length(azurerm_network_security_rule.management_access_unrestricted) == 1
    error_message = "Unrestricted fallback rule should be created when no CIDRs specified"
  }
}

# NOTE: Key Vault integration test commented out because it requires real Azure
# resources (Key Vault and secrets) to exist. This test cannot be run with mock
# data because Azure data sources are evaluated during plan phase.
#
# To test Key Vault integration manually:
# 1. Create an Azure Key Vault
# 2. Add secrets: fgt-admin-password and fgt-client-secret
# 3. Uncomment this test and update the key_vault_id to your real Key Vault ID
#
# run "verify_key_vault_integration" {
#   command = plan
#
#   variables {
#     key_vault_id               = "/subscriptions/YOUR-SUB-ID/resourceGroups/YOUR-RG/providers/Microsoft.KeyVault/vaults/YOUR-KV"
#     admin_password_secret_name = "fgt-admin-password"
#     client_secret_secret_name  = "fgt-client-secret"
#     adminpassword              = null
#     client_secret              = null
#   }
#
#   # Verify Key Vault data sources are created
#   assert {
#     condition     = length(data.azurerm_key_vault_secret.admin_password) == 1
#     error_message = "Admin password Key Vault data source should be created"
#   }
#
#   assert {
#     condition     = length(data.azurerm_key_vault_secret.client_secret) == 1
#     error_message = "Client secret Key Vault data source should be created"
#   }
#
#   # Verify data sources reference correct secrets
#   assert {
#     condition     = data.azurerm_key_vault_secret.admin_password[0].name == "fgt-admin-password"
#     error_message = "Admin password secret name should match configuration"
#   }
#
#   assert {
#     condition     = data.azurerm_key_vault_secret.client_secret[0].name == "fgt-client-secret"
#     error_message = "Client secret name should match configuration"
#   }
# }

run "verify_structured_tags" {
  command = plan

  variables {
    environment   = "Production"
    cost_center   = "IT-Security"
    owner         = "security-team@example.com"
    project       = "NetworkSecurity"
    adminpassword = "TestPassword123!"
    client_secret = "test-secret"
    tags = {
      Purpose    = "Testing"
      Compliance = "PCI-DSS"
    }
  }

  # Verify automatic tags
  assert {
    condition     = azurerm_linux_virtual_machine.fgtvm[0].tags["ManagedBy"] == "Terraform"
    error_message = "Automatic ManagedBy tag should be present"
  }

  # Verify structured tags
  assert {
    condition     = azurerm_linux_virtual_machine.fgtvm[0].tags["Environment"] == "Production"
    error_message = "Structured Environment tag should be applied"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.fgtvm[0].tags["CostCenter"] == "IT-Security"
    error_message = "Structured CostCenter tag should be applied"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.fgtvm[0].tags["Owner"] == "security-team@example.com"
    error_message = "Structured Owner tag should be applied"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.fgtvm[0].tags["Project"] == "NetworkSecurity"
    error_message = "Structured Project tag should be applied"
  }

  # Verify custom tags
  assert {
    condition     = azurerm_linux_virtual_machine.fgtvm[0].tags["Purpose"] == "Testing"
    error_message = "Custom Purpose tag should be applied"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.fgtvm[0].tags["Compliance"] == "PCI-DSS"
    error_message = "Custom Compliance tag should be applied"
  }
}
