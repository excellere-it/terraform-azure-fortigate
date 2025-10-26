# Terraform Azure FortiGate Module - Test Suite

This directory contains comprehensive tests for the Terraform Azure FortiGate module using Terraform's native testing framework.

## Test Files

### `basic.tftest.hcl`
Tests basic FortiGate deployment functionality:
- VM creation with marketplace images
- 4 network interfaces (port1-port4)
- Management public IP creation
- NSG creation and configuration
- Data disk creation
- Default tagging
- Output values

### `security.tftest.hcl`
Tests security features:
- Private-only deployment (no management public IP)
- Dynamic NSG rules with CIDR restrictions
- NSG unrestricted fallback mode
- Azure Key Vault integration for secrets
- Structured and custom tagging

### `advanced.tftest.hcl`
Tests advanced features:
- Additional network interfaces (port5, port6)
- Azure Monitor diagnostics integration
- NSG flow logs
- High Availability (HA) configuration
- Custom disk configuration

### `validation.tftest.hcl`
Tests input validation rules:
- Zone values (1, 2, 3)
- License types (byol, payg)
- Architecture (x86, arm)
- Disk size and storage type validation
- Retention days validation
- CIDR notation validation
- Port number validation
- IP address format validation
- Subnet mask validation
- Tag format validation

## Prerequisites

- **Terraform** >= 1.6.0 (native testing support)
- **Azure Provider** >= 3.0.0
- **Azure CLI** authenticated (`az login`)
  - While tests use `command = plan` and don't create actual resources, the Azure provider requires authentication to validate subscriptions and permissions during plan phase

## Running Tests

All tests use `command = plan` which means:
- No actual Azure resources are created
- Tests validate configuration correctness
- Execution is fast (no API calls to create resources)
- No costs incurred

### Authenticate with Azure

Before running tests, authenticate with Azure CLI:

```bash
az login
```

Alternatively, you can use service principal authentication:

```bash
az login --service-principal \
  --username <app-id> \
  --password <password-or-cert> \
  --tenant <tenant-id>
```

### Run All Tests

```bash
# Run all test files
terraform test

# Run with verbose output
terraform test -verbose
```

### Run Specific Test File

```bash
# Run only basic tests
terraform test -filter=tests/basic.tftest.hcl

# Run only security tests
terraform test -filter=tests/security.tftest.hcl

# Run only advanced tests
terraform test -filter=tests/advanced.tftest.hcl

# Run only validation tests
terraform test -filter=tests/validation.tftest.hcl
```

### Run Specific Test Case

```bash
# Run specific test case within a file
terraform test -filter=tests/basic.tftest.hcl -run=verify_basic_deployment
```

## Test Coverage

The test suite covers:

### ✅ Core Functionality (basic.tftest.hcl)
- [x] VM creation and configuration
- [x] Network interface creation (port1-port4)
- [x] Management public IP creation
- [x] NSG creation (public and private)
- [x] Data disk creation and attachment
- [x] Automatic tagging
- [x] Output values

### ✅ Security Features (security.tftest.hcl)
- [x] Private-only deployment
- [x] Dynamic NSG rules based on CIDRs
- [x] Management access restrictions
- [x] Azure Key Vault integration
- [x] Structured tagging
- [x] Custom tagging
- [x] Tag merging and priority

### ✅ Advanced Features (advanced.tftest.hcl)
- [x] Optional network interfaces (port5, port6)
- [x] Conditional NIC creation
- [x] Azure Monitor diagnostics
- [x] NSG flow logs
- [x] Traffic Analytics integration
- [x] Custom disk configuration
- [x] HA configuration
- [x] Output values for optional features

### ✅ Input Validation (validation.tftest.hcl)
- [x] Zone validation (1, 2, 3)
- [x] License type validation (byol, payg)
- [x] Architecture validation (x86, arm)
- [x] Disk size range (1-32767 GB)
- [x] Storage type validation
- [x] Caching mode validation
- [x] Retention days validation (0-365)
- [x] CIDR notation validation
- [x] Port number range validation (1-65535)
- [x] IP address format validation
- [x] Subnet mask validation
- [x] Tag format validation

## Test Methodology

### Plan-Only Tests
All tests use `command = plan` which means:
- No actual Azure resources are created
- Tests validate configuration correctness
- Tests verify resource attributes and relationships
- Fast execution (no API calls to Azure)
- No costs incurred

### Assertions
Tests use assertions to verify:
- Resource creation/non-creation based on configuration
- Resource attributes match expected values
- Conditional logic works correctly
- Output values are correct
- Tags are properly applied

