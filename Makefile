# =============================================================================
# Terraform Module Development Makefile
# =============================================================================

.PHONY: help docs fmt tffmt gofmt validate test tidy upgrade clean deploy init plan pre-commit security-scan

# Default target
.DEFAULT_GOAL := help

# Variables
TESTDIR := ./test
EXAMPLE_DIR := ./examples/default

# Color output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

# =============================================================================
# Help Target
# =============================================================================

help: ## Display this help message
	@echo "$(CYAN)========================================$(NC)"
	@echo "$(CYAN)Terraform Module - Available Commands$(NC)"
	@echo "$(CYAN)========================================$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

# =============================================================================
# Documentation
# =============================================================================

docs: ## Generate Terraform documentation using terraform-docs
	@echo "$(YELLOW)Generating documentation...$(NC)"
	@terraform-docs markdown document --output-file README.md --output-mode inject .
	@echo "$(GREEN)✓ Documentation generated$(NC)"

# =============================================================================
# Formatting
# =============================================================================

tffmt: ## Format Terraform files
	@echo "$(YELLOW)Formatting Terraform files...$(NC)"
	@terraform fmt -recursive
	@echo "$(GREEN)✓ Terraform files formatted$(NC)"

gofmt: ## Format Go test files
	@echo "$(YELLOW)Formatting Go files...$(NC)"
	@cd $(TESTDIR) && go fmt
	@echo "$(GREEN)✓ Go files formatted$(NC)"

fmt: tffmt gofmt ## Format all files (Terraform and Go)

# =============================================================================
# Dependencies
# =============================================================================

tidy: ## Tidy Go module dependencies
	@echo "$(YELLOW)Tidying Go dependencies...$(NC)"
	@cd $(TESTDIR) && go mod tidy
	@echo "$(GREEN)✓ Go dependencies tidied$(NC)"

# =============================================================================
# Validation
# =============================================================================

validate: ## Validate Terraform configuration
	@echo "$(YELLOW)Validating Terraform configuration...$(NC)"
	@terraform init -backend=false
	@terraform validate
	@echo "$(GREEN)✓ Terraform configuration is valid$(NC)"

# =============================================================================
# Testing
# =============================================================================

test: tidy fmt docs ## Run all tests (Go-based Terratest)
	@echo "$(YELLOW)Running tests...$(NC)"
	@cd $(TESTDIR) && go test -v --timeout=30m
	@echo "$(GREEN)✓ All tests passed$(NC)"

test-quick: ## Run tests without formatting and docs generation
	@echo "$(YELLOW)Running tests...$(NC)"
	@cd $(TESTDIR) && go test -v --timeout=30m

test-specific: ## Run specific test (usage: make test-specific TEST=TestDefault)
	@echo "$(YELLOW)Running test: $(TEST)...$(NC)"
	@cd $(TESTDIR) && go test -v -run $(TEST) --timeout=30m

test-terraform: ## Run native Terraform tests (requires Terraform >= 1.6.0)
	@echo "$(YELLOW)Running Terraform native tests...$(NC)"
	@terraform test -verbose
	@echo "$(GREEN)✓ All Terraform tests passed$(NC)"

test-terraform-filter: ## Run specific Terraform test file (usage: make test-terraform-filter FILE=tests/basic.tftest.hcl)
	@echo "$(YELLOW)Running Terraform test: $(FILE)...$(NC)"
	@terraform test -filter=$(FILE) -verbose

test-all: tidy fmt docs test-terraform ## Run all tests (both Go and Terraform native)
	@echo "$(YELLOW)Running Go tests...$(NC)"
	@cd $(TESTDIR) && go test -v --timeout=30m
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)✓ All tests passed (Go + Terraform)!$(NC)"
	@echo "$(GREEN)========================================$(NC)"

# =============================================================================
# Deployment
# =============================================================================

init: ## Initialize Terraform in example directory
	@echo "$(YELLOW)Initializing Terraform...$(NC)"
	@cd $(EXAMPLE_DIR) && terraform init
	@echo "$(GREEN)✓ Terraform initialized$(NC)"

