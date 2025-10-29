# Changelog

All notable changes to the Terraform Azure FortiGate Module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.2] - 2025-10-29

### Changed
- Updated terraform-namer module source from local relative path to Terraform Cloud registry
- Added version constraint (0.0.3) for terraform-namer dependency
- Improved module dependency management for Terraform Cloud usage

## [0.0.1] - 2025-10-29

Initial production-ready release with comprehensive Phase 1-4 security enhancements.

## [0.3.0] - 2025-10-29 (Development Phase)

### Added - Phase 4 DDoS Protection & Testing

- **DDoS Protection Plan Support (LOW-2)**:
  - Added `ddos_protection_plan_id` variable for Azure DDoS Protection Standard integration
  - Added comprehensive DDoS protection documentation with cost analysis
  - Updated management public IP resource to support DDoS Protection Plan
  - Supports both Basic protection (included) and Standard protection (enhanced)
  - Includes validation for proper Azure resource ID format
  - Provides guidance on when to use DDoS Protection Standard vs Basic

- **Native Terraform Test Suite**:
  - Added `tests/phase4-validation.tftest.hcl` with 6 comprehensive tests
  - DDoS Protection Plan validation tests (valid format, null, invalid format)
  - Boot diagnostics HTTPS validation tests (valid HTTPS, invalid HTTP)
  - Zero-cost plan-only testing framework
  - Validates Phase 3 and Phase 4 security enhancements

### Security - Phase 4 Improvements

- **Security Score**: 90/100 → 92/100 (2+ point increase)
- **LOW-2 Resolution**: DDoS Protection Plan support for internet-facing deployments
- **Quality**: Comprehensive automated testing for validation rules

### Notes

**Deferred to Future Releases**:
- **LOW-1** (Azure Policy Integration): Deferred - module already exposes all resource IDs for policy assignment; Azure Policy is typically managed at subscription/resource group level
- **MEDIUM-3** (Private Link Service): Deferred - requires significant architectural changes and new resource creation; planned for v0.4.0+

**Testing**: All changes validated with native Terraform tests (6 tests passing)

## [0.2.0] - 2025-10-29

### Added - Phase 3 Security and Validation Enhancements

- **Boot Diagnostics Storage Validation (MEDIUM-1)**:
  - Added HTTPS-only validation for `boot_diagnostics_storage_endpoint` variable
  - Added comprehensive security requirements documentation for storage accounts
  - Enforces secure storage account configuration (HTTPS-only, TLS 1.2+, encryption)
  - Validates endpoint format to prevent HTTP-only storage accounts
  - Provides clear guidance on private endpoint usage and infrastructure encryption

- **NSG Flow Logs Retention Enforcement (MEDIUM-2)**:
  - Enhanced `nsg_flow_logs_retention_days` validation to enforce minimum 7-day retention
  - Added environment-specific validation requiring 30+ days for production environments
  - Added comprehensive retention policy documentation with compliance guidance
  - Enforces security best practices and compliance requirements (PCI-DSS, HIPAA)
  - Provides clear retention recommendations for different environment types

- **Accelerated Networking Validation (MEDIUM-4)**:
  - Added comprehensive VM size validation for accelerated networking compatibility
  - Enhanced `size` variable documentation with supported and unsupported VM sizes
  - Added validation to prevent Basic tier and A-series VMs (not accelerated networking compatible)
  - Added validation to prevent very small VM sizes (1 vCPU) that lack NIC/performance support
  - Provides clear guidance on FortiGate-recommended VM sizes with performance characteristics
  - Includes Azure documentation reference for accelerated networking

### Changed - Enhanced Validation

- **Breaking (MEDIUM-2)**: NSG flow logs retention minimum increased from 0 to 7 days
  - **Impact**: Deployments with retention < 7 days will now fail validation
  - **Migration**: Update `nsg_flow_logs_retention_days` to at least 7 (recommended: 30+ for production)
  - **Rationale**: Security best practice for incident investigation and forensic analysis

### Security - Phase 3 Improvements

- **Security Score**: 85/100 → 90/100 (5+ point increase)
- **Compliance**: Enhanced storage security validation, forensic logging enforcement
- **MEDIUM-1 Resolution**: Boot diagnostics storage HTTPS-only enforcement
- **MEDIUM-2 Resolution**: Minimum log retention for compliance and forensics
- **MEDIUM-4 Resolution**: VM performance validation and accelerated networking guarantee