## Continuous Integration

### GitHub Actions Example

```yaml
name: Terraform Tests

on:
  pull_request:
    paths:
      - '**.tf'
      - 'tests/**'
  push:
    branches:
      - main

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.6.0

      - name: Terraform Init
        run: terraform init

      - name: Terraform Test
        run: terraform test -verbose
```

**Note**: Set up `AZURE_CREDENTIALS` secret in your repository with service principal credentials in this format:
```json
{
  "clientId": "<app-id>",
  "clientSecret": "<password>",
  "subscriptionId": "<subscription-id>",
  "tenantId": "<tenant-id>"
}
```

### Azure DevOps Example

```yaml
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - '*.tf'
      - 'tests/*'

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: AzureCLI@2
  inputs:
    azureSubscription: '<your-service-connection>'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      terraform init
      terraform test -verbose
```

## Adding New Tests

When adding new features to the module, follow these steps:

### 1. Identify Test Category
- **Basic**: Core deployment functionality
- **Security**: Access control, encryption, secrets
- **Advanced**: Optional features, integrations
- **Validation**: Input validation rules

### 2. Create Test Case

```hcl
run "verify_new_feature" {
  command = plan

  variables {
    # Override variables as needed
    new_feature_enabled = true
    new_feature_value   = "test-value"
  }

  # Add assertions
  assert {
    condition     = resource.type.name.attribute == "expected-value"
    error_message = "Feature should work as expected"
  }
}
```

### 3. Test Both Enabled and Disabled States

```hcl
run "verify_feature_enabled" {
  command = plan
  variables {
    feature_enabled = true
  }
  # Assertions for enabled state
}

run "verify_feature_disabled" {
  command = plan
  variables {
    feature_enabled = false
  }
  # Assertions for disabled state
}
```

### 4. Test Edge Cases

```hcl
run "verify_feature_with_null_values" {
  command = plan
  variables {
    optional_param = null
  }
  # Assertions for null handling
}

run "verify_feature_with_empty_values" {
  command = plan
  variables {
    optional_list = []
  }
  # Assertions for empty collection handling
}
```

## Troubleshooting

### Test Failures

**Error**: "No value for required variable"
```
Solution: Ensure all required variables are set in the variables block
```

**Error**: "Invalid for_each argument"
```
Solution: Check that conditional resources use proper count/for_each logic
```

**Error**: "Assertion failed"
```
Solution: Review the error_message in the assertion and verify expected vs actual values
```

### Debugging Tests

```bash
# Run tests with verbose output
terraform test -verbose

# Run specific test to isolate issue
terraform test -filter=tests/basic.tftest.hcl -run=verify_basic_deployment

# Use terraform console to inspect values
terraform console
> var.port1
> local.network_interface_ids
```

## Best Practices

1. **Keep tests isolated**: Each test should be independent
2. **Test both positive and negative cases**: Enable/disable features
3. **Test edge cases**: Null values, empty lists, boundary conditions
4. **Use descriptive names**: Test names should clearly indicate what is being tested
5. **Add meaningful error messages**: Help identify failures quickly
6. **Group related tests**: Use separate test files for different feature sets
7. **Document assumptions**: Add comments for complex test logic

## Contributing

When contributing tests:

1. Follow existing test patterns
2. Add tests for new features in appropriate test file
3. Ensure all tests pass before submitting PR
4. Update this README if adding new test files
5. Include test coverage for both success and failure scenarios

## Test Results

Example output from running tests:

```
tests/basic.tftest.hcl... pass
  run "verify_basic_deployment"... pass
  run "verify_default_tags"... pass
  run "verify_outputs"... pass

tests/security.tftest.hcl... pass
  run "verify_private_deployment"... pass
  run "verify_nsg_restrictions"... pass
  run "verify_key_vault_integration"... pass
  run "verify_structured_tags"... pass

tests/advanced.tftest.hcl... pass
  run "verify_additional_nics"... pass
  run "verify_monitoring_enabled"... pass
  run "verify_disk_configuration"... pass

tests/validation.tftest.hcl... pass
  run "validate_zone_values"... pass
  run "validate_license_type"... pass
  run "validate_disk_size_range"... pass

Success! 20 passed, 0 failed.
```

## References

- [Terraform Testing Documentation](https://developer.hashicorp.com/terraform/language/tests)
- [Terraform Test Command](https://developer.hashicorp.com/terraform/cli/commands/test)
- [Writing Effective Tests](https://developer.hashicorp.com/terraform/tutorials/configuration-language/test)
