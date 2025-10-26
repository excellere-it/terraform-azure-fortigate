# Terraform Azure FortiGate Module - Implementation Plan

## Executive Summary

This document outlines a detailed implementation plan for enhancing the Terraform Azure FortiGate module. The improvements are organized into 5 phases over approximately 4-6 weeks, with each phase building on the previous one while maintaining backward compatibility.

**Total Estimated Timeline:** 4-6 weeks
**Team Size:** 1-2 developers
**Risk Level:** Low (all changes are backward compatible)

---

## Table of Contents

1. [Phase 0: Pre-Implementation Setup](#phase-0-pre-implementation-setup)
2. [Phase 1: Quick Wins & Foundation](#phase-1-quick-wins--foundation)
3. [Phase 2: Security Enhancements](#phase-2-security-enhancements)
4. [Phase 3: Flexibility Features](#phase-3-flexibility-features)
5. [Phase 4: Observability & Monitoring](#phase-4-observability--monitoring)
6. [Phase 5: Advanced Features (Optional)](#phase-5-advanced-features-optional)
7. [Testing Strategy](#testing-strategy)
8. [Rollback Procedures](#rollback-procedures)
9. [Success Metrics](#success-metrics)
10. [Appendices](#appendices)

---

## Phase 0: Pre-Implementation Setup

**Duration:** 3-5 days
**Team:** 1 developer
**Risk:** Very Low

### Objectives
- Set up development environment
- Create feature branch structure
- Establish testing framework
- Document current state

### Tasks

#### Task 0.1: Environment Setup (1 day)
```bash
# Clone repository
git clone <repository-url>
cd terraform-azurerm-fortigate

# Create feature branch
git checkout -b feature/module-enhancements

# Set up development tools
make init
terraform init
```

**Acceptance Criteria:**
- [ ] Development environment configured
- [ ] All tests passing with current code
- [ ] Documentation reviewed and understood

#### Task 0.2: Baseline Testing (1 day)
```bash
# Run existing tests
make test

# Validate current configuration
make validate

# Document current test results
terraform plan -out=baseline.tfplan
```

**Deliverables:**
- Baseline test results document
- Current configuration snapshot
- Test coverage report

#### Task 0.3: Create Testing Infrastructure (1-2 days)

**File:** `test/integration_test.go`
```go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestPhase1Enhancements(t *testing.T) {
    // Test conditional lifecycle
    // Test input validation
    // Test enhanced tagging
}

func TestPhase2SecurityEnhancements(t *testing.T) {
    // Test configurable NSG rules
    // Test Key Vault integration
}

// Additional test functions...
```

**Acceptance Criteria:**
- [ ] Integration test framework created
- [ ] Baseline tests documented
- [ ] CI/CD pipeline validated

#### Task 0.4: Documentation Preparation (1 day)

Create tracking documents:
- `UPGRADE_GUIDE.md` - For users upgrading from current version
- `BREAKING_CHANGES.md` - Track any breaking changes (should be none)
- `FEATURE_FLAGS.md` - Document new feature flags

**Acceptance Criteria:**
- [ ] Documentation templates created
- [ ] Change tracking system in place
- [ ] Stakeholders informed of upcoming changes

---

## Phase 1: Quick Wins & Foundation

**Duration:** 1 week
**Team:** 1 developer
**Risk:** Very Low
**Backward Compatibility:** ✅ 100%

### Objectives
- Implement low-risk, high-value improvements
- Establish patterns for future enhancements
- Improve developer experience

### Tasks

#### Task 1.1: Conditional Lifecycle Management (1 day)

**Priority:** HIGH
**Files Modified:** `variables.tf`, `locals.tf`, `network.tf`, `compute.tf`

**Implementation Steps:**

1. **Update variables.tf** (15 min)
```hcl
variable "enable_deletion_protection" {
  description = "Enable deletion protection on all resources. Set false for dev/test environments"
  type        = bool
  default     = true
}
```

2. **Update locals.tf** (15 min)
```hcl
locals {
  # Conditional lifecycle rule
  lifecycle_prevent_destroy = var.enable_deletion_protection ? {
    prevent_destroy = true
  } : {}
}
```

3. **Update all resources** (4 hours)
   - Replace hardcoded `prevent_destroy = true` in all resources
   - Use dynamic lifecycle blocks
   - Test with both true/false values

**Example Pattern:**
```hcl
resource "azurerm_public_ip" "mgmt_ip" {
  name                = "${var.computer_name}mgmtip"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = var.tags

  dynamic "lifecycle" {
    for_each = var.enable_deletion_protection ? [1] : []
    content {
      prevent_destroy = true
    }
  }
}
```

**Testing:**
```bash
# Test with protection enabled (default)
terraform plan

# Test with protection disabled
terraform plan -var="enable_deletion_protection=false"

# Verify destroy works without protection
terraform destroy -var="enable_deletion_protection=false"
```

**Acceptance Criteria:**
- [ ] All resources support conditional deletion protection
- [ ] Default behavior unchanged (protection enabled)
- [ ] Tests pass with both enabled and disabled
- [ ] Documentation updated

---

#### Task 1.2: Enhanced Input Validation (1 day)

**Priority:** HIGH
**Files Modified:** `variables.tf`

**Implementation Steps:**

1. **Add validation to critical variables** (4 hours)

```hcl
# VM Size validation
variable "size" {
  description = "Azure VM size for FortiGate"
  type        = string
  default     = "Standard_F8s_v2"

  validation {
    condition     = can(regex("^Standard_[A-Z][0-9]+[a-z]*_v[0-9]+$", var.size))
    error_message = "VM size must be a valid Azure Standard SKU (e.g., Standard_F8s_v2)."
  }
}

# Zone validation
variable "zone" {
  description = "Azure availability zone (1, 2, 3, or null for non-zonal)"
  type        = string
  default     = "1"

  validation {
    condition     = var.zone == null || contains(["1", "2", "3"], var.zone)
    error_message = "Zone must be 1, 2, 3, or null."
  }
}

# Computer name validation
variable "computer_name" {
  description = "Computer/hostname for FortiGate VM (1-15 chars, lowercase alphanumeric)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{1,15}$", var.computer_name))
    error_message = "Computer name must be 1-15 characters, lowercase letters, numbers, and hyphens only."
  }
}

# IP address validation for all ports
variable "port1" {
  description = "Static private IP address for port1"
  type        = string
  default     = "172.1.3.10"

  validation {
    condition     = can(cidrhost("${var.port1}/32", 0))
    error_message = "Port1 must be a valid IPv4 address."
  }
}

# Repeat for port2, port3, port4

# License type validation
variable "license_type" {
  description = "FortiGate license type: 'byol' or 'payg'"
  type        = string
  default     = "payg"

  validation {
    condition     = contains(["byol", "payg"], var.license_type)
    error_message = "License type must be either 'byol' or 'payg'."
  }
}

# Architecture validation
variable "arch" {
  description = "FortiGate VM architecture: 'x86' or 'arm'"
  type        = string
  default     = "x86"

  validation {
    condition     = contains(["x86", "arm"], var.arch)
    error_message = "Architecture must be either 'x86' or 'arm'."
  }
}

# Disk size validation
variable "data_disk_size_gb" {
  description = "Size of data disk in GB (30-32767)"
  type        = number
  default     = 30

  validation {
    condition     = var.data_disk_size_gb >= 30 && var.data_disk_size_gb <= 32767
    error_message = "Data disk size must be between 30 GB and 32767 GB."
  }
}
```

2. **Create validation test cases** (2 hours)

**File:** `test/validation_test.go`
```go
func TestInputValidation(t *testing.T) {
    tests := []struct {
        name      string
        varName   string
        value     interface{}
        shouldFail bool
    }{
        {"Valid VM Size", "size", "Standard_F8s_v2", false},
        {"Invalid VM Size", "size", "InvalidSize", true},
        {"Valid Zone", "zone", "1", false},
        {"Invalid Zone", "zone", "4", true},
        {"Valid Computer Name", "computer_name", "fgt-test", false},
        {"Invalid Computer Name", "computer_name", "FGT_TEST_TOOLONG", true},
        {"Valid IP", "port1", "10.0.1.10", false},
        {"Invalid IP", "port1", "999.999.999.999", true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // Test validation logic
        })
    }
}
```

**Testing:**
```bash
# Test valid inputs
terraform plan -var="size=Standard_F8s_v2"

# Test invalid inputs (should fail)
terraform plan -var="size=InvalidSize" # Should show validation error
terraform plan -var="zone=4"           # Should show validation error
terraform plan -var="computer_name=TOOLONG123456789" # Should fail
```

**Acceptance Criteria:**
- [ ] All critical variables have validation
- [ ] Validation error messages are clear and helpful
- [ ] Tests confirm validation works correctly
- [ ] Documentation updated with validation rules

---

#### Task 1.3: Enhanced Tagging Strategy (1 day)

**Priority:** MEDIUM
**Files Modified:** `variables.tf`, `locals.tf`

**Implementation Steps:**

1. **Add tagging variables** (1 hour)

```hcl
# variables.tf
variable "default_tags" {
  description = "Default tags applied to all resources"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Module      = "terraform-azurerm-fortigate"
    Environment = "production"
  }
}

variable "additional_tags" {
  description = "Additional tags to merge with default tags"
  type        = map(string)
  default     = {}
}

variable "enable_timestamp_tag" {
  description = "Add deployment timestamp to tags"
  type        = bool
  default     = true
}
```

2. **Update locals.tf** (1 hour)

```hcl
locals {
  # Merge all tags
  base_tags = merge(
    var.default_tags,
    var.additional_tags,
    var.tags # User-provided tags take precedence
  )

  # Add computed tags
  computed_tags = var.enable_timestamp_tag ? {
    DeployedAt = timestamp()
    VMSize     = var.size
    Location   = var.location
    LicenseType = var.license_type
  } : {}

  # Final tags
  common_tags = merge(local.base_tags, local.computed_tags)
}
```

3. **Update all resources** (2 hours)
   - Replace `var.tags` with `local.common_tags`
   - Ensure consistent tagging across all resources

4. **Add output for tags** (30 min)

```hcl
# outputs.tf
output "applied_tags" {
  description = "Tags applied to all resources"
  value       = local.common_tags
}
```

**Testing:**
```bash
# Test default tags
terraform plan

# Test with additional tags
terraform plan -var='additional_tags={"CostCenter"="Engineering"}'

# Verify tags in output
terraform output applied_tags
```

**Acceptance Criteria:**
- [ ] Consistent tagging across all resources
- [ ] Tags are customizable and mergeable
- [ ] Timestamp tags are optional
- [ ] Documentation includes tagging examples

---

#### Task 1.4: Configurable Disk Settings (0.5 day)

**Priority:** MEDIUM
**Files Modified:** `variables.tf`, `compute.tf`

**Implementation Steps:**

1. **Add disk configuration variables** (30 min)

```hcl
# variables.tf
variable "data_disk_size_gb" {
  description = "Size of the data disk for FortiGate logs in GB"
  type        = number
  default     = 30

  validation {
    condition     = var.data_disk_size_gb >= 30 && var.data_disk_size_gb <= 32767
    error_message = "Data disk size must be between 30 GB and 32767 GB."
  }
}

variable "data_disk_type" {
  description = "Storage account type for data disk"
  type        = string
  default     = "Standard_LRS"

  validation {
    condition     = contains(["Standard_LRS", "Premium_LRS", "StandardSSD_LRS", "UltraSSD_LRS"], var.data_disk_type)
    error_message = "Invalid storage account type. Must be Standard_LRS, Premium_LRS, StandardSSD_LRS, or UltraSSD_LRS."
  }
}

variable "data_disk_caching" {
  description = "Caching mode for data disk"
  type        = string
  default     = "ReadWrite"

  validation {
    condition     = contains(["None", "ReadOnly", "ReadWrite"], var.data_disk_caching)
    error_message = "Caching must be None, ReadOnly, or ReadWrite."
  }
}

variable "enable_data_disk" {
  description = "Create and attach data disk for FortiGate logs"
  type        = bool
  default     = true
}
```

2. **Update compute.tf** (1 hour)

```hcl
resource "azurerm_managed_disk" "fgt_data_drive" {
  count                = var.enable_data_disk ? 1 : 0
  name                 = "${var.computer_name}datadisk"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.data_disk_type
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
  zone                 = var.zone
  tags                 = local.common_tags

  dynamic "lifecycle" {
    for_each = var.enable_deletion_protection ? [1] : []
    content {
      prevent_destroy = true
    }
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "fgt_log_drive_attachment" {
  count              = var.enable_data_disk ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.fgt_data_drive[0].id
  virtual_machine_id = local.vm_id
  lun                = 10
  caching            = var.data_disk_caching

  dynamic "lifecycle" {
    for_each = var.enable_deletion_protection ? [1] : []
    content {
      prevent_destroy = true
    }
  }
}
```

3. **Update outputs** (15 min)

```hcl
output "data_disk_id" {
  description = "Azure resource ID of the FortiGate data disk"
  value       = var.enable_data_disk ? azurerm_managed_disk.fgt_data_drive[0].id : null
}

output "data_disk_configuration" {
  description = "Data disk configuration details"
  value = var.enable_data_disk ? {
    size_gb = var.data_disk_size_gb
    type    = var.data_disk_type
    caching = var.data_disk_caching
  } : null
}
```

**Testing:**
```bash
# Test with default disk
terraform plan

# Test with custom disk size
terraform plan -var="data_disk_size_gb=50"

# Test with Premium disk
terraform plan -var="data_disk_type=Premium_LRS"

# Test without data disk
terraform plan -var="enable_data_disk=false"
```

**Acceptance Criteria:**
- [ ] Disk size is configurable
- [ ] Disk type is configurable
- [ ] Disk can be optionally disabled
- [ ] Validation prevents invalid configurations

---

### Phase 1 Deliverables

**Code Changes:**
- [ ] Conditional lifecycle management implemented
- [ ] Enhanced input validation added
- [ ] Improved tagging strategy implemented
- [ ] Configurable disk settings added

**Documentation:**
- [ ] CHANGELOG.md updated
- [ ] README.md updated with new variables
- [ ] Examples updated
- [ ] Variable reference documentation complete

**Testing:**
- [ ] All unit tests passing
- [ ] Integration tests passing
- [ ] Validation tests added and passing
- [ ] Backward compatibility verified

---

## Phase 2: Security Enhancements

**Duration:** 1.5 weeks
**Team:** 1-2 developers
**Risk:** Low
**Backward Compatibility:** ✅ 100%

### Objectives
- Implement configurable NSG rules
- Add Azure Key Vault integration
- Enhance security posture
- Maintain backward compatibility

### Tasks

#### Task 2.1: Configurable NSG Rules (3 days)

**Priority:** HIGH
**Files Modified:** `variables.tf`, `locals.tf`, `network.tf`

**Implementation Steps:**

**Day 1: Add Variables and Planning** (8 hours)

1. **Add management access variables** (2 hours)

```hcl
# variables.tf
variable "enable_restrictive_mgmt_rules" {
  description = "Use restrictive management rules instead of allow-all. Recommended for production"
  type        = bool
  default     = false
}

variable "management_source_ips" {
  description = "List of source IP addresses/CIDR blocks allowed to access management interface"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for ip in var.management_source_ips : can(cidrhost(ip, 0))])
    error_message = "All management source IPs must be valid CIDR blocks or IP addresses."
  }
}

variable "management_allowed_ports" {
  description = "List of TCP ports allowed for management access"
  type        = list(number)
  default     = [443, 8443, 22]

  validation {
    condition     = alltrue([for port in var.management_allowed_ports : port > 0 && port < 65536])
    error_message = "All ports must be between 1 and 65535."
  }
}

variable "custom_nsg_rules" {
  description = "Custom NSG rules to add to public NSG"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = []

  validation {
    condition     = alltrue([for rule in var.custom_nsg_rules : rule.priority >= 100 && rule.priority <= 4096])
    error_message = "NSG rule priorities must be between 100 and 4096."
  }
}
```

2. **Design NSG rule structure** (2 hours)

Create document: `docs/NSG_DESIGN.md`
```markdown
# NSG Rule Design

## Default Behavior (Backward Compatible)
- When `enable_restrictive_mgmt_rules = false` (default)
- Creates single allow-all rule (existing behavior)
- No breaking changes

## Restrictive Mode (New, Opt-in)
- When `enable_restrictive_mgmt_rules = true`
- Creates specific rules for each management port
- Restricts source IPs to allowed list

## Rule Priority Scheme
- 1000-1999: Management rules (HTTP/HTTPS/SSH)
- 2000-2999: Custom rules
- 3000-3999: HA/Sync rules
- 4000+: Deny rules (if needed)
```

3. **Create locals for rules** (2 hours)

```hcl
# locals.tf
locals {
  # Generate management rules if restrictive mode enabled
  management_rules = var.enable_restrictive_mgmt_rules ? [
    for idx, port in var.management_allowed_ports : {
      name                       = "Allow-Mgmt-${port}"
      priority                   = 1000 + idx
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = tostring(port)
      source_address_prefixes    = var.management_source_ips
      destination_address_prefix = "*"
    }
  ] : []

  # Legacy allow-all rule for backward compatibility
  legacy_allow_all_rule = var.enable_restrictive_mgmt_rules ? [] : [{
    name                       = "HttpsMgmt"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }]

  # Combine all rules
  all_public_inbound_rules = concat(
    local.management_rules,
    local.legacy_allow_all_rule,
    var.custom_nsg_rules
  )
}
```

4. **Create test plan** (2 hours)

**File:** `test/nsg_test_plan.md`
```markdown
# NSG Rule Testing Plan

## Test Cases

### TC-1: Default Behavior (Backward Compatible)
- Input: `enable_restrictive_mgmt_rules = false`
- Expected: Single allow-all rule created
- Verify: No breaking changes

### TC-2: Restrictive Mode - Single Port
- Input: `enable_restrictive_mgmt_rules = true`, `management_allowed_ports = [443]`
- Expected: One rule allowing port 443
- Verify: Other ports blocked

### TC-3: Restrictive Mode - Multiple Ports
- Input: `management_allowed_ports = [443, 8443, 22]`
- Expected: Three rules, one per port
- Verify: All ports accessible

### TC-4: Source IP Restriction
- Input: `management_source_ips = ["10.0.0.0/8", "192.168.1.100/32"]`
- Expected: Rules with multiple source prefixes
- Verify: Access only from specified IPs

### TC-5: Custom Rules
- Input: Custom rule with priority 2000
- Expected: Custom rule created alongside management rules
- Verify: No priority conflicts
```

**Day 2: Implement NSG Rules** (8 hours)

1. **Update network.tf** (4 hours)

```hcl
# network.tf

# Legacy allow-all rule (backward compatible)
resource "azurerm_network_security_rule" "incoming_public_legacy" {
  count                       = var.enable_restrictive_mgmt_rules ? 0 : 1
  name                        = "HttpsMgmt"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.publicnetworknsg.name

  dynamic "lifecycle" {
    for_each = var.enable_deletion_protection ? [1] : []
    content {
      prevent_destroy = true
    }
  }
}

# Restrictive management rules (new, opt-in)
resource "azurerm_network_security_rule" "management_access" {
  count                       = var.enable_restrictive_mgmt_rules ? length(var.management_allowed_ports) : 0
  name                        = "Allow-Mgmt-${var.management_allowed_ports[count.index]}"
  priority                    = 1000 + count.index
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = tostring(var.management_allowed_ports[count.index])
  source_address_prefixes     = var.management_source_ips
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.publicnetworknsg.name

  dynamic "lifecycle" {
    for_each = var.enable_deletion_protection ? [1] : []
    content {
      prevent_destroy = true
    }
  }
}

# Custom NSG rules
resource "azurerm_network_security_rule" "custom_rules" {
  count                       = length(var.custom_nsg_rules)
  name                        = var.custom_nsg_rules[count.index].name
  priority                    = var.custom_nsg_rules[count.index].priority
  direction                   = var.custom_nsg_rules[count.index].direction
  access                      = var.custom_nsg_rules[count.index].access
  protocol                    = var.custom_nsg_rules[count.index].protocol
  source_port_range           = var.custom_nsg_rules[count.index].source_port_range
  destination_port_range      = var.custom_nsg_rules[count.index].destination_port_range
  source_address_prefix       = var.custom_nsg_rules[count.index].source_address_prefix
  destination_address_prefix  = var.custom_nsg_rules[count.index].destination_address_prefix
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.publicnetworknsg.name

  dynamic "lifecycle" {
    for_each = var.enable_deletion_protection ? [1] : []
    content {
      prevent_destroy = true
    }
  }
}
```

2. **Add NSG outputs** (1 hour)

```hcl
# outputs.tf
output "nsg_rules_summary" {
  description = "Summary of NSG rules created"
  value = {
    public_nsg = {
      restrictive_mode = var.enable_restrictive_mgmt_rules
      management_ports = var.enable_restrictive_mgmt_rules ? var.management_allowed_ports : ["all"]
      source_ips       = var.enable_restrictive_mgmt_rules ? var.management_source_ips : ["0.0.0.0/0"]
      custom_rules_count = length(var.custom_nsg_rules)
    }
  }
}

output "management_access_urls" {
  description = "Management access URLs with allowed ports"
  value = [
    for port in (var.enable_restrictive_mgmt_rules ? var.management_allowed_ports : [443, 8443]) :
    "https://${azurerm_public_ip.mgmt_ip.ip_address}:${port}"
  ]
}
```

3. **Create examples** (2 hours)

**File:** `examples/restrictive-nsg/main.tf`
```hcl
module "fortigate_secure" {
  source = "../.."

  # ... other config ...

  # Enable restrictive management rules
  enable_restrictive_mgmt_rules = true

  # Allow only specific management IPs
  management_source_ips = [
    "10.0.0.0/8",           # Internal network
    "203.0.113.10/32"      # Admin workstation
  ]

  # Allow only specific ports
  management_allowed_ports = [443, 8443]

  # Add custom rule for monitoring
  custom_nsg_rules = [
    {
      name                       = "Allow-Monitoring"
      priority                   = 2000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "10050"
      source_address_prefix      = "10.10.0.5"
      destination_address_prefix = "*"
    }
  ]
}
```

4. **Update documentation** (1 hour)

Update `README.md` with security best practices section

**Day 3: Testing and Validation** (8 hours)

1. **Create automated tests** (4 hours)

**File:** `test/nsg_security_test.go`
```go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestNSGBackwardCompatibility(t *testing.T) {
    t.Parallel()

    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/default",
        Vars: map[string]interface{}{
            "enable_restrictive_mgmt_rules": false,
        },
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    // Verify legacy rule exists
    // Verify restrictive rules don't exist
}

func TestNSGRestrictiveMode(t *testing.T) {
    t.Parallel()

    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/restrictive-nsg",
        Vars: map[string]interface{}{
            "enable_restrictive_mgmt_rules": true,
            "management_source_ips": []string{"10.0.0.0/8"},
            "management_allowed_ports": []int{443, 8443},
        },
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    // Verify correct number of rules
    nsgSummary := terraform.Output(t, terraformOptions, "nsg_rules_summary")

    // Parse and validate
    assert.Contains(t, nsgSummary, "restrictive_mode")
}

func TestNSGCustomRules(t *testing.T) {
    // Test custom rules are created
    // Test priority handling
    // Test rule conflicts
}
```

2. **Manual validation** (2 hours)

```bash
# Test default behavior
cd examples/default
terraform init
terraform plan
# Verify: Single allow-all rule in plan

# Test restrictive mode
cd ../restrictive-nsg
terraform init
terraform plan
# Verify: Multiple specific rules in plan

# Test with Azure CLI
az network nsg rule list \
  --resource-group <rg> \
  --nsg-name <nsg> \
  --output table
```

3. **Security validation** (2 hours)

```bash
# Install and run tfsec
brew install tfsec
tfsec .

# Run Checkov
pip install checkov
checkov -d .

# Document any findings
```

**Acceptance Criteria:**
- [ ] Backward compatible (default behavior unchanged)
- [ ] Restrictive mode works with specific IPs/ports
- [ ] Custom rules can be added without conflicts
- [ ] All tests passing
- [ ] Security scanners approve changes
- [ ] Documentation complete with examples

---

#### Task 2.2: Azure Key Vault Integration (4 days)

**Priority:** HIGH
**Files Modified:** `variables.tf`, `data.tf`, `locals.tf`, `compute.tf`

**Day 1: Design and Variables** (8 hours)

1. **Design Key Vault integration** (3 hours)

Create document: `docs/KEY_VAULT_DESIGN.md`
```markdown
# Azure Key Vault Integration Design

## Requirements
- Optional: Default to direct variable input
- Support both password and client secret from Key Vault
- Allow mix: password from KV, secret from variable (or vice versa)
- No breaking changes to existing deployments

## Architecture

### Option 1: Use existing Key Vault (user-provided)
- User provides Key Vault ID
- User provides secret names
- Module reads secrets via data sources

### Option 2: Create Key Vault (future enhancement)
- Module creates Key Vault
- Module creates secrets
- Out of scope for Phase 2

## Implementation Plan
1. Add optional Key Vault variables
2. Create conditional data sources
3. Update locals to use KV or variables
4. Update compute resources
5. Test both scenarios

## Secret Naming Convention
Default secret names:
- Admin Password: `fortigate-admin-password`
- Client Secret: `fortigate-client-secret`

User can override with custom names
```

2. **Add Key Vault variables** (3 hours)

```hcl
# variables.tf

# =============================================================================
# KEY VAULT INTEGRATION (OPTIONAL)
# =============================================================================

variable "use_key_vault_for_secrets" {
  description = "Retrieve sensitive values from Azure Key Vault instead of variables"
  type        = bool
  default     = false
}

variable "key_vault_id" {
  description = "Azure Key Vault resource ID. Required if use_key_vault_for_secrets = true"
  type        = string
  default     = null

  validation {
    condition     = var.use_key_vault_for_secrets ? var.key_vault_id != null : true
    error_message = "key_vault_id must be provided when use_key_vault_for_secrets is true."
  }
}

variable "admin_password_secret_name" {
  description = "Name of Key Vault secret containing FortiGate admin password"
  type        = string
  default     = "fortigate-admin-password"
}

variable "client_secret_secret_name" {
  description = "Name of Key Vault secret containing Azure SDN connector client secret"
  type        = string
  default     = "fortigate-client-secret"
}

variable "key_vault_secret_version" {
  description = "Specific version of secrets to use (null for latest)"
  type        = string
  default     = null
}

# Keep existing variables for backward compatibility
variable "adminpassword" {
  description = "Administrator password for FortiGate VM. Use Key Vault in production!"
  type        = string
  default     = "Fortinet123#"
  sensitive   = true
}

variable "client_secret" {
  description = "Azure service principal client secret. Use Key Vault in production!"
  type        = string
  sensitive   = true
}
```

3. **Document Key Vault setup** (2 hours)

Create: `docs/KEY_VAULT_SETUP.md`
```markdown
# Azure Key Vault Setup Guide

## Prerequisites
1. Azure Key Vault created
2. Secrets uploaded to Key Vault
3. Terraform/Service Principal has read access

## Step 1: Create Key Vault (if needed)
```bash
# Create Key Vault
az keyvault create \
  --name "fortigate-secrets-kv" \
  --resource-group "rg-security" \
  --location "eastus"

# Set access policy for Terraform service principal
az keyvault set-policy \
  --name "fortigate-secrets-kv" \
  --spn <service-principal-id> \
  --secret-permissions get list
```

## Step 2: Upload Secrets
```bash
# Upload admin password
az keyvault secret set \
  --vault-name "fortigate-secrets-kv" \
  --name "fortigate-admin-password" \
  --value "YourSecurePassword123!"

# Upload client secret
az keyvault secret set \
  --vault-name "fortigate-secrets-kv" \
  --name "fortigate-client-secret" \
  --value "your-azure-client-secret"
```

## Step 3: Get Key Vault ID
```bash
az keyvault show \
  --name "fortigate-secrets-kv" \
  --query id \
  --output tsv
```

## Step 4: Use in Terraform
```hcl
module "fortigate" {
  source = "..."

  use_key_vault_for_secrets = true
  key_vault_id              = "/subscriptions/.../fortigate-secrets-kv"

  # Secret names (optional, uses defaults)
  admin_password_secret_name = "fortigate-admin-password"
  client_secret_secret_name  = "fortigate-client-secret"

  # Don't need to provide these when using Key Vault
  # adminpassword = "..."
  # client_secret = "..."
}
```
```

**Day 2: Implementation** (8 hours)

1. **Add data sources** (2 hours)

```hcl
# data.tf

# =============================================================================
# AZURE KEY VAULT DATA SOURCES (OPTIONAL)
# =============================================================================

# Retrieve admin password from Key Vault
data "azurerm_key_vault_secret" "admin_password" {
  count        = var.use_key_vault_for_secrets ? 1 : 0
  name         = var.admin_password_secret_name
  key_vault_id = var.key_vault_id
  version      = var.key_vault_secret_version
}

# Retrieve client secret from Key Vault
data "azurerm_key_vault_secret" "client_secret" {
  count        = var.use_key_vault_for_secrets ? 1 : 0
  name         = var.client_secret_secret_name
  key_vault_id = var.key_vault_id
  version      = var.key_vault_secret_version
}
```

2. **Update locals** (2 hours)

```hcl
# locals.tf

locals {
  # Use Key Vault secrets if enabled, otherwise use variables
  actual_admin_password = var.use_key_vault_for_secrets ? data.azurerm_key_vault_secret.admin_password[0].value : var.adminpassword
  actual_client_secret  = var.use_key_vault_for_secrets ? data.azurerm_key_vault_secret.client_secret[0].value : var.client_secret

  # Update bootstrap_vars to use actual secrets
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
    active_peerip   = var.active_peerip
    passive_peerip  = var.passive_peerip
    mgmt_gateway_ip = var.port1gateway
    defaultgwy      = var.port2gateway
    tenant          = data.azurerm_client_config.current.tenant_id
    subscription    = data.azurerm_client_config.current.subscription_id
    clientid        = data.azurerm_client_config.current.client_id
    clientsecret    = local.actual_client_secret  # Use computed value
    adminsport      = var.adminsport
    rsg             = var.resource_group_name
    clusterip       = var.public_ip_name
  }
}
```

3. **Update compute resources** (2 hours)

```hcl
# compute.tf

resource "azurerm_linux_virtual_machine" "customfgtvm" {
  count                 = var.custom ? 1 : 0
  name                  = var.name
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = local.network_interface_ids
  size                  = var.size
  zone                  = var.zone
  admin_username        = var.adminusername
  admin_password        = local.actual_admin_password  # Use computed value
  computer_name         = var.computer_name

  # ... rest of config ...
}

resource "azurerm_linux_virtual_machine" "fgtvm" {
  count                 = var.custom ? 0 : 1
  name                  = var.name
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = local.network_interface_ids
  size                  = var.size
  zone                  = var.zone
  admin_username        = var.adminusername
  admin_password        = local.actual_admin_password  # Use computed value
  computer_name         = var.computer_name

  # ... rest of config ...
}
```

4. **Add helpful outputs** (1 hour)

```hcl
# outputs.tf

output "secrets_configuration" {
  description = "Information about secrets configuration (values not exposed)"
  value = {
    using_key_vault            = var.use_key_vault_for_secrets
    key_vault_id               = var.use_key_vault_for_secrets ? var.key_vault_id : null
    admin_password_secret_name = var.use_key_vault_for_secrets ? var.admin_password_secret_name : null
    client_secret_secret_name  = var.use_key_vault_for_secrets ? var.client_secret_secret_name : null
  }
  sensitive = false
}
```

5. **Error handling** (1 hour)

Add validation to prevent common mistakes:

```hcl
# versions.tf or main.tf

# Validate Key Vault configuration
resource "null_resource" "validate_key_vault_config" {
  count = var.use_key_vault_for_secrets && var.key_vault_id == null ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'ERROR: key_vault_id must be provided when use_key_vault_for_secrets is true' && exit 1"
  }
}

# Warn if using default password without Key Vault
resource "null_resource" "warn_insecure_password" {
  count = !var.use_key_vault_for_secrets && var.adminpassword == "Fortinet123#" ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'WARNING: Using default password. This is insecure for production!'"
  }
}
```

**Day 3: Testing** (8 hours)

1. **Create test Key Vault** (2 hours)

```bash
# Create test environment
cd test/fixtures
terraform init

# Create Key Vault and secrets
az keyvault create \
  --name "test-fortigate-kv-${RANDOM}" \
  --resource-group "test-rg" \
  --location "eastus"

KV_ID=$(az keyvault show --name "test-fortigate-kv-${RANDOM}" --query id -o tsv)

# Upload test secrets
az keyvault secret set \
  --vault-name "test-fortigate-kv-${RANDOM}" \
  --name "fortigate-admin-password" \
  --value "TestPassword123!"

az keyvault secret set \
  --vault-name "test-fortigate-kv-${RANDOM}" \
  --name "fortigate-client-secret" \
  --value "test-client-secret"
```

2. **Create automated tests** (4 hours)

**File:** `test/key_vault_test.go`
```go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/gruntwork-io/terratest/modules/azure"
    "github.com/stretchr/testify/assert"
)

func TestKeyVaultIntegration(t *testing.T) {
    t.Parallel()

    // Setup test Key Vault
    kvName := fmt.Sprintf("test-fgt-kv-%s", random.UniqueId())
    resourceGroup := "test-rg"

    // Create Key Vault
    keyVaultID := azure.CreateKeyVault(t, kvName, resourceGroup, "eastus")
    defer azure.DeleteKeyVault(t, kvName, resourceGroup)

    // Upload secrets
    azure.SetKeyVaultSecret(t, kvName, "fortigate-admin-password", "TestPassword123!")
    azure.SetKeyVaultSecret(t, kvName, "fortigate-client-secret", "test-secret")

    // Test Terraform with Key Vault
    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/key-vault",
        Vars: map[string]interface{}{
            "use_key_vault_for_secrets": true,
            "key_vault_id":              keyVaultID,
        },
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    // Verify secrets are retrieved
    secretsConfig := terraform.OutputMap(t, terraformOptions, "secrets_configuration")
    assert.Equal(t, "true", secretsConfig["using_key_vault"])
    assert.Equal(t, keyVaultID, secretsConfig["key_vault_id"])
}

func TestBackwardCompatibilityWithoutKeyVault(t *testing.T) {
    t.Parallel()

    // Test without Key Vault (backward compatible)
    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/default",
        Vars: map[string]interface{}{
            "use_key_vault_for_secrets": false,
            "adminpassword":             "DirectPassword123!",
            "client_secret":             "direct-secret",
        },
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    // Verify deployment succeeds
    vmID := terraform.Output(t, terraformOptions, "fortigate_vm_id")
    assert.NotEmpty(t, vmID)

    secretsConfig := terraform.OutputMap(t, terraformOptions, "secrets_configuration")
    assert.Equal(t, "false", secretsConfig["using_key_vault"])
}

func TestKeyVaultValidation(t *testing.T) {
    // Test that providing use_key_vault=true without key_vault_id fails
    terraformOptions := &terraform.Options{
        TerraformDir: "../",
        Vars: map[string]interface{}{
            "use_key_vault_for_secrets": true,
            // Missing key_vault_id
        },
    }

    _, err := terraform.InitAndPlanE(t, terraformOptions)
    assert.Error(t, err)
    assert.Contains(t, err.Error(), "key_vault_id must be provided")
}
```

3. **Manual testing** (2 hours)

```bash
# Test with Key Vault
cd examples/key-vault
export TF_VAR_key_vault_id="/subscriptions/.../..."
terraform init
terraform plan
# Verify: Secrets are retrieved from Key Vault

# Test without Key Vault (backward compatible)
cd ../default
terraform init
terraform plan
# Verify: Uses variables directly

# Test validation error
terraform plan -var="use_key_vault_for_secrets=true"
# Verify: Error about missing key_vault_id
```

**Day 4: Documentation and Examples** (8 hours)

1. **Create comprehensive example** (3 hours)

**File:** `examples/key-vault/main.tf`
```hcl
# Example: FortiGate with Azure Key Vault Integration
# This example demonstrates using Azure Key Vault for sensitive values

# Prerequisites:
# 1. Azure Key Vault created
# 2. Secrets uploaded (fortigate-admin-password, fortigate-client-secret)
# 3. Terraform has read access to Key Vault

terraform {
  required_version = ">= 1.3.4"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Data source for existing Key Vault
data "azurerm_key_vault" "secrets" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group_name
}

# Deploy FortiGate with Key Vault secrets
module "fortigate_secure" {
  source = "../.."

  # Basic Configuration
  name                  = "fortigate-secure-example"
  computer_name         = "fgt-secure"
  location              = "eastus"
  resource_group_name   = var.resource_group_name
  size                  = "Standard_F8s_v2"
  zone                  = "1"

  # Network Configuration
  hamgmtsubnet_id  = var.hamgmtsubnet_id
  hasyncsubnet_id  = var.hasyncsubnet_id
  publicsubnet_id  = var.publicsubnet_id
  privatesubnet_id = var.privatesubnet_id
  public_ip_id     = var.public_ip_id
  public_ip_name   = var.public_ip_name

  # IP Addresses
  port1 = "10.0.1.10"
  port2 = "10.0.2.10"
  port3 = "10.0.3.10"
  port4 = "10.0.4.10"

  # Gateway IPs
  port1gateway = "10.0.1.1"
  port2gateway = "10.0.2.1"

  # Boot Diagnostics
  boot_diagnostics_storage_endpoint = var.boot_diagnostics_storage_endpoint

  # Key Vault Integration - ENABLED
  use_key_vault_for_secrets = true
  key_vault_id              = data.azurerm_key_vault.secrets.id

  # Optional: Custom secret names (uses defaults if not specified)
  admin_password_secret_name = "fortigate-admin-password"
  client_secret_secret_name  = "fortigate-client-secret"

  # Note: When using Key Vault, you don't need to provide:
  # - adminpassword
  # - client_secret

  # Security: Use restrictive NSG rules
  enable_restrictive_mgmt_rules = true
  management_source_ips         = ["10.0.0.0/8"]
  management_allowed_ports      = [443, 8443]

  # Tags
  tags = {
    Environment = "Production"
    Security    = "Enhanced"
    ManagedBy   = "Terraform"
  }
}

# Outputs
output "management_url" {
  description = "FortiGate management URL"
  value       = module.fortigate_secure.fortigate_management_url
}

output "secrets_info" {
  description = "Key Vault integration status"
  value       = module.fortigate_secure.secrets_configuration
}
```

**File:** `examples/key-vault/variables.tf`
```hcl
variable "key_vault_name" {
  description = "Name of existing Azure Key Vault"
  type        = string
}

variable "key_vault_resource_group_name" {
  description = "Resource group containing Key Vault"
  type        = string
}

# ... other required variables ...
```

**File:** `examples/key-vault/README.md`
```markdown
# FortiGate with Azure Key Vault Integration

This example demonstrates deploying FortiGate with secrets retrieved from Azure Key Vault.

## Prerequisites

### 1. Create Key Vault
```bash
az keyvault create \
  --name "fortigate-prod-kv" \
  --resource-group "rg-security" \
  --location "eastus" \
  --enabled-for-template-deployment true
```

### 2. Upload Secrets
```bash
# Admin password
az keyvault secret set \
  --vault-name "fortigate-prod-kv" \
  --name "fortigate-admin-password" \
  --value "YourSecurePassword123!"

# Client secret
az keyvault secret set \
  --vault-name "fortigate-prod-kv" \
  --name "fortigate-client-secret" \
  --value "your-azure-client-secret-here"
```

### 3. Grant Access
```bash
# Get current user/SP object ID
OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

# Grant secret read permissions
az keyvault set-policy \
  --name "fortigate-prod-kv" \
  --object-id $OBJECT_ID \
  --secret-permissions get list
```

## Deploy

```bash
terraform init

terraform plan \
  -var="key_vault_name=fortigate-prod-kv" \
  -var="key_vault_resource_group_name=rg-security" \
  # ... other vars ...

terraform apply
```

## Verify

```bash
# Check secrets configuration
terraform output secrets_info

# Should show:
# {
#   "using_key_vault" = "true"
#   "key_vault_id" = "/subscriptions/.../fortigate-prod-kv"
#   ...
# }
```

## Security Benefits

1. **No Secrets in Code**: Passwords never stored in Terraform code
2. **Centralized Management**: Secrets managed in one place
3. **Audit Trail**: Key Vault logs all secret access
4. **Rotation**: Easy to rotate secrets without Terraform changes
5. **RBAC**: Fine-grained access control via Azure RBAC
```

2. **Update main documentation** (3 hours)

Update `README.md`:
```markdown
## Security Best Practices

### Azure Key Vault Integration

**Highly Recommended for Production**: Store sensitive values in Azure Key Vault instead of Terraform variables.

#### Quick Start

1. **Create Key Vault and upload secrets**:
```bash
az keyvault create --name "fortigate-kv" --resource-group "rg-security"
az keyvault secret set --vault-name "fortigate-kv" \
  --name "fortigate-admin-password" --value "YourSecurePassword"
az keyvault secret set --vault-name "fortigate-kv" \
  --name "fortigate-client-secret" --value "YourClientSecret"
```

2. **Configure module**:
```hcl
module "fortigate" {
  source = "..."

  # Enable Key Vault
  use_key_vault_for_secrets = true
  key_vault_id              = azurerm_key_vault.main.id

  # No need to provide adminpassword or client_secret
}
```

#### Benefits
- ✅ No secrets in Terraform code or state
- ✅ Centralized secret management
- ✅ Audit trail of secret access
- ✅ Easy secret rotation
- ✅ Role-based access control

See [examples/key-vault](examples/key-vault) for complete example.

### Restrictive Network Security

**Recommended for Production**: Use restrictive NSG rules instead of allow-all.

```hcl
module "fortigate" {
  source = "..."

  # Enable restrictive management access
  enable_restrictive_mgmt_rules = true
  management_source_ips         = ["10.0.0.0/8", "YOUR_ADMIN_IP/32"]
  management_allowed_ports      = [443, 8443]
}
```

Benefits:
- ✅ Limits management access to specific IPs
- ✅ Reduces attack surface
- ✅ Follows least privilege principle
```

3. **Create migration guide** (2 hours)

**File:** `docs/MIGRATING_TO_KEY_VAULT.md`
```markdown
# Migrating Existing Deployments to Azure Key Vault

This guide helps you migrate existing FortiGate deployments to use Azure Key Vault for secrets.

## Overview

Migrating to Key Vault is a two-phase process:
1. **Phase 1**: Create Key Vault and upload secrets
2. **Phase 2**: Update Terraform configuration

**Important**: This migration is **non-destructive** and will not recreate your FortiGate VM.

## Phase 1: Prepare Key Vault

### Step 1: Create Key Vault

```bash
# Set variables
KV_NAME="fortigate-secrets-kv"
RG_NAME="rg-fortigate"
LOCATION="eastus"

# Create Key Vault
az keyvault create \
  --name $KV_NAME \
  --resource-group $RG_NAME \
  --location $LOCATION \
  --enabled-for-template-deployment true
```

### Step 2: Upload Current Secrets

```bash
# Get current admin password from Terraform state
CURRENT_PASSWORD=$(terraform output -raw fortigate_admin_password 2>/dev/null || echo "YourCurrentPassword")

# Upload to Key Vault
az keyvault secret set \
  --vault-name $KV_NAME \
  --name "fortigate-admin-password" \
  --value "$CURRENT_PASSWORD"

# Upload client secret
az keyvault secret set \
  --vault-name $KV_NAME \
  --name "fortigate-client-secret" \
  --value "$YOUR_CLIENT_SECRET"
```

### Step 3: Grant Terraform Access

```bash
# Get service principal ID (or user ID if running locally)
SP_ID=$(az account show --query user.name -o tsv)

# Grant secret read access
az keyvault set-policy \
  --name $KV_NAME \
  --spn $SP_ID \
  --secret-permissions get list
```

## Phase 2: Update Terraform Configuration

### Step 1: Get Key Vault ID

```bash
KV_ID=$(az keyvault show --name $KV_NAME --query id -o tsv)
echo $KV_ID
```

### Step 2: Update Module Configuration

**Before**:
```hcl
module "fortigate" {
  source = "..."

  # ... other config ...

  adminpassword = "MyCurrentPassword"
  client_secret = "my-client-secret"
}
```

**After**:
```hcl
module "fortigate" {
  source = "..."

  # ... other config ...

  # Enable Key Vault
  use_key_vault_for_secrets = true
  key_vault_id              = "/subscriptions/.../fortigate-secrets-kv"

  # Remove these lines (or comment out):
  # adminpassword = "MyCurrentPassword"
  # client_secret = "my-client-secret"
}
```

### Step 3: Plan and Verify

```bash
terraform plan
```

**Expected Output**:
```
No changes. Your infrastructure matches the configuration.
```

If you see changes to the VM resource, **STOP** and review. The migration should not modify the VM.

### Step 4: Apply

```bash
terraform apply
```

## Verification

### Confirm Key Vault is Being Used

```bash
terraform output secrets_configuration
```

Should show:
```hcl
{
  using_key_vault = true
  key_vault_id    = "/subscriptions/.../fortigate-secrets-kv"
}
```

### Test FortiGate Access

```bash
# Get management URL
MGMT_URL=$(terraform output -raw fortigate_management_url)

# Test access (should work with password from Key Vault)
curl -k $MGMT_URL
```

## Troubleshooting

### Error: "Failed to retrieve secret"

**Cause**: Terraform doesn't have access to Key Vault

**Solution**:
```bash
az keyvault set-policy \
  --name $KV_NAME \
  --spn $(az account show --query user.name -o tsv) \
  --secret-permissions get list
```

### Error: "VM will be recreated"

**Cause**: Password changed between variable and Key Vault

**Solution**: Ensure the password in Key Vault matches the current VM password exactly.

## Rollback

If needed, you can rollback by:

1. Set `use_key_vault_for_secrets = false`
2. Provide secrets via variables again
3. Run `terraform apply`

## Security Cleanup

After successful migration:

1. **Remove secrets from Terraform files**
2. **Remove secrets from state** (if stored):
   ```bash
   terraform state pull | grep -i password
   # If found, consider: terraform state rm <resource>
   ```
3. **Enable Key Vault audit logging**
4. **Set up secret rotation schedule**
```

**Acceptance Criteria:**
- [ ] Key Vault integration works correctly
- [ ] Backward compatible (can still use variables)
- [ ] Secrets never appear in state or logs
- [ ] Migration guide tested and accurate
- [ ] All tests passing
- [ ] Documentation complete

---

### Phase 2 Deliverables

**Code Changes:**
- [ ] Configurable NSG rules implemented
- [ ] Azure Key Vault integration added
- [ ] Backward compatibility maintained

**Documentation:**
- [ ] Security best practices documented
- [ ] Key Vault setup guide created
- [ ] Migration guide written
- [ ] Examples provided

**Testing:**
- [ ] NSG rule tests passing
- [ ] Key Vault integration tests passing
- [ ] Backward compatibility verified
- [ ] Security scanning completed

---

## Phase 3: Flexibility Features

**Duration:** 1 week
**Team:** 1 developer
**Risk:** Low
**Backward Compatibility:** ✅ 100%

### Objectives
- Add optional management public IP
- Implement configurable disk settings (already done in Phase 1)
- Add support for additional network interfaces
- Improve deployment flexibility

### Tasks

#### Task 3.1: Optional Management Public IP (2 days)

**Priority:** MEDIUM
**Files Modified:** `variables.tf`, `network.tf`, `outputs.tf`

**Implementation Steps:**

**Day 1: Implementation** (6 hours)

1. **Add variable** (30 min)
```hcl
# variables.tf
variable "enable_mgmt_public_ip" {
  description = "Create public IP for management interface. Set false for private-only deployments"
  type        = bool
  default     = true
}
```

2. **Update public IP resource** (1 hour)
```hcl
# network.tf
resource "azurerm_public_ip" "mgmt_ip" {
  count               = var.enable_mgmt_public_ip ? 1 : 0
  name                = "${var.computer_name}mgmtip"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = local.common_tags

  dynamic "lifecycle" {
    for_each = var.enable_deletion_protection ? [1] : []
    content {
      prevent_destroy = true
    }
  }
}
```

3. **Update NIC configuration** (2 hours)
```hcl
# network.tf
resource "azurerm_network_interface" "port1" {
  name                           = "${var.computer_name}port1"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.hamgmtsubnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.port1
    primary                       = true
    public_ip_address_id          = var.enable_mgmt_public_ip ? azurerm_public_ip.mgmt_ip[0].id : null
  }

  tags = local.common_tags

  dynamic "lifecycle" {
    for_each = var.enable_deletion_protection ? [1] : []
    content {
      prevent_destroy = true
    }
  }
}
```

4. **Update outputs** (1.5 hours)
```hcl
# outputs.tf
output "management_public_ip" {
  description = "Public IP address for FortiGate management (null if disabled)"
  value       = var.enable_mgmt_public_ip ? azurerm_public_ip.mgmt_ip[0].ip_address : null
}

output "management_public_ip_id" {
  description = "Azure resource ID of management public IP (null if disabled)"
  value       = var.enable_mgmt_public_ip ? azurerm_public_ip.mgmt_ip[0].id : null
}

output "fortigate_management_url" {
  description = "HTTPS URL for FortiGate management interface (uses private IP if public IP disabled)"
  value = var.enable_mgmt_public_ip ? (
    "https://${azurerm_public_ip.mgmt_ip[0].ip_address}:${var.adminsport}"
  ) : (
    "https://${azurerm_network_interface.port1.private_ip_address}:${var.adminsport} (private)"
  )
}

output "management_access_method" {
  description = "How to access FortiGate management"
  value = {
    public_ip_enabled = var.enable_mgmt_public_ip
    public_ip         = var.enable_mgmt_public_ip ? azurerm_public_ip.mgmt_ip[0].ip_address : null
    private_ip        = azurerm_network_interface.port1.private_ip_address
    access_note       = var.enable_mgmt_public_ip ? "Access via public IP" : "Access via private IP (VPN/Bastion required)"
  }
}
```

5. **Add validation** (1 hour)
```hcl
# locals.tf
locals {
  # Validation: Warn if restrictive NSG rules enabled without public IP
  nsg_warning = var.enable_restrictive_mgmt_rules && !var.enable_mgmt_public_ip ? (
    "WARNING: Restrictive NSG rules enabled but management public IP disabled. Ensure private access is configured."
  ) : null
}

# main.tf or locals.tf
resource "null_resource" "validate_mgmt_access" {
  count = local.nsg_warning != null ? 1 : 0

  provisioner "local-exec" {
    command = "echo '${local.nsg_warning}'"
  }

  triggers = {
    warning = local.nsg_warning
  }
}
```

**Day 2: Testing and Examples** (6 hours)

1. **Create example** (2 hours)

**File:** `examples/private-management/main.tf`
```hcl
# Example: FortiGate with Private Management (No Public IP)
# Suitable for deployments with VPN or Azure Bastion access

module "fortigate_private" {
  source = "../.."

  # ... standard config ...

  # Disable management public IP
  enable_mgmt_public_ip = false

  # Note: Access via private IP only
  # Requires VPN or Azure Bastion
}

# Optional: Deploy Azure Bastion for management access
resource "azurerm_bastion_host" "management" {
  name                = "bastion-fortigate-mgmt"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}
```

2. **Add tests** (3 hours)
```go
func TestPrivateManagement(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/private-management",
        Vars: map[string]interface{}{
            "enable_mgmt_public_ip": false,
        },
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    // Verify no public IP created
    mgmtIP := terraform.Output(t, terraformOptions, "management_public_ip")
    assert.Empty(t, mgmtIP)

    // Verify private IP accessible
    accessMethod := terraform.OutputMap(t, terraformOptions, "management_access_method")
    assert.Equal(t, "false", accessMethod["public_ip_enabled"])
    assert.NotEmpty(t, accessMethod["private_ip"])
}
```

3. **Update documentation** (1 hour)

**Acceptance Criteria:**
- [ ] Public IP creation is optional
- [ ] Outputs handle both scenarios correctly
- [ ] Warning shows when appropriate
- [ ] Tests pass for both public and private scenarios
- [ ] Documentation includes examples

---

#### Task 3.2: Additional Network Interfaces Support (3 days)

**Priority:** MEDIUM
**Files Modified:** `variables.tf`, `locals.tf`, `network.tf`, `compute.tf`, `outputs.tf`

**Day 1: Design and Variables** (6 hours)

1. **Design interface configuration** (2 hours)

Create: `docs/ADDITIONAL_INTERFACES_DESIGN.md`
```markdown
# Additional Network Interfaces Design

## Requirements
- Support 5+ network interfaces (beyond standard 4)
- Configurable per interface: subnet, IP, forwarding
- Optional NSG association
- Maintain NIC ordering (port1-4 first, additional after)

## Configuration Structure
```hcl
additional_interfaces = [
  {
    name              = "port5"
    subnet_id         = "/subscriptions/.../subnet5"
    private_ip        = "10.0.5.10"
    enable_forwarding = true
    nsg_id            = null  # Optional
  },
  {
    name              = "port6"
    subnet_id         = "/subscriptions/.../subnet6"
    private_ip        = "10.0.6.10"
    enable_forwarding = false
    nsg_id            = azurerm_network_security_group.custom.id
  }
]
```

## Implementation Notes
- VM size must support additional NICs
- Azure limits vary by VM size
- NICs added in order: port1, port2, port3, port4, port5, port6, ...
```

2. **Add variables** (2 hours)
```hcl
# variables.tf
variable "additional_interfaces" {
  description = "Additional network interfaces beyond the standard 4 ports. Each requires name, subnet_id, private_ip, enable_forwarding, and optional nsg_id"
  type = list(object({
    name              = string
    subnet_id         = string
    private_ip        = string
    private_ip_mask   = string
    enable_forwarding = bool
    nsg_id            = optional(string, null)
  }))
  default = []

  validation {
    condition     = length(var.additional_interfaces) <= 4  # Most VM sizes support up to 8 NICs total
    error_message = "Maximum 4 additional interfaces supported (8 total). Check your VM size NIC limit."
  }

  validation {
    condition = alltrue([
      for iface in var.additional_interfaces :
      can(regex("^port[5-8]$", iface.name))
    ])
    error_message = "Additional interface names must be port5, port6, port7, or port8."
  }

  validation {
    condition = alltrue([
      for iface in var.additional_interfaces :
      can(cidrhost("${iface.private_ip}/32", 0))
    ])
    error_message = "All private IPs must be valid IPv4 addresses."
  }
}

variable "enable_additional_interfaces_in_bootstrap" {
  description = "Include additional interfaces in bootstrap configuration"
  type        = bool
  default     = true
}
```

3. **Update locals** (2 hours)
```hcl
# locals.tf
locals {
  # All network interface IDs in correct order
  all_network_interface_ids = concat(
    [
      azurerm_network_interface.port1.id,
      azurerm_network_interface.port2.id,
      azurerm_network_interface.port3.id,
      azurerm_network_interface.port4.id
    ],
    azurerm_network_interface.additional[*].id
  )

  # Bootstrap configuration for additional interfaces
  additional_interfaces_config = var.enable_additional_interfaces_in_bootstrap ? {
    for idx, iface in var.additional_interfaces :
    iface.name => {
      ip    = iface.private_ip
      mask  = iface.private_ip_mask
    }
  } : {}

  # Updated bootstrap vars to include additional interfaces
  bootstrap_vars_extended = merge(local.bootstrap_vars, {
    additional_interfaces = local.additional_interfaces_config
  })
}
```

**Day 2: Implementation** (8 hours)

1. **Add NIC resources** (3 hours)
```hcl
# network.tf

# =============================================================================
# ADDITIONAL NETWORK INTERFACES (OPTIONAL)
# =============================================================================

# Additional network interfaces beyond the standard 4 ports
# Useful for advanced routing scenarios or additional network segments
resource "azurerm_network_interface" "additional" {
  count                          = length(var.additional_interfaces)
  name                           = "${var.computer_name}${var.additional_interfaces[count.index].name}"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  ip_forwarding_enabled          = var.additional_interfaces[count.index].enable_forwarding
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.additional_interfaces[count.index].subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.additional_interfaces[count.index].private_ip
  }

  tags = local.common_tags

  dynamic "lifecycle" {
    for_each = var.enable_deletion_protection ? [1] : []
    content {
      prevent_destroy = true
    }
  }
}

# NSG associations for additional interfaces (if specified)
resource "azurerm_network_interface_security_group_association" "additional" {
  count                     = length([for iface in var.additional_interfaces : iface if iface.nsg_id != null])
  network_interface_id      = azurerm_network_interface.additional[count.index].id
  network_security_group_id = var.additional_interfaces[count.index].nsg_id

  depends_on = [azurerm_network_interface.additional]

  dynamic "lifecycle" {
    for_each = var.enable_deletion_protection ? [1] : []
    content {
      prevent_destroy = true
    }
  }
}
```

2. **Update compute resources** (2 hours)
```hcl
# compute.tf

# Update both VM resources to use local.all_network_interface_ids
resource "azurerm_linux_virtual_machine" "customfgtvm" {
  count                 = var.custom ? 1 : 0
  name                  = var.name
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = local.all_network_interface_ids  # Updated
  size                  = var.size
  zone                  = var.zone
  admin_username        = var.adminusername
  admin_password        = local.actual_admin_password
  computer_name         = var.computer_name

  source_image_id = azurerm_image.custom[0].id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Use extended bootstrap vars if additional interfaces exist
  custom_data = base64encode(templatefile(
    "${path.module}/${var.bootstrap}",
    length(var.additional_interfaces) > 0 ? local.bootstrap_vars_extended : local.bootstrap_vars
  ))

  disable_password_authentication = false

  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics_storage_endpoint
  }

  dynamic "lifecycle" {
    for_each = var.enable_deletion_protection ? [1] : []
    content {
      prevent_destroy = true
      ignore_changes  = [custom_data]
    }
  }

  tags = local.common_tags
}

# Same update for fgtvm resource
resource "azurerm_linux_virtual_machine" "fgtvm" {
  count                 = var.custom ? 0 : 1
  # ... same changes as above ...
  network_interface_ids = local.all_network_interface_ids  # Updated
  # ... rest of config ...
}
```

3. **Add outputs** (1.5 hours)
```hcl
# outputs.tf

# =============================================================================
# ADDITIONAL INTERFACE OUTPUTS
# =============================================================================

output "additional_interface_ids" {
  description = "Azure resource IDs of additional network interfaces"
  value       = azurerm_network_interface.additional[*].id
}

output "additional_interface_ips" {
  description = "Private IP addresses of additional network interfaces"
  value = {
    for idx, iface in var.additional_interfaces :
    iface.name => azurerm_network_interface.additional[idx].private_ip_address
  }
}

output "all_interface_summary" {
  description = "Summary of all network interfaces"
  value = merge(
    {
      port1 = {
        id         = azurerm_network_interface.port1.id
        private_ip = azurerm_network_interface.port1.private_ip_address
        public_ip  = var.enable_mgmt_public_ip ? azurerm_public_ip.mgmt_ip[0].ip_address : null
      }
      port2 = {
        id         = azurerm_network_interface.port2.id
        private_ip = azurerm_network_interface.port2.private_ip_address
      }
      port3 = {
        id         = azurerm_network_interface.port3.id
        private_ip = azurerm_network_interface.port3.private_ip_address
      }
      port4 = {
        id         = azurerm_network_interface.port4.id
        private_ip = azurerm_network_interface.port4.private_ip_address
      }
    },
    {
      for idx, iface in var.additional_interfaces :
      iface.name => {
        id         = azurerm_network_interface.additional[idx].id
        private_ip = azurerm_network_interface.additional[idx].private_ip_address
      }
    }
  )
}
```

4. **Add validation** (1.5 hours)
```hcl
# locals.tf

locals {
  # Validate VM size supports required NIC count
  total_nic_count = 4 + length(var.additional_interfaces)

  # Common VM sizes and their NIC limits
  vm_nic_limits = {
    "Standard_F8s_v2"  = 4
    "Standard_F16s_v2" = 8
    "Standard_D2s_v3"  = 2
    "Standard_D4s_v3"  = 4
    "Standard_D8s_v3"  = 8
  }

  vm_nic_limit = lookup(local.vm_nic_limits, var.size, 8)  # Default to 8 if unknown

  nic_count_error = local.total_nic_count > local.vm_nic_limit ? (
    "ERROR: VM size ${var.size} supports maximum ${local.vm_nic_limit} NICs, but ${local.total_nic_count} requested. Choose larger VM size."
  ) : null
}

# Validation check
resource "null_resource" "validate_nic_count" {
  count = local.nic_count_error != null ? 1 : 0

  provisioner "local-exec" {
    command = "echo '${local.nic_count_error}' && exit 1"
  }

  triggers = {
    nic_count = local.total_nic_count
    vm_size   = var.size
  }
}
```

**Day 3: Testing and Documentation** (6 hours)

1. **Create example** (2 hours)

**File:** `examples/additional-interfaces/main.tf`
```hcl
# Example: FortiGate with Additional Network Interfaces
# Demonstrates using more than 4 network interfaces

module "fortigate_multi_nic" {
  source = "../.."

  # ... standard config ...

  # Use VM size that supports 8 NICs
  size = "Standard_F16s_v2"

  # Standard 4 interfaces
  hamgmtsubnet_id  = data.azurerm_subnet.mgmt.id
  hasyncsubnet_id  = data.azurerm_subnet.sync.id
  publicsubnet_id  = data.azurerm_subnet.public.id
  privatesubnet_id = data.azurerm_subnet.private.id

  # Standard IPs
  port1 = "10.0.1.10"
  port2 = "10.0.2.10"
  port3 = "10.0.3.10"
  port4 = "10.0.4.10"

  # Additional interfaces
  additional_interfaces = [
    {
      name              = "port5"
      subnet_id         = data.azurerm_subnet.dmz.id
      private_ip        = "10.0.5.10"
      private_ip_mask   = "255.255.255.0"
      enable_forwarding = true
      nsg_id            = azurerm_network_security_group.dmz.id
    },
    {
      name              = "port6"
      subnet_id         = data.azurerm_subnet.partner.id
      private_ip        = "10.0.6.10"
      private_ip_mask   = "255.255.255.0"
      enable_forwarding = true
      nsg_id            = null
    }
  ]
}

# Output all interfaces
output "all_interfaces" {
  value = module.fortigate_multi_nic.all_interface_summary
}
```

2. **Add tests** (3 hours)
```go
func TestAdditionalInterfaces(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/additional-interfaces",
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    // Verify correct number of interfaces
    interfaceSummary := terraform.OutputMap(t, terraformOptions, "all_interface_summary")

    // Should have 6 interfaces (4 standard + 2 additional)
    assert.Equal(t, 6, len(interfaceSummary))
    assert.Contains(t, interfaceSummary, "port5")
    assert.Contains(t, interfaceSummary, "port6")
}

func TestVMSizeValidation(t *testing.T) {
    // Test that small VM size fails with too many NICs
    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/additional-interfaces",
        Vars: map[string]interface{}{
            "size": "Standard_D2s_v3",  // Only supports 2 NICs
        },
    }

    _, err := terraform.InitAndPlanE(t, terraformOptions)
    assert.Error(t, err)
    assert.Contains(t, err.Error(), "supports maximum 2 NICs")
}
```

3. **Update documentation** (1 hour)

**Acceptance Criteria:**
- [ ] Additional interfaces can be configured
- [ ] NICs are ordered correctly
- [ ] VM size validation works
- [ ] Tests pass
- [ ] Documentation includes examples

---

### Phase 3 Deliverables

**Code Changes:**
- [ ] Optional management public IP implemented
- [ ] Additional network interfaces support added
- [ ] All validations in place

**Documentation:**
- [ ] Private management examples created
- [ ] Additional interfaces examples provided
- [ ] Design documents written
- [ ] README updated

**Testing:**
- [ ] All tests passing
- [ ] Validation tests for edge cases
- [ ] Examples tested

---

## Phase 4: Observability & Monitoring

**Duration:** 1 week
**Team:** 1 developer
**Risk:** Low
**Backward Compatibility:** ✅ 100%

### Objectives
- Add Azure Monitor integration
- Implement NSG flow logs
- Add diagnostic settings
- Improve operational visibility

### Tasks

#### Task 4.1: Azure Monitor Alerts (2 days)

**Priority:** MEDIUM
**Files Created:** `monitoring.tf`
**Files Modified:** `variables.tf`, `outputs.tf`

**Day 1: Implementation** (8 hours)

1. **Add monitoring variables** (1 hour)
```hcl
# variables.tf

# =============================================================================
# MONITORING AND ALERTING
# =============================================================================

variable "enable_monitoring_alerts" {
  description = "Enable Azure Monitor metric alerts for FortiGate VM"
  type        = bool
  default     = false
}

variable "action_group_id" {
  description = "Azure Monitor action group ID for alert notifications. Required if enable_monitoring_alerts = true"
  type        = string
  default     = null

  validation {
    condition     = var.enable_monitoring_alerts ? var.action_group_id != null : true
    error_message = "action_group_id must be provided when enable_monitoring_alerts is true."
  }
}

variable "cpu_alert_threshold" {
  description = "CPU usage percentage threshold for alerts"
  type        = number
  default     = 80

  validation {
    condition     = var.cpu_alert_threshold > 0 && var.cpu_alert_threshold <= 100
    error_message = "CPU threshold must be between 1 and 100."
  }
}

variable "memory_alert_threshold_bytes" {
  description = "Available memory threshold in bytes for alerts"
  type        = number
  default     = 524288000  # 500 MB
}

variable "disk_alert_threshold_percent" {
  description = "Disk usage percentage threshold for alerts"
  type        = number
  default     = 85

  validation {
    condition     = var.disk_alert_threshold_percent > 0 && var.disk_alert_threshold_percent <= 100
    error_message = "Disk threshold must be between 1 and 100."
  }
}

variable "enable_vm_insights" {
  description = "Enable Azure Monitor VM Insights for detailed monitoring"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for VM Insights. Required if enable_vm_insights = true"
  type        = string
  default     = null
}
```

2. **Create monitoring.tf** (5 hours)

```hcl
# =============================================================================
# FORTIGATE MODULE - MONITORING AND ALERTS
# =============================================================================
# This file contains Azure Monitor resources for FortiGate observability
# including metric alerts and VM Insights integration.
# =============================================================================

# =============================================================================
# METRIC ALERTS
# =============================================================================

# CPU Usage Alert
resource "azurerm_monitor_metric_alert" "cpu_alert" {
  count               = var.enable_monitoring_alerts ? 1 : 0
  name                = "${var.computer_name}-cpu-alert"
  resource_group_name = var.resource_group_name
  scopes              = [local.vm_id]
  description         = "Alert when FortiGate CPU usage exceeds ${var.cpu_alert_threshold}%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.cpu_alert_threshold
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = local.common_tags
}

# Memory Alert
resource "azurerm_monitor_metric_alert" "memory_alert" {
  count               = var.enable_monitoring_alerts ? 1 : 0
  name                = "${var.computer_name}-memory-alert"
  resource_group_name = var.resource_group_name
  scopes              = [local.vm_id]
  description         = "Alert when FortiGate available memory drops below threshold"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Available Memory Bytes"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = var.memory_alert_threshold_bytes
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = local.common_tags
}

# Disk Usage Alert (Data Disk)
resource "azurerm_monitor_metric_alert" "disk_alert" {
  count               = var.enable_monitoring_alerts && var.enable_data_disk ? 1 : 0
  name                = "${var.computer_name}-disk-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_managed_disk.fgt_data_drive[0].id]
  description         = "Alert when FortiGate data disk usage exceeds ${var.disk_alert_threshold_percent}%"
  severity            = 2
  frequency           = "PT15M"
  window_size         = "PT30M"

  criteria {
    metric_namespace = "Microsoft.Compute/disks"
    metric_name      = "Composite Disk Write Bytes/sec"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 10485760  # 10 MB/s - indicates heavy logging
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = local.common_tags
}

# VM Availability Alert
resource "azurerm_monitor_metric_alert" "vm_availability" {
  count               = var.enable_monitoring_alerts ? 1 : 0
  name                = "${var.computer_name}-availability-alert"
  resource_group_name = var.resource_group_name
  scopes              = [local.vm_id]
  description         = "Alert when FortiGate VM becomes unavailable"
  severity            = 1  # Critical
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "VmAvailabilityMetric"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = local.common_tags
}

# =============================================================================
# VM INSIGHTS (Optional)
# =============================================================================

# Enable VM Insights for detailed monitoring
resource "azurerm_virtual_machine_extension" "monitoring_agent" {
  count                      = var.enable_vm_insights ? 1 : 0
  name                       = "MicrosoftMonitoringAgent"
  virtual_machine_id         = local.vm_id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "OmsAgentForLinux"
  type_handler_version       = "1.13"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    workspaceId = var.log_analytics_workspace_id
  })

  protected_settings = jsonencode({
    workspaceKey = var.log_analytics_workspace_key
  })

  tags = local.common_tags
}

# Dependency Agent for VM Insights
resource "azurerm_virtual_machine_extension" "dependency_agent" {
  count                      = var.enable_vm_insights ? 1 : 0
  name                       = "DependencyAgent"
  virtual_machine_id         = local.vm_id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentLinux"
  type_handler_version       = "9.10"
  auto_upgrade_minor_version = true

  depends_on = [azurerm_virtual_machine_extension.monitoring_agent]

  tags = local.common_tags
}

# =============================================================================
# DIAGNOSTIC SETTINGS
# =============================================================================

# Boot diagnostics are already configured in compute.tf
# This section can be extended for additional diagnostic settings

```

3. **Add monitoring outputs** (1 hour)
```hcl
# outputs.tf

output "monitoring_configuration" {
  description = "Monitoring and alerting configuration status"
  value = {
    alerts_enabled     = var.enable_monitoring_alerts
    vm_insights_enabled = var.enable_vm_insights
    cpu_threshold      = var.enable_monitoring_alerts ? var.cpu_alert_threshold : null
    memory_threshold   = var.enable_monitoring_alerts ? var.memory_alert_threshold_bytes : null
    disk_threshold     = var.enable_monitoring_alerts ? var.disk_alert_threshold_percent : null
    action_group_id    = var.enable_monitoring_alerts ? var.action_group_id : null
  }
}

output "alert_ids" {
  description = "Resource IDs of created metric alerts"
  value = var.enable_monitoring_alerts ? {
    cpu_alert           = azurerm_monitor_metric_alert.cpu_alert[0].id
    memory_alert        = azurerm_monitor_metric_alert.memory_alert[0].id
    disk_alert          = var.enable_data_disk ? azurerm_monitor_metric_alert.disk_alert[0].id : null
    availability_alert  = azurerm_monitor_metric_alert.vm_availability[0].id
  } : null
}
```

4. **Update module README** (1 hour)

**Day 2: Testing and Examples** (8 hours)

1. **Create monitoring example** (3 hours)

**File:** `examples/with-monitoring/main.tf`
```hcl
# Example: FortiGate with Full Monitoring Configuration

# Create Action Group for alerts
resource "azurerm_monitor_action_group" "fortigate_alerts" {
  name                = "fortigate-alerts"
  resource_group_name = var.resource_group_name
  short_name          = "fgt-alert"

  email_receiver {
    name          = "ops-team"
    email_address = "ops@example.com"
  }

  sms_receiver {
    name         = "oncall"
    country_code = "1"
    phone_number = "5555555555"
  }
}

# Create Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "fortigate" {
  name                = "log-fortigate-monitoring"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Deploy FortiGate with monitoring
module "fortigate_monitored" {
  source = "../.."

  # ... standard config ...

  # Enable monitoring alerts
  enable_monitoring_alerts      = true
  action_group_id               = azurerm_monitor_action_group.fortigate_alerts.id
  cpu_alert_threshold           = 80
  memory_alert_threshold_bytes  = 524288000  # 500 MB
  disk_alert_threshold_percent  = 85

  # Enable VM Insights
  enable_vm_insights          = true
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.fortigate.workspace_id
  log_analytics_workspace_key = azurerm_log_analytics_workspace.fortigate.primary_shared_key
}

# Outputs
output "monitoring_dashboard_url" {
  description = "URL to Azure Monitor dashboard"
  value       = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource${module.fortigate_monitored.fortigate_vm_id}/metrics"
}

output "monitoring_status" {
  value = module.fortigate_monitored.monitoring_configuration
}
```

2. **Add tests** (3 hours)
```go
func TestMonitoringIntegration(t *testing.T) {
    // Test monitoring alerts are created
    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/with-monitoring",
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    // Verify monitoring configuration
    monitoringConfig := terraform.OutputMap(t, terraformOptions, "monitoring_status")
    assert.Equal(t, "true", monitoringConfig["alerts_enabled"])
    assert.Equal(t, "true", monitoringConfig["vm_insights_enabled"])

    // Verify alerts created
    alertIDs := terraform.OutputMap(t, terraformOptions, "alert_ids")
    assert.NotEmpty(t, alertIDs["cpu_alert"])
    assert.NotEmpty(t, alertIDs["memory_alert"])
}
```

3. **Create monitoring guide** (2 hours)

**File:** `docs/MONITORING_GUIDE.md`
```markdown
# FortiGate Monitoring Guide

This guide explains how to set up comprehensive monitoring for FortiGate deployments.

## Quick Start

### 1. Create Action Group

Action Groups define who gets notified:

```bash
az monitor action-group create \
  --name "fortigate-alerts" \
  --resource-group "rg-fortigate" \
  --short-name "fgt-alert" \
  --email-receiver name="ops-team" email="ops@example.com"
```

### 2. Enable Monitoring in Terraform

```hcl
module "fortigate" {
  source = "..."

  # ... other config ...

  enable_monitoring_alerts = true
  action_group_id          = azurerm_monitor_action_group.alerts.id
  cpu_alert_threshold      = 80
}
```

## Available Alerts

### CPU Alert
- **Metric**: Percentage CPU
- **Default Threshold**: 80%
- **Severity**: Warning
- **Window**: 15 minutes

**Triggered when**: Average CPU usage exceeds threshold

### Memory Alert
- **Metric**: Available Memory Bytes
- **Default Threshold**: 500 MB
- **Severity**: Warning
- **Window**: 15 minutes

**Triggered when**: Available memory drops below threshold

### Disk Alert
- **Metric**: Disk Write Bytes/sec
- **Default Threshold**: 10 MB/s
- **Severity**: Warning
- **Window**: 30 minutes

**Triggered when**: Heavy logging activity detected

### Availability Alert
- **Metric**: VM Availability
- **Threshold**: < 1
- **Severity**: Critical
- **Window**: 5 minutes

**Triggered when**: VM becomes unavailable

## VM Insights (Advanced)

Enable for detailed performance monitoring:

```hcl
module "fortigate" {
  # ... other config ...

  enable_vm_insights          = true
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.main.workspace_id
  log_analytics_workspace_key = azurerm_log_analytics_workspace.main.primary_shared_key
}
```

### Features:
- Process-level monitoring
- Network connection mapping
- Performance trend analysis
- Dependency visualization

## Viewing Metrics

### Azure Portal
1. Navigate to FortiGate VM resource
2. Click "Metrics" in left menu
3. Select metric to view

### Azure CLI
```bash
# View CPU metrics
az monitor metrics list \
  --resource <vm-id> \
  --metric "Percentage CPU" \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z
```

## Custom Queries (Log Analytics)

### High CPU Usage
```kusto
Perf
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| where CounterValue > 80
| summarize avg(CounterValue) by bin(TimeGenerated, 5m)
```

### Memory Usage Trend
```kusto
Perf
| where ObjectName == "Memory" and CounterName == "Available MBytes"
| summarize avg(CounterValue) by bin(TimeGenerated, 5m)
| render timechart
```

## Alert Customization

### Adjust Thresholds
```hcl
module "fortigate" {
  # ...
  cpu_alert_threshold          = 90  # Increase to 90%
  memory_alert_threshold_bytes = 262144000  # Lower to 250 MB
}
```

### Add Custom Actions
```hcl
resource "azurerm_monitor_action_group" "custom" {
  name                = "fortigate-custom-actions"
  resource_group_name = var.resource_group_name
  short_name          = "fgt-custom"

  # Email notifications
  email_receiver {
    name          = "ops-team"
    email_address = "ops@example.com"
  }

  # SMS notifications
  sms_receiver {
    name         = "oncall"
    country_code = "1"
    phone_number = "5555555555"
  }

  # Webhook for automation
  webhook_receiver {
    name        = "automation"
    service_uri = "https://your-automation-endpoint.com/webhook"
  }

  # Azure Function integration
  azure_function_receiver {
    name                     = "auto-remediate"
    function_app_resource_id = azurerm_function_app.remediation.id
    function_name            = "auto-remediate"
    http_trigger_url         = "https://your-function.azurewebsites.net/api/remediate"
  }
}
```

## Troubleshooting

### Alerts Not Firing
1. Check action group is configured correctly
2. Verify metric thresholds are set appropriately
3. Ensure VM has been running long enough to generate metrics

### VM Insights Not Working
1. Verify Log Analytics workspace is accessible
2. Check VM extensions are installed: `az vm extension list`
3. Review extension logs in VM diagnostics

### High False Positive Rate
- Increase alert thresholds
- Adjust time windows
- Use dynamic thresholds (machine learning-based)

## Best Practices

1. **Start Conservative**: Begin with higher thresholds, adjust based on baseline
2. **Test Alerts**: Manually trigger test alerts to verify notification flow
3. **Document Runbooks**: Create response procedures for each alert type
4. **Review Regularly**: Analyze alert patterns monthly
5. **Use Workbooks**: Create Azure Workbooks for custom dashboards

## Cost Optimization

- VM Insights adds cost (~$2/VM/month + data ingestion)
- Metric alerts are free (up to 10 per resource)
- Log Analytics charges for data ingestion and retention
- Consider shorter retention periods for cost savings

## Resources

- [Azure Monitor Documentation](https://docs.microsoft.com/azure/azure-monitor/)
- [VM Insights Overview](https://docs.microsoft.com/azure/azure-monitor/vm/vminsights-overview)
- [Alert Best Practices](https://docs.microsoft.com/azure/azure-monitor/alerts/alerts-best-practices)
```

**Acceptance Criteria:**
- [ ] Metric alerts created for CPU, memory, disk, availability
- [ ] VM Insights integration working
- [ ] Tests passing
- [ ] Documentation complete
- [ ] Example functional

---

#### Task 4.2: NSG Flow Logs (2 days)

**Priority:** MEDIUM
**Files Modified:** `variables.tf`, `network.tf`, `outputs.tf`

(Implementation details similar to above, with focus on NSG flow log configuration)

---

#### Task 4.3: Enhanced Diagnostic Settings (1 day)

**Priority:** LOW
**Files Modified:** `variables.tf`, `compute.tf`, `outputs.tf`

(Implementation details for boot diagnostics enhancements and activity logs)

---

### Phase 4 Deliverables

**Code Changes:**
- [ ] Azure Monitor alerts implemented
- [ ] VM Insights integration added
- [ ] NSG flow logs configured
- [ ] Enhanced diagnostics in place

**Documentation:**
- [ ] Monitoring guide created
- [ ] Examples provided
- [ ] Best practices documented

**Testing:**
- [ ] All tests passing
- [ ] Alert validation completed
- [ ] Examples functional

---

## Phase 5: Advanced Features (Optional)

**Duration:** 2 weeks (optional)
**Team:** 1-2 developers
**Risk:** Medium
**Backward Compatibility:** ✅ 100%

### Objectives
- Create HA pair wrapper module
- Add backup/recovery automation
- Implement policy-as-code
- Add advanced networking features

*(Detailed tasks omitted for brevity - would follow similar structure to previous phases)*

---

## Testing Strategy

### Unit Testing

**Tools**: Terratest (Go)
**Coverage Target**: 80%+

#### Test Categories

1. **Backward Compatibility Tests**
   - Verify default behavior unchanged
   - Test existing examples still work
   - Validate state compatibility

2. **Feature Tests**
   - Test each new feature independently
   - Validate feature combinations
   - Test edge cases

3. **Validation Tests**
   - Test input validation rules
   - Verify error messages are helpful
   - Test boundary conditions

4. **Integration Tests**
   - Full deployment tests
   - Multi-resource interactions
   - End-to-end scenarios

### Test Execution

```bash
# Run all tests
cd test
go test -v -timeout 60m

# Run specific test
go test -v -run TestKeyVaultIntegration

# Run validation tests only (fast)
go test -v -run TestValidation
```

### Manual Testing Checklist

#### Phase 1
- [ ] Deploy with default settings
- [ ] Deploy with deletion protection disabled
- [ ] Deploy with custom disk size
- [ ] Deploy with custom tags
- [ ] Verify terraform fmt passes
- [ ] Verify terraform validate passes

#### Phase 2
- [ ] Deploy with restrictive NSG rules
- [ ] Deploy with Key Vault integration
- [ ] Deploy with mixed security features
- [ ] Test NSG rule priorities
- [ ] Verify secrets not in state
- [ ] Test Key Vault access failures

#### Phase 3
- [ ] Deploy without management public IP
- [ ] Deploy with additional interfaces
- [ ] Deploy with maximum interfaces
- [ ] Test VM size validation
- [ ] Verify NIC ordering

#### Phase 4
- [ ] Deploy with monitoring alerts
- [ ] Deploy with VM Insights
- [ ] Deploy with NSG flow logs
- [ ] Trigger test alerts
- [ ] Verify Log Analytics integration

### Automated CI/CD Testing

**File:** `.github/workflows/terraform-test.yml`
```yaml
name: Terraform Tests

on:
  pull_request:
    branches: [ main, feature/* ]
  push:
    branches: [ main ]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.3.4

      - name: Terraform Format Check
        run: terraform fmt -check -recursive

      - name: Terraform Init
        run: terraform init -backend=false

      - name: Terraform Validate
        run: terraform validate

  unit-test:
    runs-on: ubuntu-latest
    needs: validate
    steps:
      - uses: actions/checkout@v3

      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.19'

      - name: Run Unit Tests
        run: |
          cd test
          go test -v -run TestValidation

  integration-test:
    runs-on: ubuntu-latest
    needs: unit-test
    if: github.event_name == 'push'
    steps:
      - uses: actions/checkout@v3

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Run Integration Tests
        env:
          TF_VAR_client_secret: ${{ secrets.CLIENT_SECRET }}
        run: |
          cd test
          go test -v -timeout 60m
```

---

## Rollback Procedures

### General Rollback Strategy

1. **Identify Issue**: Determine which phase/feature is problematic
2. **Isolate**: Disable specific feature via variable
3. **Revert**: Roll back to previous version if needed
4. **Communicate**: Notify stakeholders

### Feature-Specific Rollbacks

#### Phase 1 Features

**Conditional Lifecycle**:
```hcl
# Rollback: Set to true to restore original behavior
enable_deletion_protection = true
```

**Enhanced Tagging**:
```hcl
# Rollback: Use empty map
additional_tags = {}
```

#### Phase 2 Features

**Restrictive NSG Rules**:
```hcl
# Rollback: Disable restrictive mode
enable_restrictive_mgmt_rules = false
```

**Key Vault Integration**:
```hcl
# Rollback: Disable Key Vault
use_key_vault_for_secrets = false
adminpassword = "original-password"
client_secret = "original-secret"
```

#### Phase 3 Features

**Optional Public IP**:
```hcl
# Rollback: Enable public IP
enable_mgmt_public_ip = true
```

**Additional Interfaces**:
```hcl
# Rollback: Remove additional interfaces
additional_interfaces = []
```

#### Phase 4 Features

**Monitoring**:
```hcl
# Rollback: Disable monitoring
enable_monitoring_alerts = false
enable_vm_insights = false
```

### Emergency Rollback

If critical issue discovered:

```bash
# Option 1: Revert to previous tag
git checkout v1.0.0
terraform init
terraform plan
terraform apply

# Option 2: Disable all new features
terraform apply \
  -var="enable_deletion_protection=true" \
  -var="enable_restrictive_mgmt_rules=false" \
  -var="use_key_vault_for_secrets=false" \
  -var="enable_monitoring_alerts=false"

# Option 3: Use previous module version
module "fortigate" {
  source  = "..."
  version = "1.0.0"  # Previous stable version
  # ...
}
```

---

## Success Metrics

### Phase 1 Success Criteria
- [ ] All tests pass (100%)
- [ ] Backward compatibility verified
- [ ] Documentation complete
- [ ] Code review approved
- [ ] No regression in existing functionality
- [ ] Performance impact < 5%

### Phase 2 Success Criteria
- [ ] Security scan passes (tfsec, checkov)
- [ ] Key Vault integration working
- [ ] NSG rules configurable
- [ ] Zero security vulnerabilities introduced
- [ ] Migration guide tested

### Phase 3 Success Criteria
- [ ] Additional interfaces functional
- [ ] VM size validation working
- [ ] Private deployment tested
- [ ] All edge cases handled

### Phase 4 Success Criteria
- [ ] Alerts firing correctly
- [ ] VM Insights collecting data
- [ ] Flow logs working
- [ ] Monitoring dashboards functional

### Overall Project Success Metrics
- **Code Quality**: 90%+ test coverage
- **Security**: Zero critical vulnerabilities
- **Documentation**: 100% coverage
- **Backward Compatibility**: Zero breaking changes
- **Performance**: No degradation
- **User Adoption**: Positive feedback from 80%+ users

---

## Risk Assessment

### Identified Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking changes | Low | High | Extensive testing, feature flags |
| State file issues | Low | High | Thorough validation, backup strategy |
| Security regressions | Medium | High | Security scanning, code review |
| Performance degradation | Low | Medium | Performance testing, monitoring |
| Documentation lag | Medium | Low | Documentation as part of DoD |
| Key Vault access issues | Medium | Medium | Clear error messages, troubleshooting guide |
| Test environment costs | High | Low | Use smallest VM sizes, auto-cleanup |

### Risk Mitigation Strategies

1. **Feature Flags**: All new features opt-in by default
2. **Extensive Testing**: 80%+ code coverage required
3. **Security Scanning**: Automated tools in CI/CD
4. **Code Review**: Mandatory review before merge
5. **Phased Rollout**: One phase at a time
6. **Documentation First**: Write docs before implementation
7. **Community Feedback**: Beta testing with select users

---

## Appendices

### Appendix A: File Change Summary

| Phase | Files Modified | Files Created | Lines Added | Lines Modified |
|-------|----------------|---------------|-------------|----------------|
| 0     | 0              | 3             | ~500        | 0              |
| 1     | 5              | 0             | ~800        | ~200           |
| 2     | 6              | 5             | ~1500       | ~300           |
| 3     | 5              | 4             | ~1200       | ~250           |
| 4     | 4              | 2             | ~1000       | ~150           |
| 5     | Multiple       | Multiple      | ~2000       | ~400           |
| **Total** | **20+**    | **14+**       | **~7000**   | **~1300**      |

### Appendix B: Dependency Matrix

```
Phase 0 (Setup)
  └─> Phase 1 (Foundation)
        ├─> Phase 2 (Security)
        │     └─> Phase 4 (Monitoring)
        │
        └─> Phase 3 (Flexibility)
              └─> Phase 4 (Monitoring)
                    └─> Phase 5 (Advanced) [Optional]
```

### Appendix C: Resource Links

- [Azure Terraform Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terratest Documentation](https://terratest.gruntwork.io/)
- [FortiGate Azure Guide](https://docs.fortinet.com/document/fortigate-public-cloud/7.6.0/azure-administration-guide/)
- [Azure Naming Conventions](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)

### Appendix D: Team Contacts

| Role | Name | Contact |
|------|------|---------|
| Project Lead | TBD | email@example.com |
| Developer 1 | TBD | email@example.com |
| Security Reviewer | TBD | email@example.com |
| QA Engineer | TBD | email@example.com |

### Appendix E: Change Log Template

```markdown
# CHANGELOG.md

## [2.0.0] - TBD

### Added
- Conditional lifecycle management (Phase 1)
- Enhanced input validation (Phase 1)
- Improved tagging strategy (Phase 1)
- Configurable disk settings (Phase 1)
- Configurable NSG rules (Phase 2)
- Azure Key Vault integration (Phase 2)
- Optional management public IP (Phase 3)
- Additional network interfaces support (Phase 3)
- Azure Monitor alerts (Phase 4)
- VM Insights integration (Phase 4)
- NSG flow logs (Phase 4)

### Changed
- Updated all resources to support conditional deletion protection
- Improved error messages for validation failures
- Enhanced documentation with examples

### Deprecated
- None

### Removed
- None

### Fixed
- None

### Security
- Added Key Vault support for secrets
- Improved NSG rule configuration
- Enhanced security documentation

## [1.0.0] - Current Version

### Initial Release
- FortiGate deployment with 4-port architecture
- HA support
- Multiple licensing options
- Comprehensive documentation
```

---

## Conclusion

This implementation plan provides a structured, phased approach to enhancing the Terraform Azure FortiGate module. Each phase builds upon the previous one while maintaining backward compatibility and minimizing risk.

**Key Success Factors:**
1. Feature flags ensure backward compatibility
2. Comprehensive testing at every phase
3. Thorough documentation alongside code
4. Phased approach allows for course correction
5. Clear rollback procedures minimize risk

**Next Steps:**
1. Review and approve this plan
2. Set up Phase 0 (Pre-Implementation)
3. Begin Phase 1 implementation
4. Schedule regular progress reviews

**Questions or Concerns:**
Contact the project team for clarification or adjustments to this plan.

---

**Document Version**: 1.0
**Last Updated**: [Current Date]
**Status**: Ready for Review
