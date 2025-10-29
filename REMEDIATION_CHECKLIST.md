# FortiGate Module Remediation Checklist

**Quick Reference Guide for Development Team**

**Status**: 🔴 In Progress
**Current Score**: 62/100
**Target Score**: 95/100

---

## Phase 1: Critical Issues ⏰ IMMEDIATE (8 hours)

### CRITICAL-1: Hardcoded Default Password ✅/❌

**Files to Modify**: `locals.tf`, `variables.tf`, `README.md`, `CHANGELOG.md`, `tests/`

- [ ] **Step 1**: Edit `locals.tf` line 12-14
  - Remove: `var.adminpassword != null ? var.adminpassword : "ChangeMe123!"`
  - Replace: `var.adminpassword`

- [ ] **Step 2**: Update `adminpassword` variable in `variables.tf`
  - Add: Password complexity validation (12+ chars, mixed case, numbers, special)
  - Add: Require password OR Key Vault validation

- [ ] **Step 3**: Create `tests/password-validation.tftest.hcl`
  - Test: Password required
  - Test: Weak password rejected
  - Test: Strong password accepted

- [ ] **Step 4**: Update `README.md`
  - Add: Security warning section
  - Add: Password requirements
  - Add: Key Vault example

- [ ] **Step 5**: Update `CHANGELOG.md`
  - Add: Breaking change notice
  - Add: Migration guide

- [ ] **Step 6**: Update `examples/default/main.tf`
  - Use: Key Vault for passwords

**Verify**:
```bash
terraform validate
terraform test -filter=tests/password-validation.tftest.hcl
grep -r "ChangeMe123" .  # Should return 0 results
```

---

### CRITICAL-2: Password Authentication ✅/❌

**Files to Modify**: `variables.tf`, `README.md`, `examples/`, `tests/validation.tftest.hcl`

- [ ] **Step 1**: Update `enable_management_access_restriction` in `variables.tf`
  - Change: Default stays `true`
  - Add: Validation requiring `true`

- [ ] **Step 2**: Update `management_access_cidrs` in `variables.tf`
  - Add: Validation requiring non-empty list
  - Add: Validation rejecting `0.0.0.0/0`
  - Add: CIDR format validation

- [ ] **Step 3**: Add security documentation to `README.md`
  - Add: "Security Considerations" section
  - Add: Password authentication explanation
  - Add: Mitigation strategies
  - Add: Defense in depth diagram

- [ ] **Step 4**: Update `examples/default/main.tf`
  - Set: `management_access_cidrs = ["10.0.0.0/8"]`
  - Set: `create_management_public_ip = false`

- [ ] **Step 5**: Add validation tests
  - Test: Management restriction required
  - Test: CIDRs required
  - Test: 0.0.0.0/0 rejected

**Verify**:
```bash
terraform validate
terraform test -filter=tests/validation.tftest.hcl -verbose
```

---

### CRITICAL-3: Overly Permissive NSG Rules ✅/❌

**Files to Modify**: `network.tf`, `tests/security.tftest.hcl`, `CHANGELOG.md`

- [ ] **Step 1**: Delete unrestricted rule from `network.tf` (lines 80-94)
  - Remove: Entire `management_access_unrestricted` resource

- [ ] **Step 2**: Add default deny rules to `network.tf` (after line 95)
  - Add: `deny_all_inbound_public` at priority 4096
  - Add: `deny_all_inbound_private` at priority 4096

- [ ] **Step 3**: Update management access rules (lines 65-78)
  - Convert to: Dynamic for_each loop with locals
  - Use: `management_access_cidrs` (now required)

- [ ] **Step 4**: Add NSG tests to `tests/security.tftest.hcl`
  - Test: Default deny rules exist
  - Test: No unrestricted allow rules

- [ ] **Step 5**: Update `CHANGELOG.md`
  - Add: Breaking change notice

**Verify**:
```bash
terraform plan | grep "deny_all_inbound"  # Should show 2 resources
terraform plan | grep "management_access_unrestricted"  # Should show 0 resources
terraform test -filter=tests/security.tftest.hcl
```

---

## Phase 2: High Severity Issues 🟠 HIGH PRIORITY (16 hours)

### HIGH-1: Disk Encryption ✅/❌

**Files to Modify**: `variables.tf`, `compute.tf`, `examples/disk-encryption/`, `README.md`

- [ ] **Step 1**: Add encryption variables to `variables.tf`
  - Add: `enable_encryption_at_host` (default: true)
  - Add: `disk_encryption_set_id` (default: null)
  - Add: `os_disk_storage_type` (default: "Premium_LRS")

