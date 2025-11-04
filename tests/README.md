# Terraform Native Tests

This directory contains native Terraform tests (`.tftest.hcl` files) for the terraform-azurerm-route-server module.

## Overview

These tests use Terraform's built-in testing framework (available in Terraform >= 1.6.0) to validate module functionality without requiring external test harnesses. All tests use mock providers and `command = plan` to ensure zero-cost, fast execution.

## Test Files

### basic.tftest.hcl
Tests core Route Server functionality:
- Basic Route Server creation with Public IP
- Route Server naming conventions
- Branch-to-branch traffic settings (enabled and disabled)
- Public IP configuration (SKU, allocation method)
- Diagnostics integration (enabled and disabled)
- Tag application (standard and optional tags)
- Output generation (id, name, ASN, IPs)
- Minimal configuration scenarios

**Test Cases (11 total)**:
- `test_basic_route_server_creation` - Verifies Route Server and Public IP are created with correct naming and SKU
- `test_branch_to_branch_disabled_default` - Validates branch-to-branch traffic is disabled by default (SECURITY)
- `test_branch_to_branch_enabled` - Tests branch-to-branch traffic can be enabled
- `test_route_server_naming` - Validates naming follows terraform-namer patterns
- `test_public_ip_configuration` - Verifies Public IP settings (Static, Standard SKU)
- `test_diagnostics_disabled` - Tests diagnostics module is not created when disabled
- `test_diagnostics_enabled` - Validates diagnostics module creation when enabled
- `test_optional_tags` - Tests optional tags merge with standard tags
- `test_standard_tags` - Verifies standard tags from namer module
- `test_resource_outputs` - Validates name output and resource configuration
- `test_minimal_configuration` - Tests module with minimal required variables

### validation.tftest.hcl
Tests input validation rules:
- RouteServerSubnet name validation (CRITICAL Azure requirement)
- Public IP SKU validation (must be Standard)
- Public IP allocation method validation (must be Static)
- Route Server SKU validation (must be Standard)
- Diagnostics workspace ID validation when enabled
- Name object structure validation
- Optional tags type validation

**Test Cases (17 total)**:
- `test_valid_routeserver_subnet` - Passes with correct "RouteServerSubnet" name
- `test_invalid_routeserver_subnet_name` - Fails with invalid subnet name (NEGATIVE TEST)
- `test_gateway_subnet_not_allowed` - Fails even with GatewaySubnet (NEGATIVE TEST)
- `test_public_ip_standard_sku` - Accepts Standard SKU
- `test_public_ip_basic_sku_rejected` - Rejects Basic SKU (NEGATIVE TEST)
- `test_public_ip_static_allocation` - Accepts Static allocation
- `test_public_ip_dynamic_allocation_rejected` - Rejects Dynamic allocation (NEGATIVE TEST)
- `test_route_server_standard_sku` - Accepts Standard SKU
- `test_route_server_basic_sku_rejected` - Rejects non-Standard SKU (NEGATIVE TEST)
- `test_diagnostics_enabled_missing_workspace` - Fails when enabled without workspace (NEGATIVE TEST)
- `test_diagnostics_enabled_with_workspace` - Passes with enabled + workspace ID
- `test_diagnostics_disabled_with_workspace` - Passes when disabled (workspace ID ignored)
- `test_name_with_instance` - Validates optional instance field
- `test_name_without_instance` - Tests default instance value ("0")
- `test_complete_valid_configuration` - Full configuration with all options
- `test_optional_tags_empty` - Accepts empty tags map
- `test_optional_tags_multiple` - Accepts multiple tag entries

## Running Tests

### Prerequisites

- Terraform >= 1.6.0 (required for native testing)
- No additional dependencies needed

### Run All Tests

```bash
# Using Terraform directly
terraform test

# Using Makefile
make test-terraform
```

### Run Specific Test File

```bash
terraform test -filter=tests/basic.tftest.hcl
terraform test -filter=tests/validation.tftest.hcl
```

### Run Specific Test Case