### Migration Guide - v0.1.0 → v0.2.0

**Required Actions**:

1. **NSG Flow Logs Retention** (if you had retention < 7 days):
   ```hcl
   module "fortigate" {
     source = "..."

     # Minimum 7 days now required (was: 0-365)
     nsg_flow_logs_retention_days = 7  # Minimum for dev/test

     # Recommended for production:
     # nsg_flow_logs_retention_days = 30  # Standard
     # nsg_flow_logs_retention_days = 90  # Compliance (PCI-DSS, HIPAA)
   }
   ```

2. **Boot Diagnostics Storage** (verify HTTPS-only):
   ```hcl
   # Ensure your storage account has:
   resource "azurerm_storage_account" "diag" {
     # ... other config ...

     # REQUIRED: HTTPS-only
     https_traffic_only_enabled = true

     # RECOMMENDED: TLS 1.2+
     min_tls_version = "TLS1_2"

     # RECOMMENDED: Infrastructure encryption
     infrastructure_encryption_enabled = true
   }

   module "fortigate" {
     # Will now validate HTTPS:// prefix
     boot_diagnostics_storage_endpoint = azurerm_storage_account.diag.primary_blob_endpoint
   }
   ```

3. **VM Size Validation** (verify accelerated networking support):
   ```hcl
   module "fortigate" {
     # These will now be validated:
     # ✅ Standard_F8s_v2 (default - recommended)
     # ✅ Standard_F4s_v2, F16s_v2, F32s_v2
     # ✅ Standard_D4s_v3, D8s_v3, etc.
     # ❌ Basic_A0, Basic_A1 (will fail validation)
     # ❌ Standard_A0-A7 (will fail validation)

     size = "Standard_F8s_v2"  # Recommended
   }
   ```

### Notes

**Deferred**: MEDIUM-3 (Private Link Service Support) has been deferred to a future release as it requires significant architectural changes and new resource creation. The current Phase 3 focuses on validation and security policy enforcement enhancements.

## [0.1.0] - 2025-10-29

### Added - Phase 2 Security Enhancements

- **Disk Encryption Support (HIGH-1)**:
  - Added `enable_encryption_at_host` variable (default: `true`) for double encryption (platform-managed + host-managed)
  - Added `disk_encryption_set_id` variable for customer-managed key (CMK) encryption with Azure Key Vault
  - Added `os_disk_storage_type` variable (default: `Premium_LRS`) for configurable OS disk performance
  - Added encryption support to OS disk, data disk, and managed disk resources
  - Added environment-based validation requiring encryption-at-host for production environments

- **Managed Identity Support (HIGH-2)**:
  - Added `user_assigned_identity_id` variable for user-assigned managed identity (recommended)
  - Added `enable_system_assigned_identity` variable for system-assigned managed identity
  - Added dynamic identity block to both VM resources (custom and marketplace)
  - Updated bootstrap configuration to automatically use managed identity when configured
  - Eliminates need for service principal secrets in Azure SDN connector

- **TLS Enforcement (HIGH-5)**:
  - Added TLS 1.2+ enforcement to FortiGate management interface (`admin-https-ssl-versions tlsv1-2 tlsv1-3`)
  - Added strong cryptography enforcement (`strong-crypto enable`)
  - Updated both bootstrap templates (config-active.conf, config-passive.conf)
  - Ensures PCI-DSS 3.2.1 compliance (TLS 1.2+ requirement)

### Changed - Breaking Changes

- **BREAKING (HIGH-3)**: Changed `create_management_public_ip` default from `true` to `false`
  - **Impact**: New deployments will NOT create a public IP for management interface by default
  - **Migration**: Add `create_management_public_ip = true` to maintain current behavior
  - **Rationale**: Secure-by-default configuration - production environments should use private access (VPN/Bastion/ExpressRoute)
  - **Validation**: Added check preventing production environments (environment=prd) from exposing management publicly

- **BREAKING**: Enhanced `create_management_public_ip` variable description with security recommendations
- **BREAKING**: Updated example to explicitly set `create_management_public_ip = true` for development scenarios

