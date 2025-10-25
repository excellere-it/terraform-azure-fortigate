# Changelog

All notable changes to the Terraform Azure FortiGate Module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
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
- Updated module from resource naming module to FortiGate deployment module
- Complete rewrite of documentation to reflect FortiGate functionality
- Updated examples to demonstrate FortiGate deployment scenarios
- Updated tests to validate FortiGate deployments

### Security
- Added lifecycle `prevent_destroy` rules for production safety
- Marked sensitive variables (passwords, secrets)
- Added validation for critical input variables
- Documented security best practices in README

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