```bash
terraform test -filter=test_basic_route_server_creation
terraform test -filter=test_invalid_subnet_name
```

### Verbose Output

```bash
terraform test -verbose
```

### Example Output

```
tests\basic.tftest.hcl... in progress
  run "test_basic_route_server_creation"... pass
  run "test_branch_to_branch_disabled_default"... pass
  run "test_branch_to_branch_enabled"... pass
  run "test_route_server_naming"... pass
  run "test_public_ip_configuration"... pass
  run "test_diagnostics_disabled"... pass
  run "test_diagnostics_enabled"... pass
  run "test_optional_tags"... pass
  run "test_standard_tags"... pass
  run "test_resource_outputs"... pass
  run "test_minimal_configuration"... pass
tests\basic.tftest.hcl... tearing down
tests\basic.tftest.hcl... pass
tests\validation.tftest.hcl... in progress
  run "test_valid_routeserver_subnet"... pass
  run "test_invalid_routeserver_subnet_name"... pass
  run "test_gateway_subnet_not_allowed"... pass
  run "test_public_ip_standard_sku"... pass
  run "test_public_ip_basic_sku_rejected"... pass
  run "test_public_ip_static_allocation"... pass
  run "test_public_ip_dynamic_allocation_rejected"... pass
  run "test_route_server_standard_sku"... pass
  run "test_route_server_basic_sku_rejected"... pass
  run "test_diagnostics_enabled_missing_workspace"... pass
  run "test_diagnostics_enabled_with_workspace"... pass
  run "test_diagnostics_disabled_with_workspace"... pass
  run "test_name_with_instance"... pass
  run "test_name_without_instance"... pass
  run "test_complete_valid_configuration"... pass
  run "test_optional_tags_empty"... pass
  run "test_optional_tags_multiple"... pass
tests\validation.tftest.hcl... tearing down
tests\validation.tftest.hcl... pass

Success! 28 passed, 0 failed.
```

## Test Structure

Each test file follows this structure:

```hcl
# Test run block
run "test_name" {
  command = plan  # or apply

  # Input variables
  variables {
    name = {
      contact     = "test@example.com"
      environment = "sbx"
      repository  = "test-repo"
      workload    = "routing"
    }
    resource_group = {
      location = "centralus"
      name     = "rg-test"
    }
    subnet = {
      id = "/subscriptions/.../subnets/RouteServerSubnet"
    }
  }

  # Assertions
  assert {
    condition     = output.virtual_router_asn == 65515
    error_message = "Route Server ASN must be 65515"
  }

  # Expected failures (for negative tests)
  expect_failures = [
    var.subnet,
  ]
}
```

## Test Coverage

Current test coverage:

| Feature | Coverage | Test Count | Status |
|---------|----------|------------|--------|
| Route Server creation | ✓ Complete | 3 tests | ✓ Implemented |
| Public IP configuration | ✓ Complete | 4 tests | ✓ Implemented |
| Branch-to-branch traffic | ✓ Complete | 2 tests | ✓ Implemented |
| Diagnostics integration | ✓ Complete | 3 tests | ✓ Implemented |
| Naming and tagging | ✓ Complete | 3 tests | ✓ Implemented |
| Output validation | ✓ Complete | 1 test | ✓ Implemented |
| RouteServerSubnet validation | ✓ Complete | 3 tests | ✓ Implemented |
| SKU validation | ✓ Complete | 4 tests | ✓ Implemented |
| Diagnostics validation | ✓ Complete | 3 tests | ✓ Implemented |
| Name object validation | ✓ Complete | 2 tests | ✓ Implemented |
| Tags validation | ✓ Complete | 2 tests | ✓ Implemented |
| Complete configuration | ✓ Complete | 2 tests | ✓ Implemented |

**Total Tests**: 28 test cases across 2 test files

### Test Type Breakdown
- **Positive Tests** (happy path): 17 tests
- **Negative Tests** (validation failures): 6 tests
- **Configuration Tests** (various scenarios): 5 tests

