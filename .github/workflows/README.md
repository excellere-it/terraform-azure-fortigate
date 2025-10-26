# GitHub Actions Workflows

This directory contains CI/CD workflows for the Terraform Azure FortiGate module.

## Workflows

### `test.yml` - Continuous Testing

**Triggers:**
- Pull requests to `main` or `develop` branches
- Pushes to `main` or `develop` branches
- Manual workflow dispatch
- Only when Terraform files (`**.tf`) or tests change

**Jobs:**

1. **terraform-format** - Validates Terraform formatting
   - Runs `terraform fmt -check -recursive`
   - Ensures code follows Terraform style guidelines

2. **terraform-validate** - Validates Terraform configuration
   - Runs `terraform init -backend=false`
   - Runs `terraform validate`
   - Checks configuration syntax and internal consistency

3. **terraform-test** - Runs unit tests (matrix strategy)
   - Runs each test file individually in parallel:
     - `tests/basic.tftest.hcl`
     - `tests/security.tftest.hcl`
     - `tests/advanced.tftest.hcl`
     - `tests/validation.tftest.hcl`
   - Uploads test results as artifacts (7-day retention)
   - Fails fast on any test failure

4. **terraform-test-all** - Runs all tests together
   - Executes `terraform test -verbose`
   - Generates test summary in job summary
   - Comments results on pull requests
   - Uploads complete test log (30-day retention)

5. **test-coverage-report** - Generates coverage summary
   - Documents test coverage in job summary
   - Lists all test files and coverage areas

6. **security-scan** - Security analysis
   - Runs Checkov security scanner
   - Identifies potential security issues
   - Uploads SARIF results (30-day retention)
   - Soft fail (informational only)

7. **lint** - Code quality checks
   - Runs TFLint for best practices
   - Checks for deprecated syntax and potential issues
   - Informational only (doesn't fail build)

8. **test-summary** - Overall test status
   - Aggregates results from all jobs
   - Creates comprehensive summary
   - Fails if any critical test fails

**Artifacts:**
- Test results from individual test files (7 days)
- Complete test log from all tests (30 days)
- Security scan results (30 days)

**PR Comments:**
Automatically comments test results on pull requests with summary and links to full logs.

### `release-module.yml` - Release Automation

**Triggers:**
- Git tags matching pattern `v*.*.*` (e.g., v1.0.0, v2.1.3)

**Jobs:**

1. **release** - Creates GitHub release
   - Verifies tag format (semantic versioning)
   - Generates release notes from git history
   - Compares with previous tag
   - Creates GitHub release with notes

2. **validate** - Pre-release validation
   - Runs `terraform fmt -check -recursive`
   - Runs `terraform init -backend=false`
   - Runs `terraform validate`
   - **Runs `terraform test -verbose`** (ensures all tests pass)
   - Generates Terraform documentation
   - Verifies documentation is up-to-date

**Release Creation:**
Only creates release if all validation and tests pass.

## Requirements

### Terraform Version
- Minimum: `1.6.0` (required for native testing framework)
- Specified in workflows: `~> 1.6.0`

### GitHub Permissions
- **test.yml**: Requires `contents: read` and `pull-requests: write`
- **release-module.yml**: Requires `contents: write`

### GitHub Secrets
- `GITHUB_TOKEN`: Automatically provided by GitHub Actions

## Local Testing

You can run the same tests locally:

```bash
# Format check
terraform fmt -check -recursive

# Validation
terraform init -backend=false
terraform validate

# Run all tests
terraform test -verbose

# Run specific test file
terraform test -filter=tests/basic.tftest.hcl -verbose

# Security scan (requires Checkov)
pip install checkov
checkov -d . --framework terraform

# Linting (requires TFLint)
tflint --init
tflint --recursive
```

## Workflow Status Badges

Add these badges to your main README.md:

```markdown
[![Terraform Tests](https://github.com/YOUR_ORG/terraform-azurerm-fortigate/actions/workflows/test.yml/badge.svg)](https://github.com/YOUR_ORG/terraform-azurerm-fortigate/actions/workflows/test.yml)
[![Release](https://github.com/YOUR_ORG/terraform-azurerm-fortigate/actions/workflows/release-module.yml/badge.svg)](https://github.com/YOUR_ORG/terraform-azurerm-fortigate/actions/workflows/release-module.yml)
```

## Workflow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Pull Request / Push                       │
│                   (main/develop branch)                      │
└─────────────────────┬───────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
        ▼             ▼             ▼
┌──────────────┐ ┌────────────┐ ┌────────────────────┐
│   Format     │ │  Validate  │ │   Unit Tests       │
│   Check      │ │            │ │  (4 test files)    │
└──────┬───────┘ └─────┬──────┘ └─────────┬──────────┘
       │               │                  │
       └───────────────┴──────────────────┤
                                          │
                                          ▼
                                ┌─────────────────────┐
                                │  All Tests Pass?    │
                                └──────────┬──────────┘
                                           │
                          ┌────────────────┴────────────────┐
                          │                                 │
                          ▼                                 ▼
                    ┌──────────┐                     ┌──────────┐
                    │   Pass   │                     │   Fail   │
                    │ ✅ Merge  │                     │ ❌ Block  │
                    └──────────┘                     └──────────┘
```

## Creating a Release

1. Ensure all tests pass on main branch
2. Create and push a semantic version tag:
   ```bash
   git tag v1.2.3
   git push origin v1.2.3
   ```
3. GitHub Actions will automatically:
   - Run all tests
   - Validate configuration
   - Create GitHub release with notes

## Troubleshooting

### Test Failures
- Check the "Summary" tab in GitHub Actions for test results
- Download test artifacts for detailed logs
- Run tests locally to reproduce: `terraform test -verbose`

### Format Failures
- Run `terraform fmt -recursive` to fix formatting
- Commit and push changes

### Validation Failures
- Check syntax errors in Terraform files
- Run `terraform validate` locally
- Ensure all required variables have defaults or validation rules

### Release Failures
- Verify tag format matches `v*.*.*` pattern
- Ensure all tests pass before tagging
- Check GitHub Actions logs for specific errors

## Maintenance

### Updating Terraform Version
Update the `terraform_version` in both workflows:
```yaml
terraform_version: "~> 1.6.0"  # Update this
```

### Adding New Test Files
New test files in `tests/*.tftest.hcl` are automatically picked up by `terraform test`.
To run them individually in the matrix, add to `test.yml`:
```yaml
matrix:
  test-file:
    - tests/basic.tftest.hcl
    - tests/security.tftest.hcl
    - tests/advanced.tftest.hcl
    - tests/validation.tftest.hcl
    - tests/your-new-test.tftest.hcl  # Add here
```

### Disabling Jobs
To temporarily disable a job, comment it out or add a condition:
```yaml
security-scan:
  if: false  # Disables this job
  name: Security Scan
  ...
```

## Best Practices

1. **Always run tests locally** before pushing
2. **Keep test files organized** by feature area
3. **Write meaningful commit messages** for better release notes
4. **Use semantic versioning** for releases (MAJOR.MINOR.PATCH)
5. **Review test results** in PR comments before merging
6. **Update documentation** when adding new features
7. **Monitor workflow execution times** and optimize if needed

## Contributing

When adding new workflows:
1. Follow existing naming conventions
2. Add comprehensive documentation
3. Test locally using `act` (GitHub Actions local runner)
4. Ensure minimal permissions required
5. Add appropriate artifacts and retention policies
6. Update this README with new workflow documentation
