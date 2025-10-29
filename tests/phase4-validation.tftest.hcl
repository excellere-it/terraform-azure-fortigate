# =============================================================================
# Phase 4 Validation Tests
# =============================================================================
# Tests for Phase 4 features: DDoS Protection, validation enhancements
# =============================================================================

# Test: DDoS Protection Plan validation (valid format)
run "test_ddos_protection_valid_format" {
  command = plan

  variables {
    contact     = "test@example.com"
    environment = "dev"
    location    = "centralus"
    repository  = "terraform-azurerm-fortigate"
    workload    = "firewall"

    resource_group_name                  = "rg-test"
    hamgmtsubnet_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-mgmt"
    hasyncsubnet_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-sync"
    publicsubnet_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-public"
    privatesubnet_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-private"
    public_ip_id                         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/publicIPAddresses/pip-test"
    public_ip_name                       = "pip-test"
    port1                                = "10.0.1.10"
    port2                                = "10.0.2.10"
    port3                                = "10.0.3.10"
    port4                                = "10.0.4.10"
    port1mask                            = "255.255.255.0"
    port2mask                            = "255.255.255.0"
    port3mask                            = "255.255.255.0"
    port4mask                            = "255.255.255.0"
    port1gateway                         = "10.0.1.1"
    port2gateway                         = "10.0.2.1"
    adminusername                        = "azureadmin"
    adminpassword                        = "TestP@ssw0rd123!Secure"
    boot_diagnostics_storage_endpoint    = "https://sttest.blob.core.windows.net/"
    enable_management_access_restriction = true
    management_access_cidrs              = ["203.0.113.0/24"]

    # DDoS Protection Plan (valid format)
    ddos_protection_plan_id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-ddos/providers/Microsoft.Network/ddosProtectionPlans/ddos-plan-prod"
  }

  assert {
    condition     = var.ddos_protection_plan_id != null
    error_message = "DDoS Protection Plan ID should be set"
  }
}

# Test: DDoS Protection Plan validation (null is valid)
run "test_ddos_protection_null_valid" {
  command = plan

  variables {
    contact     = "test@example.com"
    environment = "dev"
    location    = "centralus"
    repository  = "terraform-azurerm-fortigate"
    workload    = "firewall"

    resource_group_name                  = "rg-test"
    hamgmtsubnet_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-mgmt"
    hasyncsubnet_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-sync"
    publicsubnet_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-public"
    privatesubnet_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-private"
    public_ip_id                         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/publicIPAddresses/pip-test"
    public_ip_name                       = "pip-test"
    port1                                = "10.0.1.10"
    port2                                = "10.0.2.10"
    port3                                = "10.0.3.10"
    port4                                = "10.0.4.10"
    port1mask                            = "255.255.255.0"
    port2mask                            = "255.255.255.0"
    port3mask                            = "255.255.255.0"
    port4mask                            = "255.255.255.0"
    port1gateway                         = "10.0.1.1"
    port2gateway                         = "10.0.2.1"
    adminusername                        = "azureadmin"
    adminpassword                        = "TestP@ssw0rd123!Secure"
    boot_diagnostics_storage_endpoint    = "https://sttest.blob.core.windows.net/"
    enable_management_access_restriction = true
    management_access_cidrs              = ["203.0.113.0/24"]

    # DDoS Protection Plan (null is valid - uses basic protection)
    ddos_protection_plan_id = null
  }

  assert {
    condition     = var.ddos_protection_plan_id == null
    error_message = "DDoS Protection Plan ID should be null (basic protection)"
  }
}