### Coverage Statistics
- **100% variable coverage** - All input variables tested
- **100% validation rules** - All validation constraints tested
- **100% security defaults** - Branch-to-branch disabled by default
- **100% resource creation** - Route Server, Public IP, and conditional diagnostics

## Continuous Integration

These tests will run automatically in CI/CD:

- On pull requests to `main` and `develop`
- On pushes to `main` and `develop`
- When `*.tf` or `tests/**` files change

See `.github/workflows/test.yml` for CI configuration.

## Writing New Tests

To add new tests:

1. Create a new `.tftest.hcl` file or add to an existing one
2. Follow the naming convention: `test_<feature>_<scenario>`
3. Include clear error messages in assertions
4. Test both positive and negative cases
5. Run tests locally before committing

Example:

```hcl
run "test_route_server_asn" {
  command = plan

  variables {
    name = {
      contact     = "test@example.com"
      environment = "sbx"
      repository  = "test-repo"
      workload    = "routing"
    }
    resource_group = {
      location = "centralus"
      name     = "rg-test"
    }
    subnet = {
      id = "/subscriptions/.../subnets/RouteServerSubnet"
    }
  }

  assert {
    condition     = output.virtual_router_asn == 65515
    error_message = "Route Server must use ASN 65515 (Azure-managed)"
  }
}
```

## Important Route Server Test Considerations

### RouteServerSubnet Validation
- Tests must use a subnet ID containing "RouteServerSubnet"
- Subnet must be /27 or larger in real deployments
- Tests validate the name but cannot validate size in plan-only mode

### BGP Testing
- ASN is always 65515 (cannot be changed)
- Virtual router IPs are assigned by Azure (2 IPs for HA)
- BGP connections are managed separately (azurerm_route_server_bgp_connection)

### Public IP Requirements
- Must be Standard SKU (not Basic)
- Must use Static allocation
- Tests validate these constraints

### Diagnostics
- Optional diagnostics module integration
- Tests verify conditional resource creation
- Workspace ID required when enabled

## Comparing to Go Tests

This module will have Terraform native tests only (no Go-based Terratest tests initially):

| Aspect | Terraform Tests | Go Tests |
|--------|----------------|----------|
| **Location** | `tests/*.tftest.hcl` | N/A (not yet implemented) |
| **Framework** | Terraform native | N/A |
| **Speed** | Fast (plan only) | N/A |
| **Requirements** | Terraform >= 1.6.0 | N/A |
| **Best for** | Unit testing, validation | Integration testing |
| **CI/CD** | Yes | No |

## Troubleshooting

### Test Failures

If tests fail:

1. Run with verbose output: `terraform test -verbose`
2. Check the specific assertion that failed
3. Validate your changes didn't break existing functionality
4. Ensure you're using Terraform >= 1.6.0

### Terraform Version

Check your Terraform version:

```bash
terraform version
```

If you're using an older version, upgrade:

```bash
# Using tfenv
tfenv install latest
tfenv use latest

# Or download from terraform.io
```

### Debugging Tests

Add temporary assert blocks to debug:

```hcl
run "test_debug" {
  command = plan

  variables {
    # ...
  }

  # This will print during test execution
  assert {
    condition     = true
    error_message = "Debug: ${output.virtual_router_asn}"
  }
}
```

## Best Practices

1. **Keep tests focused** - Each test should validate one specific behavior
2. **Use descriptive names** - Test names should clearly indicate what they test
3. **Clear error messages** - Help developers understand failures quickly
4. **Test edge cases** - Don't just test the happy path
5. **Maintain tests** - Update tests when functionality changes
6. **Run before commit** - Always run tests before pushing changes

## Resources

- [Terraform Testing Documentation](https://developer.hashicorp.com/terraform/language/tests)
- [Terraform Test Command](https://developer.hashicorp.com/terraform/cli/commands/test)
- [Writing Terraform Tests](https://developer.hashicorp.com/terraform/tutorials/configuration-language/test)
- [Azure Route Server Documentation](https://learn.microsoft.com/en-us/azure/route-server/)

---

For questions or issues with tests, please open an issue in the repository.
