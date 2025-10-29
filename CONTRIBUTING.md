# Contributing to terraform-azurerm-fortigate

Thank you for your interest in contributing to the terraform-azurerm-fortigate module! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Terraform** >= 1.13.4
- **Go** >= 1.19 (for testing)
- **Azure CLI** (for authentication)
- **terraform-docs** (for documentation generation)
- **make** (for build automation)

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/terraform-azurerm-fortigate.git
   cd terraform-azurerm-fortigate
   ```
3. Add the upstream repository:
   ```bash
   git remote add upstream https://github.com/ORIGINAL-OWNER/terraform-azurerm-fortigate.git
   ```

## Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

Use descriptive branch names:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `test/` - Test additions or modifications

### 2. Make Your Changes

- Write clear, concise commit messages
- Follow the existing code style
- Add tests for new functionality
- Update documentation as needed

### 3. Test Your Changes

Run the full test suite before submitting:

```bash
# Format code
make fmt

# Validate Terraform
make validate

# Generate documentation
make docs

# Run tests
make test
```

### 4. Commit Your Changes

```bash
git add .
git commit -m "feat: add support for ARM64 architecture"
```

Follow [Conventional Commits](https://www.conventionalcommits.org/) format:
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `test:` - Test updates
- `chore:` - Maintenance tasks
- `refactor:` - Code refactoring

### 5. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

## Pull Request Process

### Before Submitting

1. **Sync with upstream**:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Run pre-commit checks**:
   ```bash
   make pre-commit
   ```

3. **Update documentation**:
   - Update README.md if adding features
   - Update CHANGELOG.md with your changes
   - Ensure terraform-docs is up to date

### Submitting the PR

1. Create a pull request from your fork to the main repository
2. Fill out the PR template completely
3. Link any related issues
4. Request review from maintainers

### PR Title Format

Use clear, descriptive titles following Conventional Commits:

```
feat: add support for custom DNS configuration
fix: resolve issue with HA sync configuration
docs: improve bootstrap configuration examples
```

### PR Description

Include in your PR description:
- **What**: Brief description of changes
- **Why**: Reason for the changes
- **How**: Implementation approach
- **Testing**: How you tested the changes
- **Screenshots**: If applicable

### Review Process

- Maintainers will review your PR within 1-2 weeks
- Address feedback and requested changes
- Once approved, a maintainer will merge your PR

## Coding Standards

### Terraform Style

- Follow [HashiCorp Terraform Style Guide](https://www.terraform.io/docs/language/syntax/style.html)
- Use `terraform fmt` to format code
- Use meaningful variable and resource names
- Add descriptions to all variables and outputs
- Group related resources with comments

### File Organization

```
.
├── main.tf              # Primary resources
├── variables.tf         # Input variables
├── outputs.tf           # Module outputs
├── versions.tf          # Provider requirements
├── *.tf                 # Additional resource files
├── examples/            # Usage examples
│   └── default/         # Example configurations
├── test/                # Automated tests
└── docs/                # Additional documentation
```

### Comments and Documentation

- Add inline comments for complex logic
- Use section headers to organize resources
- Document all variables with clear descriptions
- Include examples in documentation

### Example Code Style

```hcl
# =============================================================================
# NETWORK INTERFACES
# =============================================================================

# Port1 - HA Management Interface
# Used for FortiGate administrative access
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
  }

  tags = var.tags
}
```

## Testing

### Unit Tests

Tests are written using [Terratest](https://terratest.gruntwork.io/):

```bash
# Run validation tests only (fast)
make test

# Run full integration tests (requires Azure)
make test-full
```

### Manual Testing

When adding new features:

1. Test in a development Azure environment
2. Document test scenarios
3. Verify cleanup (`terraform destroy`) works

### Test Requirements

- All new features must include tests
- Tests should be idempotent
- Tests must clean up resources properly
- Use data sources instead of hardcoded values

## Documentation

### Update README.md

- Add new features to the features list
- Update usage examples if needed
- Add troubleshooting entries for common issues

### Generate Terraform Docs

Documentation is auto-generated using terraform-docs:

```bash
make docs
```

This updates the `<!-- BEGIN_TF_DOCS -->` section in README.md.

### Add Examples

For significant features, add a new example:

1. Create directory: `examples/your-example/`
2. Add `main.tf`, `variables.tf`, `outputs.tf`
3. Document the example in README.md

## Questions?

If you have questions:
- Check existing issues and discussions
- Create a new issue for bugs
- Start a discussion for feature requests
- Contact maintainers for guidance

Thank you for contributing! 🎉