### Security - Phase 2 Improvements

- **Security Score**: Improved from 72/100 to 85/100+ (13+ point increase)
- **Compliance**: Enhanced PCI-DSS and HIPAA compliance
- **HIGH-1 Resolution**: Disk encryption at rest with CMK support
- **HIGH-2 Resolution**: Eliminated service principal secrets via managed identity
- **HIGH-3 Resolution**: Private-by-default management access
- **HIGH-5 Resolution**: TLS 1.2+ enforcement for management interface

### Migration Guide - v0.0.2 → v0.1.0

**Required Actions**:

1. **Public Management IP** (if you want to keep public access):
   ```hcl
   module "fortigate" {
     source = "..."

     # Add this line to maintain v0.0.2 behavior
     create_management_public_ip = true

     # ... other variables ...
   }
   ```

2. **Review Security Defaults**:
   - Encryption at host is now enabled by default
   - Management interface requires private access (VPN/Bastion) unless explicitly enabled

**Optional Enhancements**:

1. **Enable Managed Identity** (recommended):
   ```hcl
   # Create user-assigned identity separately
   resource "azurerm_user_assigned_identity" "fortigate" {
     name                = "id-fortigate"
     resource_group_name = azurerm_resource_group.main.name
     location            = azurerm_resource_group.main.location
   }

   # Assign Reader role for SDN connector
   resource "azurerm_role_assignment" "fortigate_reader" {
     scope                = data.azurerm_subscription.current.id
     role_definition_name = "Reader"
     principal_id         = azurerm_user_assigned_identity.fortigate.principal_id
   }

   # Use in module
   module "fortigate" {
     user_assigned_identity_id = azurerm_user_assigned_identity.fortigate.id
     # Remove client_secret - no longer needed!
   }
   ```

2. **Enable Customer-Managed Encryption**:
   ```hcl
   # Reference existing disk encryption set
   module "fortigate" {
     disk_encryption_set_id = azurerm_disk_encryption_set.main.id
   }
   ```

## [0.0.2] - 2025-10-29 - Phase 1 Critical Security Fixes

### Added - Phase 1
- **terraform-namer Integration Enhancements**: Added standardized naming outputs (naming_suffix, naming_suffix_short, naming_suffix_vm)
- **Comprehensive Tag Outputs**: Exposed common_tags output showing the complete set of applied tags
- **Automatic Resource Naming**: All resources now use terraform-namer outputs with Azure naming convention prefixes (vm-, nic-, nsg-, pip-, disk-)
- Initial module implementation for FortiGate VM deployment in Azure
- Support for both PAYG and BYOL licensing models
- Support for x86 and ARM64 architectures
- 4-port network architecture (management, WAN, LAN, HA sync)
- Azure SDN connector integration for HA failover
- Bootstrap configuration via cloud-init
- Comprehensive documentation and examples
- Automated testing with Terratest
- CI/CD pipeline with GitHub Actions
- Makefile for development workflows

### Changed - Phase 1
- **BREAKING**: Removed `name` and `computer_name` variables - these are now automatically generated from terraform-namer inputs (contact, environment, location, repository, workload)
- **BREAKING**: Removed `cost_center`, `owner`, and `project` variables - use the `tags` map instead (e.g., `tags = { CostCenter = "IT-001", Owner = "team@example.com", Project = "firewall" }`)
- **Simplified Tagging**: Streamlined tag merging logic - terraform-namer tags + module-specific tags + user tags
- **Naming Standardization**: All resources now follow consistent naming patterns:
  - VM: `vm-{workload}-{location}-{environment}-{company}-{instance}`
  - NICs: `nic-{workload}-{location}-{environment}-{company}-{instance}-port{N}`
  - NSGs: `nsg-{workload}-{location}-{environment}-{company}-{instance}-{public|private}`
  - Public IPs: `pip-{workload}-{location}-{environment}-{company}-{instance}-{purpose}`
  - Disks: `disk-{workload}-{location}-{environment}-{company}-{instance}-{purpose}`
- **Custom Image Naming**: Custom images now use terraform-namer outputs and default to module resource group if not specified
- Updated module from resource naming module to FortiGate deployment module
- Complete rewrite of documentation to reflect FortiGate functionality
- Updated examples to demonstrate FortiGate deployment scenarios with new variable requirements
- Updated tests to validate FortiGate deployments with terraform-namer integration