plan: init ## Create Terraform plan
	@echo "$(YELLOW)Creating Terraform plan...$(NC)"
	@cd $(EXAMPLE_DIR) && terraform plan
	@echo "$(GREEN)✓ Plan created$(NC)"

deploy: fmt docs ## Apply Terraform configuration (example)
	@echo "$(YELLOW)Applying Terraform configuration...$(NC)"
	@cd $(EXAMPLE_DIR) && terraform apply
	@echo "$(GREEN)✓ Configuration applied$(NC)"

destroy: ## Destroy Terraform resources (example)
	@echo "$(RED)Destroying Terraform resources...$(NC)"
	@cd $(EXAMPLE_DIR) && terraform destroy
	@echo "$(GREEN)✓ Resources destroyed$(NC)"

# =============================================================================
# Maintenance
# =============================================================================

upgrade: fmt docs ## Upgrade Terraform providers
	@echo "$(YELLOW)Upgrading Terraform providers...$(NC)"
	@cd $(EXAMPLE_DIR) && terraform init -upgrade
	@echo "$(GREEN)✓ Providers upgraded$(NC)"

clean: ## Clean temporary files and caches
	@echo "$(YELLOW)Cleaning temporary files...$(NC)"
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.tfstate" -delete 2>/dev/null || true
	@find . -type f -name "*.tfstate.backup" -delete 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@find . -type f -name "*.tfplan" -delete 2>/dev/null || true
	@cd $(TESTDIR) && go clean -cache 2>/dev/null || true
	@echo "$(GREEN)✓ Temporary files cleaned$(NC)"

# =============================================================================
# Pre-commit Checks
# =============================================================================

pre-commit: fmt validate test ## Run all pre-commit checks (format, validate, test)
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)✓ All pre-commit checks passed!$(NC)"
	@echo "$(GREEN)========================================$(NC)"

# =============================================================================
# Security & Quality
# =============================================================================

security-scan: ## Run security scanning with tfsec
	@echo "$(YELLOW)Running security scan...$(NC)"
	@if command -v tfsec >/dev/null 2>&1; then \
		tfsec .; \
		echo "$(GREEN)✓ Security scan complete$(NC)"; \
	else \
		echo "$(RED)tfsec not found. Install it: https://github.com/aquasecurity/tfsec$(NC)"; \
		exit 1; \
	fi

lint: ## Run TFLint for code quality
	@echo "$(YELLOW)Running TFLint...$(NC)"
	@if command -v tflint >/dev/null 2>&1; then \
		tflint --init && tflint; \
		echo "$(GREEN)✓ Linting complete$(NC)"; \
	else \
		echo "$(RED)tflint not found. Install it: https://github.com/terraform-linters/tflint$(NC)"; \
		exit 1; \
	fi

# =============================================================================
# Development Workflow
# =============================================================================

dev: clean fmt validate docs test ## Complete development workflow
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)✓ Development workflow complete!$(NC)"
	@echo "$(GREEN)========================================$(NC)"

check: fmt validate docs ## Quick check (format, validate, docs)
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)✓ Quick check complete!$(NC)"
	@echo "$(GREEN)========================================$(NC)"

# =============================================================================
# CI/CD Helpers
# =============================================================================

ci-test: ## Run tests in CI environment (without cleanup)
	@echo "$(YELLOW)Running CI tests...$(NC)"
	@cd $(TESTDIR) && go test -v --timeout=30m -json > test-results.json || true
	@cd $(TESTDIR) && go test -v --timeout=30m

# =============================================================================
# Information
# =============================================================================

info: ## Display project information
	@echo "$(CYAN)========================================$(NC)"
	@echo "$(CYAN)Project Information$(NC)"
	@echo "$(CYAN)========================================$(NC)"
	@echo "$(GREEN)Module Name:$(NC) terraform-azurerm-route-server"
	@echo "$(GREEN)Terraform Version:$(NC) >= 1.6.0"
	@echo "$(GREEN)AzureRM Provider:$(NC) >= 3.41"
	@echo "$(GREEN)Go Version:$(NC) >= 1.18"
	@echo "$(GREEN)Test Directory:$(NC) $(TESTDIR)"
	@echo "$(GREEN)Example Directory:$(NC) $(EXAMPLE_DIR)"
	@echo ""