- [ ] **Step 2**: Update VM resources in `compute.tf`
  - Add: `encryption_at_host_enabled = var.enable_encryption_at_host`
  - Add: `os_disk.disk_encryption_set_id = var.disk_encryption_set_id`
  - Change: `storage_account_type = var.os_disk_storage_type`

- [ ] **Step 3**: Update data disk in `compute.tf`
  - Add: `disk_encryption_set_id = var.disk_encryption_set_id`

- [ ] **Step 4**: Create `examples/disk-encryption/main.tf`
  - Include: Key Vault, Key, Disk Encryption Set
  - Include: FortiGate with encryption enabled

- [ ] **Step 5**: Add encryption docs to `README.md`
  - Add: Encryption at Host section
  - Add: Customer-Managed Keys section
  - Add: Requirements and benefits

**Verify**:
```bash
cd examples/disk-encryption
terraform init
terraform plan
cd ../..
terraform test -filter=tests/validation.tftest.hcl
```

---

### HIGH-2: Managed Identity ✅/❌

**Files to Modify**: `variables.tf`, `compute.tf`, `locals.tf`, `config-*.conf`, `examples/managed-identity/`, `outputs.tf`

- [ ] **Step 1**: Add identity variables to `variables.tf`
  - Add: `user_assigned_identity_id` (default: null)
  - Add: `enable_system_assigned_identity` (default: false)

- [ ] **Step 2**: Update VM resources in `compute.tf`
  - Add: `identity` block supporting UserAssigned/SystemAssigned/Both

- [ ] **Step 3**: Update `locals.tf`
  - Add: `use_managed_identity` local
  - Update: `resolved_client_secret` to check managed identity
  - Update: `bootstrap_vars` to include `use_managed_identity`

- [ ] **Step 4**: Update bootstrap templates (`config-active.conf`, `config-passive.conf`)
  - Add: Conditional logic for managed identity vs service principal
  - Add: `use-metadata-iam enable` when using managed identity

- [ ] **Step 5**: Create `examples/managed-identity/main.tf`
  - Include: User-assigned identity resource
  - Include: Role assignments (Reader, Network Contributor)
  - Include: FortiGate with identity

- [ ] **Step 6**: Add identity outputs to `outputs.tf`
  - Add: `system_assigned_identity_principal_id`
  - Add: `user_assigned_identity_id`

**Verify**:
```bash
cd examples/managed-identity
terraform init
terraform plan
cd ../..
terraform test -filter=tests/advanced.tftest.hcl
```

---

### HIGH-3: Public Management IP ✅/❌

**Files to Modify**: `variables.tf`, `README.md`, `examples/`

- [ ] **Step 1**: Update `create_management_public_ip` in `variables.tf`
  - Change: Default from `true` to `false`
  - Add: Validation preventing public IP when `environment = "prd"`

- [ ] **Step 2**: Update `README.md`
  - Add: Private-only deployment section
  - Add: Access methods (Bastion, VPN, ExpressRoute)

- [ ] **Step 3**: Update all examples
  - Set: `create_management_public_ip = false`

**Verify**:
```bash
terraform validate
grep -r "create_management_public_ip.*true" examples/  # Should return 0
```

---

### HIGH-4: Data Disk Encryption ✅/❌

**Completed in HIGH-1** - Data disk encryption added alongside OS disk encryption

- [x] Added `disk_encryption_set_id` to data disk resource

---

### HIGH-5: TLS Enforcement ✅/❌

**Files to Modify**: `variables.tf`, `config-active.conf`, `config-passive.conf`, `README.md`

- [ ] **Step 1**: Add TLS variable to `variables.tf`
  - Add: `min_tls_version` (default: "1.2", validation: ["1.2", "1.3"])

- [ ] **Step 2**: Update bootstrap templates
  - Add: `set admin-https-ssl-versions tlsv1-2 tlsv1-3`
  - Add: `set strong-crypto enable`

- [ ] **Step 3**: Update `README.md`
  - Add: TLS hardening section

**Verify**:
```bash
grep "admin-https-ssl-versions" config-active.conf
grep "strong-crypto" config-active.conf
```

---

## Phase 3: Medium Severity Issues 🟡 RECOMMENDED (12 hours)

### MEDIUM-1: Boot Diagnostics Validation ✅/❌

- [ ] Add HTTPS validation to `boot_diagnostics_storage_endpoint` variable
- [ ] Add security requirements documentation

### MEDIUM-2: NSG Flow Logs Retention ✅/❌

- [ ] Add minimum retention validation (7 days) to `nsg_flow_logs_retention_days`

### MEDIUM-3: Private Link Service ✅/❌

- [ ] Design Private Link Service integration
- [ ] Add variables for Private Link
- [ ] Update documentation