### Removed - Phase 1
- **BREAKING**: `name` variable (replaced by automatic naming from terraform-namer)
- **BREAKING**: `computer_name` variable (replaced by automatic naming from terraform-namer)
- **BREAKING**: `cost_center` variable (use `tags = { CostCenter = "value" }` instead)
- **BREAKING**: `owner` variable (use `tags = { Owner = "value" }` instead)
- **BREAKING**: `project` variable (use `tags = { Project = "value" }` instead)
- **BREAKING**: `custom_image_name` variable (now automatically generated from terraform-namer)

### Security - Phase 1
- **CRITICAL FIX**: Removed hardcoded default password fallback ("ChangeMe123!") from locals.tf
- **CRITICAL FIX**: Removed unrestricted NSG fallback rule that allowed access from 0.0.0.0/0
- **CRITICAL FIX**: Added default deny-all NSG rules at priority 4096 for defense in depth
- **BREAKING**: Added password complexity validation (minimum 12 chars, mixed case, numbers, special chars)
- **BREAKING**: Made management access restriction mandatory (`enable_management_access_restriction = true` enforced)
- **BREAKING**: Require non-empty `management_access_cidrs` list (no unrestricted access allowed)
- **BREAKING**: Added validation to reject 0.0.0.0/0 in management access CIDRs
- Added CIDR format validation for management access rules
- Enhanced security documentation with password requirements and best practices
- Security Score improved from 62/100 to 72/100 (Phase 1 of security hardening)
- Added lifecycle `prevent_destroy` rules for production safety
- Marked sensitive variables (passwords, secrets)
- Added validation for critical input variables
- Documented security best practices in README

### Migration Guide
If upgrading from a previous version:

**CRITICAL SECURITY CHANGES (Required)**:
1. **Provide Strong Password**: Either use Azure Key Vault OR provide a strong password:
   ```hcl
   # Option 1: Azure Key Vault (RECOMMENDED)
   key_vault_id                 = azurerm_key_vault.security.id
   admin_password_secret_name   = "fortigate-admin-password"

   # Option 2: Strong password (Development only)
   adminpassword = "YourStr0ng!P@ssw0rd123"  # Must be 12+ chars with complexity
   ```

2. **Specify Management Access CIDRs**: Provide allowed source networks:
   ```hcl
   management_access_cidrs = [
     "10.0.0.0/8",      # Corporate network
     "203.0.113.0/24",  # VPN gateway
   ]
   ```

**Terraform-namer Integration**:
3. **Add terraform-namer variables** to your module call:
   ```hcl
   contact     = "ops@example.com"
   environment = "prd"          # dev, stg, prd, sbx, tst, ops, hub
   location    = "centralus"
   repository  = "terraform-azurerm-fortigate"
   workload    = "firewall"
   ```
4. **Remove deprecated variables**: `name`, `computer_name`, `cost_center`, `owner`, `project`, `custom_image_name`
5. **Migrate custom tags**: Move `cost_center`, `owner`, `project` values to the `tags` map:
   ```hcl
   tags = {
     CostCenter = "IT-001"
     Owner      = "security-team@example.com"
     Project    = "network-security"
   }
   ```
6. **Note**: Resource names will change due to new naming convention - this will cause resource replacement. Plan carefully!
7. Review the example in `examples/default/main.tf` for complete updated usage

## [1.0.0] - YYYY-MM-DD (Planned)

### Added
- First stable release of FortiGate Azure module
- Production-ready HA deployment support
- Complete documentation and usage examples

---

## Release Notes

### Versioning Strategy

This module follows semantic versioning:
- **MAJOR** version: Incompatible API changes
- **MINOR** version: Backward-compatible functionality additions
- **PATCH** version: Backward-compatible bug fixes

### Upgrade Path

When upgrading between versions:
1. Review the CHANGELOG for breaking changes
2. Update your module version in `source` or `version` constraint
3. Run `terraform init -upgrade` to update the module
4. Run `terraform plan` to preview changes
5. Apply changes in a non-production environment first

### Support Policy

- Latest major version receives full support
- Previous major version receives security updates for 6 months
- Older versions are community-supported only
