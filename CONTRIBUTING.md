# Contributing to terraform-azurerm-route-server

Thank you for your interest in contributing to the terraform-azurerm-route-server module! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Testing Requirements](#testing-requirements)
- [Coding Standards](#coding-standards)
- [Documentation](#documentation)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

We are committed to providing a welcoming and inclusive environment. Please be respectful and professional in all interactions.

### Expected Behavior

- Use welcoming and inclusive language
- Be respectful of differing viewpoints and experiences
- Gracefully accept constructive criticism
- Focus on what is best for the community
- Show empathy towards other community members

## Getting Started

### Prerequisites

Before you begin, ensure you have the following tools installed:

- [Terraform](https://www.terraform.io/downloads.html) >= 1.6.0
- [Go](https://golang.org/dl/) >= 1.18 (for testing)
- [terraform-docs](https://terraform-docs.io/) (for documentation generation)
- [Make](https://www.gnu.org/software/make/) (for automation)
- Git

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/terraform-azurerm-route-server.git
   cd terraform-azurerm-route-server
   ```
3. Add the upstream repository:
   ```bash
   git remote add upstream https://github.com/infoex/terraform-azurerm-route-server.git
   ```

### Development Setup

1. Initialize the Go module:
   ```bash
   cd test
   go mod download
   cd ..
   ```

2. Verify your setup:
   ```bash
   make fmt
   make validate
   ```

## Development Workflow

### 1. Create a Feature Branch

Always create a new branch for your work:

```bash
git checkout -b feature/your-feature-name
```

Branch naming conventions:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `test/` - Test additions or modifications
- `refactor/` - Code refactoring

### 2. Make Your Changes

- Follow the [coding standards](#coding-standards) below
- Write clear, concise commit messages
- Keep commits focused and atomic

### 3. Test Your Changes

Before submitting a pull request, ensure all tests pass:

```bash
# Format code
make fmt

# Validate configuration
make validate

# Generate documentation
make docs
```

### 4. Commit Your Changes

Write clear commit messages following this format:

```
<type>: <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Test additions or changes
- `refactor`: Code refactoring
- `style`: Code style changes (formatting, etc.)
- `chore`: Maintenance tasks

Example:
```
feat: Add support for route server BGP connections

Added support for managing BGP connections to the route server,
enabling dynamic routing with network virtual appliances.

Closes #123
```

### 5. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a pull request on GitHub.

## Testing Requirements

All contributions must include appropriate tests.

### Running Tests

```bash
# Run native Terraform tests
make test-terraform

# Run tests with verbose output
terraform test -verbose

# Run specific test
terraform test -filter=tests/basic.tftest.hcl
```

### Test Coverage

- All new features must include tests
- Bug fixes should include regression tests
- Aim for comprehensive test coverage of new code

## Coding Standards

### Terraform Style

Follow the [HashiCorp Terraform Style Guide](https://www.terraform.io/docs/language/syntax/style.html):

1. **Formatting**: Use `terraform fmt` for consistent formatting
2. **Naming**: Use snake_case for variables, outputs, and resources
3. **Comments**: Add section headers and explain complex logic
4. **Organization**: Group related resources together

### File Organization

```
terraform-azurerm-route-server/
├── main.tf           # Core module logic
├── variables.tf      # Input variable definitions
├── outputs.tf        # Output definitions
├── versions.tf       # Provider version requirements
```

### Variable Naming

- Use descriptive, lowercase names with underscores
- Prefix boolean variables with `enable_` or `is_`
- Use plural for list/map variables

### Documentation Standards

1. **Variables**: All variables must have descriptions
   ```hcl
   variable "branch_to_branch_traffic_enabled" {
     type        = bool
     description = "Enable branch-to-branch traffic between BGP peers"
     default     = false
   }
   ```

2. **Outputs**: All outputs must have descriptions
   ```hcl
   output "virtual_router_asn" {
     value       = azurerm_route_server.this.virtual_router_asn
     description = "The ASN of the Route Server (always 65515)"
   }
   ```

3. **Comments**: Use comments for complex logic
   ```hcl
   # Route Server requires Standard SKU public IP
   # Static allocation is required for Standard SKU
   ```

### Input Validation

Add validation rules for inputs where appropriate:

```hcl
variable "sku" {
  type        = string
  description = "The SKU of the Route Server"
  default     = "Standard"

  validation {
    condition     = var.sku == "Standard"
    error_message = "Route Server only supports 'Standard' SKU."
  }
}
```

## Documentation

### README Updates

When adding features or changing behavior:

1. Update the README.md with new examples
2. Run `make docs` to regenerate terraform-docs sections
3. Ensure all examples are up to date

### terraform-docs

Documentation is automatically generated from:
- Variable descriptions in `variables.tf`
- Output descriptions in `outputs.tf`
- Header comment in `main.tf`

Generate documentation:
```bash
make docs
```

### Examples

Add examples for new features in the `examples/` directory:

```
examples/
└── your-feature/
    ├── main.tf
    ├── versions.tf
    └── README.md  # Optional
```

## Pull Request Process

### Before Submitting

Ensure you have:

- [ ] Run `make fmt` to format code
- [ ] Run `make validate` to validate configuration
- [ ] Run `make docs` to update documentation
- [ ] Added tests for new functionality
- [ ] Updated README.md if needed
- [ ] Updated CHANGELOG.md with your changes
- [ ] Rebased on latest main branch

### PR Description

Include in your pull request:

1. **Summary**: Brief description of changes
2. **Motivation**: Why is this change needed?
3. **Changes**: List of specific changes made
4. **Testing**: How you tested the changes
5. **Breaking Changes**: Note any breaking changes
6. **Related Issues**: Link to related issues

### Review Process

1. Automated checks will run (tests, formatting, etc.)
2. Maintainers will review your code
3. Address any feedback
4. Once approved, maintainers will merge

### After Merge

1. Delete your feature branch
2. Pull the latest changes from upstream:
   ```bash
   git checkout main
   git pull upstream main
   ```

## Release Process

Releases are automated using GitHub Actions:

1. Maintainers create a version tag (e.g., `v0.1.0`)
2. GitHub Actions automatically creates a release
3. Release notes are auto-generated from commits

## Additional Resources

- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Azure Route Server Documentation](https://learn.microsoft.com/en-us/azure/route-server/)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)

---

Thank you for contributing to terraform-azurerm-route-server!
