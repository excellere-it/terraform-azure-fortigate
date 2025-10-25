# =============================================================================
# TERRAFORM AZURE FORTIGATE MODULE - MAKEFILE
# =============================================================================
# This Makefile provides convenient commands for development, testing, and
# documentation of the FortiGate Azure Terraform module.

.DEFAULT_GOAL := help
.PHONY: help docs fmt tidy test validate deploy destroy clean

# Directories
TESTDIR := ./test
EXAMPLEDIR := ./examples/default

# Colors for output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

#------------------------------------------------------------------------------
# Help Target
#------------------------------------------------------------------------------

help: ## Display this help message
	@echo ""
	@echo "$(CYAN)Terraform Azure FortiGate Module - Available Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""

#------------------------------------------------------------------------------
# Documentation
#------------------------------------------------------------------------------

docs: ## Generate Terraform documentation using terraform-docs
	@echo "$(CYAN)Generating Terraform documentation...$(NC)"
	@terraform-docs markdown document --output-file README.md --output-mode inject .
	@echo "$(GREEN)✓ Documentation generated successfully$(NC)"

#------------------------------------------------------------------------------
# Formatting
#------------------------------------------------------------------------------

tffmt: ## Format all Terraform files
	@echo "$(CYAN)Formatting Terraform files...$(NC)"
	@terraform fmt -recursive
	@echo "$(GREEN)✓ Terraform files formatted$(NC)"

gofmt: ## Format all Go test files
	@echo "$(CYAN)Formatting Go test files...$(NC)"
	@cd $(TESTDIR) && go fmt
	@echo "$(GREEN)✓ Go files formatted$(NC)"

fmt: tffmt gofmt ## Format all Terraform and Go files

#------------------------------------------------------------------------------
# Dependencies
#------------------------------------------------------------------------------

tidy: ## Tidy Go module dependencies
	@echo "$(CYAN)Tidying Go dependencies...$(NC)"
	@cd $(TESTDIR) && go mod tidy
	@echo "$(GREEN)✓ Go dependencies tidied$(NC)"

#------------------------------------------------------------------------------
# Validation
#------------------------------------------------------------------------------

validate: ## Validate Terraform configuration
	@echo "$(CYAN)Validating Terraform configuration...$(NC)"
	@terraform init -backend=false
	@terraform validate
	@echo "$(GREEN)✓ Terraform configuration is valid$(NC)"

#------------------------------------------------------------------------------
# Testing
#------------------------------------------------------------------------------

test: tidy fmt docs ## Run all tests (validation only, no deployment)
	@echo "$(CYAN)Running FortiGate module tests...$(NC)"
	@echo "$(YELLOW)⚠ Note: Full deployment tests require Azure credentials and pre-existing infrastructure$(NC)"
	@cd $(TESTDIR) && go test -v -run TestFortiGateValidation --timeout=10m
	@echo "$(GREEN)✓ Tests completed$(NC)"

test-full: tidy fmt docs ## Run full integration tests including deployment (requires Azure)
	@echo "$(CYAN)Running full FortiGate deployment tests...$(NC)"
	@echo "$(YELLOW)⚠ Warning: This will deploy actual Azure resources and may incur costs$(NC)"
	@read -p "Continue? [y/N] " -n 1 -r; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd $(TESTDIR) && go test -v --timeout=60m; \
	else \
		echo "\n$(RED)✗ Tests cancelled$(NC)"; \
	fi

#------------------------------------------------------------------------------
# Example Deployment
#------------------------------------------------------------------------------

init: ## Initialize Terraform in the example directory
	@echo "$(CYAN)Initializing Terraform...$(NC)"
	@cd $(EXAMPLEDIR) && terraform init
	@echo "$(GREEN)✓ Terraform initialized$(NC)"

plan: init ## Plan the example deployment
	@echo "$(CYAN)Planning FortiGate deployment...$(NC)"
	@cd $(EXAMPLEDIR) && terraform plan
	@echo "$(GREEN)✓ Plan completed$(NC)"

deploy: fmt docs init ## Deploy the example FortiGate configuration
	@echo "$(CYAN)Deploying FortiGate...$(NC)"
	@echo "$(YELLOW)⚠ Warning: This will deploy Azure resources and may incur costs$(NC)"
	@cd $(EXAMPLEDIR) && terraform apply
	@echo "$(GREEN)✓ Deployment completed$(NC)"

destroy: ## Destroy the example FortiGate deployment
	@echo "$(CYAN)Destroying FortiGate deployment...$(NC)"
	@echo "$(YELLOW)⚠ Warning: This will destroy all deployed resources$(NC)"
	@cd $(EXAMPLEDIR) && terraform destroy
	@echo "$(GREEN)✓ Resources destroyed$(NC)"

#------------------------------------------------------------------------------
# Maintenance
#------------------------------------------------------------------------------

upgrade: fmt docs ## Upgrade provider versions in example
	@echo "$(CYAN)Upgrading Terraform providers...$(NC)"
	@cd $(EXAMPLEDIR) && terraform init -upgrade
	@echo "$(GREEN)✓ Providers upgraded$(NC)"

clean: ## Clean up temporary files and caches
	@echo "$(CYAN)Cleaning up temporary files...$(NC)"
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@find . -type f -name "terraform.tfstate*" -delete 2>/dev/null || true
	@echo "$(GREEN)✓ Cleanup completed$(NC)"

#------------------------------------------------------------------------------
# Development Workflow
#------------------------------------------------------------------------------

dev: fmt validate docs ## Run development workflow (format, validate, docs)
	@echo "$(GREEN)✓ Development workflow completed$(NC)"

pre-commit: dev test ## Run all pre-commit checks
	@echo "$(GREEN)✓ Pre-commit checks passed$(NC)"

#------------------------------------------------------------------------------
# Security
#------------------------------------------------------------------------------

security-scan: ## Run security scanning with tfsec (requires tfsec installation)
	@echo "$(CYAN)Running security scan...$(NC)"
	@command -v tfsec >/dev/null 2>&1 || { echo "$(RED)✗ tfsec is not installed. Install from https://github.com/aquasecurity/tfsec$(NC)"; exit 1; }
	@tfsec .
	@echo "$(GREEN)✓ Security scan completed$(NC)"
