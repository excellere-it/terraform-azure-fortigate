# Changelog

All notable changes to the Terraform Azure FortiGate Module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
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

### Changed
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

### Removed
- **BREAKING**: `name` variable (replaced by automatic naming from terraform-namer)
- **BREAKING**: `computer_name` variable (replaced by automatic naming from terraform-namer)
- **BREAKING**: `cost_center` variable (use `tags = { CostCenter = "value" }` instead)
- **BREAKING**: `owner` variable (use `tags = { Owner = "value" }` instead)
- **BREAKING**: `project` variable (use `tags = { Project = "value" }` instead)
- **BREAKING**: `custom_image_name` variable (now automatically generated from terraform-namer)

### Security
- Added lifecycle `prevent_destroy` rules for production safety
- Marked sensitive variables (passwords, secrets)
- Added validation for critical input variables
- Documented security best practices in README

### Migration Guide
If upgrading from a previous version:
1. **Add terraform-namer variables** to your module call:
   ```hcl
   contact     = "ops@example.com"
   environment = "prd"          # dev, stg, prd, sbx, tst, ops, hub
   location    = "centralus"
   repository  = "terraform-azurerm-fortigate"
   workload    = "firewall"
   ```
2. **Remove deprecated variables**: `name`, `computer_name`, `cost_center`, `owner`, `project`, `custom_image_name`
3. **Migrate custom tags**: Move `cost_center`, `owner`, `project` values to the `tags` map:
   ```hcl
   tags = {
     CostCenter = "IT-001"
     Owner      = "security-team@example.com"
     Project    = "network-security"
   }
   ```
4. **Note**: Resource names will change due to new naming convention - this will cause resource replacement. Plan carefully!
5. Review the example in `examples/default/main.tf` for complete updated usage

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
