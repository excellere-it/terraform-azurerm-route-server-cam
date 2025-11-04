# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.1] - 2025-10-28

### Added
- Initial Azure Route Server Terraform module implementation
- Azure Route Server resource (azurerm_route_server) with Standard SKU
- Public IP address resource with Standard SKU and Static allocation
- **BGP peer connection support (azurerm_route_server_bgp_connection)**
  - Support for up to 8 BGP peer connections (Azure limit)
  - Map-based configuration for multiple NVA peers
  - ASN validation (1-4294967295, 32-bit support)
  - IPv4 address validation for peer IPs
  - Comprehensive BGP connection outputs (connections, IDs, count)
- Integration with terraform-namer module (v0.0.3) for consistent naming and tagging
- Integration with diagnostics module (v0.0.2) for optional monitoring
- Branch-to-branch traffic configuration (disabled by default for security)
- Public IP configuration with Standard SKU enforcement
- RouteServerSubnet name validation (Azure requirement)
- Comprehensive input validation (8 validation rules, including BGP)
- Lifecycle preconditions for runtime validation
- Comprehensive test suite with 42 native Terraform tests (100% pass rate)
- tests/basic.tftest.hcl - 15 core functionality tests (11 base + 4 BGP)
- tests/validation.tftest.hcl - 27 input validation tests (17 base + 10 BGP)
- Zero-cost testing using mock providers (plan-only)
- GitHub Actions CI/CD pipeline with 7-job workflow
- Makefile with 20+ automation targets
- Complete examples/default/ configuration with BGP peering example
- CONTRIBUTING.md with development workflow
- Comprehensive documentation in main.tf (120-line header)

### Security
- Branch-to-branch traffic disabled by default (secure posture)
- Standard SKU enforcement prevents insecure Basic SKU usage
- Static IP allocation required (security best practice)
- RouteServerSubnet name validation (Azure security boundary)
- **BGP connection security**
  - ASN validation prevents invalid BGP configurations
  - IPv4-only validation (IPv6 not yet supported by Azure)
  - Maximum 8 connections enforced (Azure security limit)
  - BGP MD5 authentication documented (planned for v0.1.0)
  - NSG requirements for BGP traffic (TCP/179) documented
- Comprehensive security documentation in module header
- Security review completed (68/100 initial score, remediation plan provided)
- BGP security best practices documented
- NSG requirements documented for RouteServerSubnet
- DDoS Protection recommendations included

### Documentation
- Comprehensive README.md with auto-generated documentation
- Complete CHANGELOG.md following Keep a Changelog format
- CONTRIBUTING.md with development guidelines
- tests/README.md with test framework documentation
- .github/workflows/README.md with CI/CD pipeline docs
- Module header with 4 common use cases
- **BGP peering documentation**
  - BGP connection configuration examples (FortiGate, Palo Alto)
  - Detailed variable descriptions with ASN ranges
  - BGP security notes in variables.tf
  - Comprehensive test coverage documentation
- BGP peering scenarios documented
- Security considerations (6 areas)
- Performance considerations (5 areas)
- Cost considerations (4 areas)

### Requirements
- Terraform >= 1.6.0
- Azure Provider >= 3.41
- RouteServerSubnet must be /27 or larger
- Standard SKU Public IP required
- Static IP allocation required

---

## Version History Notes

### Versioning Scheme

This project follows [Semantic Versioning](https://semver.org/):
- **MAJOR** version for incompatible API changes
- **MINOR** version for new functionality in a backward compatible manner
- **PATCH** version for backward compatible bug fixes

### Release Process

Releases are automated via GitHub Actions:
1. Create a tag matching the pattern `0.0.*` (e.g., `0.0.1`)
2. Push the tag to GitHub
3. GitHub Actions automatically creates a release with notes

### Upgrade Guidance

When upgrading between versions, check the relevant sections above for:
- **Breaking Changes**: May require updates to your configuration
- **Deprecated Features**: Plan to migrate away from these
- **New Features**: Optional enhancements you may want to adopt

---

## Template for Future Releases

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features and capabilities

### Changed
- Changes to existing functionality

### Deprecated
- Features that will be removed in future versions

### Removed
- Features removed in this version

### Fixed
- Bug fixes

### Security
- Security-related changes
```

---

[Unreleased]: https://github.com/excellere-it/terraform-azurerm-route-server/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/excellere-it/terraform-azurerm-route-server/releases/tag/v0.0.1