# Test: DDoS Protection Plan validation (invalid format)
run "test_ddos_protection_invalid_format" {
  command = plan

  variables {
    contact     = "test@example.com"
    environment = "dev"
    location    = "centralus"
    repository  = "terraform-azurerm-fortigate"
    workload    = "firewall"

    resource_group_name                  = "rg-test"
    hamgmtsubnet_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-mgmt"
    hasyncsubnet_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-sync"
    publicsubnet_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-public"
    privatesubnet_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-private"
    public_ip_id                         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/publicIPAddresses/pip-test"
    public_ip_name                       = "pip-test"
    port1                                = "10.0.1.10"
    port2                                = "10.0.2.10"
    port3                                = "10.0.3.10"
    port4                                = "10.0.4.10"
    port1mask                            = "255.255.255.0"
    port2mask                            = "255.255.255.0"
    port3mask                            = "255.255.255.0"
    port4mask                            = "255.255.255.0"
    port1gateway                         = "10.0.1.1"
    port2gateway                         = "10.0.2.1"
    adminusername                        = "azureadmin"
    adminpassword                        = "TestP@ssw0rd123!Secure"
    boot_diagnostics_storage_endpoint    = "https://sttest.blob.core.windows.net/"
    enable_management_access_restriction = true
    management_access_cidrs              = ["203.0.113.0/24"]

    # DDoS Protection Plan (invalid format - not a full resource ID)
    ddos_protection_plan_id = "invalid-ddos-plan-id"
  }

  expect_failures = [
    var.ddos_protection_plan_id,
  ]
}

# Test: Boot diagnostics HTTPS validation (valid)
run "test_boot_diagnostics_https_valid" {
  command = plan

  variables {
    contact     = "test@example.com"
    environment = "dev"
    location    = "centralus"
    repository  = "terraform-azurerm-fortigate"
    workload    = "firewall"

    resource_group_name                  = "rg-test"
    hamgmtsubnet_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-mgmt"
    hasyncsubnet_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-sync"
    publicsubnet_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-public"
    privatesubnet_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-private"
    public_ip_id                         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/publicIPAddresses/pip-test"
    public_ip_name                       = "pip-test"
    port1                                = "10.0.1.10"
    port2                                = "10.0.2.10"
    port3                                = "10.0.3.10"
    port4                                = "10.0.4.10"
    port1mask                            = "255.255.255.0"
    port2mask                            = "255.255.255.0"
    port3mask                            = "255.255.255.0"
    port4mask                            = "255.255.255.0"
    port1gateway                         = "10.0.1.1"
    port2gateway                         = "10.0.2.1"
    adminusername                        = "azureadmin"
    adminpassword                        = "TestP@ssw0rd123!Secure"
    boot_diagnostics_storage_endpoint    = "https://stsecure.blob.core.windows.net/"
    enable_management_access_restriction = true
    management_access_cidrs              = ["203.0.113.0/24"]
  }

  assert {
    condition     = can(regex("^https://", var.boot_diagnostics_storage_endpoint))
    error_message = "Boot diagnostics should use HTTPS"
  }
}

# Test: Boot diagnostics HTTPS validation (HTTP should fail)
run "test_boot_diagnostics_http_invalid" {
  command = plan

  variables {
    contact     = "test@example.com"
    environment = "dev"
    location    = "centralus"
    repository  = "terraform-azurerm-fortigate"
    workload    = "firewall"

    resource_group_name                  = "rg-test"
    hamgmtsubnet_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-mgmt"
    hasyncsubnet_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-sync"
    publicsubnet_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-public"
    privatesubnet_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-private"
    public_ip_id                         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/publicIPAddresses/pip-test"
    public_ip_name                       = "pip-test"
    port1                                = "10.0.1.10"
    port2                                = "10.0.2.10"
    port3                                = "10.0.3.10"
    port4                                = "10.0.4.10"
    port1mask                            = "255.255.255.0"
    port2mask                            = "255.255.255.0"
    port3mask                            = "255.255.255.0"
    port4mask                            = "255.255.255.0"
    port1gateway                         = "10.0.1.1"
    port2gateway                         = "10.0.2.1"
    adminusername                        = "azureadmin"
    adminpassword                        = "TestP@ssw0rd123!Secure"
    boot_diagnostics_storage_endpoint    = "http://stinsecure.blob.core.windows.net/" # HTTP not HTTPS
    enable_management_access_restriction = true
    management_access_cidrs              = ["203.0.113.0/24"]
  }

  expect_failures = [
    var.boot_diagnostics_storage_endpoint,
  ]
}