### MEDIUM-4: Accelerated Networking Validation ✅/❌

- [ ] Add VM size validation to ensure accelerated networking support

---

## Phase 4: Low Severity Enhancements 🟢 OPTIONAL (8 hours)

### LOW-1: Azure Policy Integration ✅/❌

- [ ] Add Azure Policy assignment support

### LOW-2: DDoS Protection Plan ✅/❌

- [ ] Add `ddos_protection_plan_id` variable
- [ ] Update public IP resources

---

## Testing Checklist

### Pre-Commit Checks
```bash
# Run before every commit
make fmt                    # Format code
make validate              # Validate syntax
make test                  # Run all tests
git status                 # Check changes
```

### Phase 1 Testing
```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test -verbose
grep -r "ChangeMe123" .    # Should be 0
grep -r "0.0.0.0/0.*Allow" network.tf  # Should be 0
```

### Phase 2 Testing
```bash
cd examples/disk-encryption && terraform init && terraform plan && cd ../..
cd examples/managed-identity && terraform init && terraform plan && cd ../..
terraform test -filter=tests/advanced.tftest.hcl -verbose
```

### Security Validation
```bash
# Optional security scanning
checkov -d . --framework terraform
tfsec .
terraform-compliance -f security-policy/ -p plan.json
```

---

## Git Workflow

### Branch Naming
```bash
git checkout -b remediation/critical-issues  # Phase 1
git checkout -b remediation/high-severity    # Phase 2
git checkout -b remediation/medium-severity  # Phase 3
```

### Commit Messages
```
fix(security): remove hardcoded default password (CRITICAL-1)

- Remove "ChangeMe123!" fallback from locals.tf
- Add password complexity validation
- Require Key Vault or explicit password
- Add 3 password validation tests

BREAKING CHANGE: Users must provide adminpassword or key_vault_id
```

### Pull Request Checklist
- [ ] All tests passing
- [ ] terraform fmt clean
- [ ] terraform validate passing
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Examples updated
- [ ] Security review conducted

---

## Documentation Checklist

### Files to Update for Every Issue
- [ ] `README.md` - Usage documentation
- [ ] `CHANGELOG.md` - Version history
- [ ] `SECURITY_REVIEW.md` - Update status
- [ ] `REMEDIATION_PLAN.md` - Mark completed
- [ ] Examples in `examples/` directory
- [ ] Tests in `tests/` directory

---

## Completion Checklist

### Phase 1 Complete ✅/❌
- [ ] All 3 critical issues resolved
- [ ] 5 new tests passing
- [ ] Documentation updated
- [ ] Examples updated
- [ ] CHANGELOG.md updated
- [ ] Security score ≥ 72/100
- [ ] Git tag: `v0.0.2` created

### Phase 2 Complete ✅/❌
- [ ] All 5 high issues resolved
- [ ] 2 new examples created
- [ ] 5+ new tests passing
- [ ] Documentation updated
- [ ] Security score ≥ 85/100
- [ ] PCI-DSS compliant
- [ ] HIPAA compliant
- [ ] Git tag: `v0.0.3` or `v0.1.0` created

### Phase 3 Complete ✅/❌
- [ ] All 4 medium issues resolved
- [ ] Security score ≥ 92/100
- [ ] Git tag: `v0.1.1` created

### Phase 4 Complete ✅/❌
- [ ] All 2 low issues resolved
- [ ] Security score ≥ 95/100
- [ ] Production-ready certification
- [ ] Git tag: `v0.2.0` created

---

## Quick Commands Reference

```bash
# Development
make help                  # Show all commands
make dev                   # Full dev workflow
make check                 # Quick validation

# Testing
terraform test             # All tests
terraform test -verbose    # Verbose output
terraform test -filter=tests/basic.tftest.hcl  # Specific test

# Formatting
terraform fmt -recursive   # Format all files
terraform fmt -check       # Check formatting only

# Validation
terraform init -backend=false
terraform validate

# Documentation
make docs                  # Generate README (if terraform-docs installed)

# Git
git status
git add .
git commit -m "..."
git push

# Release
git tag -a v0.0.2 -m "Release notes"
git push origin v0.0.2
```

---

## Contact Information

**Questions?**
- Primary Contact: [Your Name] - [Email]
- Security Lead: [Name] - [Email]
- Terraform Channel: [Slack/Teams]

**Resources**:
- Detailed Plan: `REMEDIATION_PLAN.md`
- Executive Summary: `REMEDIATION_EXECUTIVE_SUMMARY.md`
- Security Review: `SECURITY_REVIEW.md`
- Module Docs: `README.md`

---

**Last Updated**: 2025-10-29
**Next Review**: After Phase 1 completion
**Document Version**: 1.0
