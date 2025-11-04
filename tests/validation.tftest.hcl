# Input Validation Tests
#
# Tests input validation rules for the terraform-azurerm-route-server module including:
# - RouteServerSubnet name validation
# - Public IP SKU validation (must be Standard)
# - Public IP allocation method validation (must be Static)
# - Route Server SKU validation (must be Standard)
# - Diagnostics workspace ID validation when enabled
# - Variable type constraints

mock_provider "azurerm" {
  mock_resource "azurerm_route_server" {
    defaults = {
      id                 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualHubs/rs-routing-cu-sbx-kmi-0"
      virtual_router_asn = 65515
      virtual_router_ips = ["10.0.0.4", "10.0.0.5"]
    }
  }

  mock_resource "azurerm_public_ip" {
    defaults = {
      id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/publicIPAddresses/pip-routing-cu-sbx-kmi-0"
      ip_address = "20.30.40.50"
    }
  }

  mock_resource "azurerm_route_server_bgp_connection" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualHubs/rs-routing-cu-sbx-kmi-0/bgpConnections/bgp-test"
    }
  }
}

variables {
  name = {
    contact     = "test@example.com"
    environment = "sbx"
    repository  = "terraform-azurerm-route-server"
    workload    = "routing"
  }

  resource_group = {
    location = "centralus"
    name     = "rg-test"
  }

  subnet = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/RouteServerSubnet"
  }

  diagnostics = {
    enabled = false
  }
}

#
# Test: RouteServerSubnet Name Validation (PASS)
#
# Verifies that a subnet ID containing "RouteServerSubnet" passes validation.
# This is a critical Azure requirement for Route Server deployment.
#
run "test_valid_routeserver_subnet" {
  command = plan

  variables {
    subnet = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/RouteServerSubnet"
    }
  }

  assert {
    condition     = azurerm_route_server.this.subnet_id != null
    error_message = "Valid RouteServerSubnet should be accepted"
  }
}

#
# Test: RouteServerSubnet Name Validation (FAIL)
#
# Verifies that a subnet with invalid name fails validation.
# Route Server MUST be deployed in a subnet named "RouteServerSubnet".
#
run "test_invalid_routeserver_subnet_name" {
  command = plan

  variables {
    subnet = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/default-subnet"
    }
  }

  expect_failures = [
    var.subnet,
  ]
}

#
# Test: RouteServerSubnet Name Validation - GatewaySubnet (FAIL)
#
# Verifies that even other special subnet names like GatewaySubnet fail.
# Only "RouteServerSubnet" is acceptable.
#
run "test_gateway_subnet_not_allowed" {
  command = plan

  variables {
    subnet = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/GatewaySubnet"
    }
  }

  expect_failures = [
    var.subnet,
  ]
}

#
# Test: Public IP SKU Validation (Standard Required)
#
# Verifies that only Standard SKU is accepted for Public IP.
# This is enforced by both variable validation and resource lifecycle precondition.
#
run "test_public_ip_standard_sku" {
  command = plan

  variables {
    public_ip_sku = "Standard"
  }

  assert {
    condition     = azurerm_public_ip.route_server.sku == "Standard"
    error_message = "Public IP should accept Standard SKU"
  }
}

#
# Test: Public IP SKU Validation (Basic Not Allowed)
#
# Verifies that Basic SKU is rejected for Public IP.
# Route Server requires Standard SKU.
#
run "test_public_ip_basic_sku_rejected" {
  command = plan

  variables {
    public_ip_sku = "Basic"
  }

  expect_failures = [
    var.public_ip_sku,
  ]
}

#
# Test: Public IP Allocation Method (Static Required)
#
# Verifies that Static allocation method is accepted.
# Standard SKU Public IPs require Static allocation.
#
run "test_public_ip_static_allocation" {
  command = plan

  variables {
    public_ip_allocation_method = "Static"
  }

  assert {
    condition     = azurerm_public_ip.route_server.allocation_method == "Static"
    error_message = "Public IP should accept Static allocation method"
  }
}

#
# Test: Public IP Allocation Method (Dynamic Not Allowed)
#
# Verifies that Dynamic allocation method is rejected.
# Route Server requires Static allocation for Standard SKU.
#
run "test_public_ip_dynamic_allocation_rejected" {
  command = plan

  variables {
    public_ip_allocation_method = "Dynamic"
  }

  expect_failures = [
    var.public_ip_allocation_method,
  ]
}

#
# Test: Route Server SKU Validation (Standard Required)
#
# Verifies that Standard SKU is accepted for Route Server.
# This is currently the only SKU available for Route Server.
#
run "test_route_server_standard_sku" {
  command = plan

  variables {
    sku = "Standard"
  }

  assert {
    condition     = azurerm_route_server.this.sku == "Standard"
    error_message = "Route Server should accept Standard SKU"
  }
}

#
# Test: Route Server SKU Validation (Basic Not Allowed)
#
# Verifies that non-Standard SKUs are rejected.
# Azure only supports Standard SKU for Route Server.
#
run "test_route_server_basic_sku_rejected" {
  command = plan

  variables {
    sku = "Basic"
  }

  expect_failures = [
    var.sku,
  ]
}

#
# Test: Diagnostics Enabled Without Workspace ID (FAIL)
#
# Verifies that enabling diagnostics without workspace ID fails validation.
# This prevents misconfiguration where diagnostics would be enabled but unusable.
#
run "test_diagnostics_enabled_missing_workspace" {
  command = plan

  variables {
    diagnostics = {
      enabled                    = true
      log_analytics_workspace_id = null
    }
  }

  expect_failures = [
    var.diagnostics,
  ]
}

#
# Test: Diagnostics Enabled With Workspace ID (PASS)
#
# Verifies that enabling diagnostics with valid workspace ID passes.
#
run "test_diagnostics_enabled_with_workspace" {
  command = plan

  variables {
    diagnostics = {
      enabled                    = true
      log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
    }
  }

  assert {
    condition     = length(module.diagnostics) == 1
    error_message = "Diagnostics should be enabled when workspace ID is provided"
  }
}

#
# Test: Diagnostics Disabled With Workspace ID (PASS)
#
# Verifies that diagnostics can be disabled even when workspace ID is provided.
# This is a valid configuration.
#
run "test_diagnostics_disabled_with_workspace" {
  command = plan

  variables {
    diagnostics = {
      enabled                    = false
      log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
    }
  }

  assert {
    condition     = length(module.diagnostics) == 0
    error_message = "Diagnostics should not be created when disabled, even with workspace ID"
  }
}

#
# Test: Name Object With Optional Instance
#
# Verifies that name object accepts optional instance field.
#
run "test_name_with_instance" {
  command = plan

  variables {
    name = {
      contact     = "test@example.com"
      environment = "prd"
      repository  = "test-repo"
      workload    = "routing"
      instance    = "5"
    }
  }

  assert {
    condition     = var.name.instance == "5"
    error_message = "Name should accept optional instance field"
  }
}

#
# Test: Name Object Without Instance (Default)
#
# Verifies that name object works without instance (defaults to "0").
#
run "test_name_without_instance" {
  command = plan

  variables {
    name = {
      contact     = "test@example.com"
      environment = "dev"
      repository  = "test-repo"
      workload    = "routing"
    }
  }

  assert {
    condition     = azurerm_route_server.this.name != null
    error_message = "Name should work with default instance value"
  }
}

#
# Test: Complete Valid Configuration
#
# Verifies that a complete configuration with all valid values passes validation.
#
run "test_complete_valid_configuration" {
  command = plan

  variables {
    name = {
      contact     = "admin@company.com"
      environment = "prd"
      repository  = "infrastructure"
      workload    = "hub-routing"
      instance    = "1"
    }

    resource_group = {
      location = "eastus2"
      name     = "rg-hub-routing"
    }

    subnet = {
      id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub/subnets/RouteServerSubnet"
    }

    branch_to_branch_traffic_enabled = true
    sku                              = "Standard"
    public_ip_allocation_method      = "Static"
    public_ip_sku                    = "Standard"

    diagnostics = {
      enabled                    = true
      log_analytics_workspace_id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/law-central"
    }

    optional_tags = {
      Topology    = "hub-spoke"
      ManagedBy   = "Terraform"
      CostCenter  = "Network-Operations"
      Criticality = "High"
    }
  }

  assert {
    condition     = azurerm_route_server.this.name != null
    error_message = "Complete valid configuration should create Route Server"
  }

  assert {
    condition     = azurerm_public_ip.route_server.name != null
    error_message = "Complete valid configuration should create Public IP"
  }

  assert {
    condition     = length(module.diagnostics) == 1
    error_message = "Complete valid configuration should enable diagnostics"
  }
}

#
# Test: Optional Tags Type Validation (Empty Map)
#
# Verifies that optional_tags accepts an empty map.
#
run "test_optional_tags_empty" {
  command = plan

  variables {
    optional_tags = {}
  }

  assert {
    condition     = length(var.optional_tags) == 0
    error_message = "Optional tags should accept empty map"
  }
}

#
# Test: Optional Tags Type Validation (Multiple Entries)
#
# Verifies that optional_tags accepts multiple key-value pairs.
#
run "test_optional_tags_multiple" {
  command = plan

  variables {
    optional_tags = {
      Environment = "Production"
      CostCenter  = "IT-001"
      Owner       = "Network Team"
      Criticality = "High"
      Compliance  = "Required"
    }
  }

  assert {
    condition     = length(var.optional_tags) == 5
    error_message = "Optional tags should accept multiple entries"
  }

  assert {
    condition     = var.optional_tags["Environment"] == "Production"
    error_message = "Optional tags values should be preserved"
  }
}

#
# Test: BGP Connections Maximum Count (8 Connections - PASS)
#
# Verifies that up to 8 BGP connections are allowed (Azure limit).
#
run "test_bgp_connections_max_allowed" {
  command = plan

  variables {
    bgp_connections = {
      nva1 = { peer_asn = 65001, peer_ip = "10.100.1.4" }
      nva2 = { peer_asn = 65002, peer_ip = "10.100.1.5" }
      nva3 = { peer_asn = 65003, peer_ip = "10.100.1.6" }
      nva4 = { peer_asn = 65004, peer_ip = "10.100.1.7" }
      nva5 = { peer_asn = 65005, peer_ip = "10.100.1.8" }
      nva6 = { peer_asn = 65006, peer_ip = "10.100.1.9" }
      nva7 = { peer_asn = 65007, peer_ip = "10.100.1.10" }
      nva8 = { peer_asn = 65008, peer_ip = "10.100.1.11" }
    }
  }

  assert {
    condition     = length(azurerm_route_server_bgp_connection.this) == 8
    error_message = "Should allow 8 BGP connections (Azure maximum)"
  }
}

#
# Test: BGP Connections Exceed Maximum (9 Connections - FAIL)
#
# Verifies that more than 8 BGP connections are rejected.
# Azure Route Server has a hard limit of 8 BGP peer connections.
#
run "test_bgp_connections_exceed_max" {
  command = plan

  variables {
    bgp_connections = {
      nva1 = { peer_asn = 65001, peer_ip = "10.100.1.4" }
      nva2 = { peer_asn = 65002, peer_ip = "10.100.1.5" }
      nva3 = { peer_asn = 65003, peer_ip = "10.100.1.6" }
      nva4 = { peer_asn = 65004, peer_ip = "10.100.1.7" }
      nva5 = { peer_asn = 65005, peer_ip = "10.100.1.8" }
      nva6 = { peer_asn = 65006, peer_ip = "10.100.1.9" }
      nva7 = { peer_asn = 65007, peer_ip = "10.100.1.10" }
      nva8 = { peer_asn = 65008, peer_ip = "10.100.1.11" }
      nva9 = { peer_asn = 65009, peer_ip = "10.100.1.12" }
    }
  }

  expect_failures = [
    var.bgp_connections,
  ]
}

#
# Test: BGP Connection Valid ASN (Private Range - PASS)
#
# Verifies that valid private ASNs (64512-65534) are accepted.
#
run "test_bgp_connection_valid_private_asn" {
  command = plan

  variables {
    bgp_connections = {
      nva1 = { peer_asn = 65001, peer_ip = "10.100.1.4" }
    }
  }

  assert {
    condition     = azurerm_route_server_bgp_connection.this["nva1"].peer_asn == 65001
    error_message = "Should accept valid private ASN"
  }
}

#
# Test: BGP Connection Valid ASN (32-bit Range - PASS)
#
# Verifies that valid 32-bit ASNs (4200000000-4294967294) are accepted.
#
run "test_bgp_connection_valid_32bit_asn" {
  command = plan

  variables {
    bgp_connections = {
      nva1 = { peer_asn = 4200000000, peer_ip = "10.100.1.4" }
    }
  }

  assert {
    condition     = azurerm_route_server_bgp_connection.this["nva1"].peer_asn == 4200000000
    error_message = "Should accept valid 32-bit ASN"
  }
}

#
# Test: BGP Connection Invalid ASN (Zero - FAIL)
#
# Verifies that ASN 0 is rejected (not a valid BGP AS number).
#
run "test_bgp_connection_invalid_asn_zero" {
  command = plan

  variables {
    bgp_connections = {
      nva1 = { peer_asn = 0, peer_ip = "10.100.1.4" }
    }
  }

  expect_failures = [
    var.bgp_connections,
  ]
}

#
# Test: BGP Connection Invalid ASN (Too High - FAIL)
#
# Verifies that ASN > 4294967295 (32-bit max) is rejected.
#
run "test_bgp_connection_invalid_asn_too_high" {
  command = plan

  variables {
    bgp_connections = {
      nva1 = { peer_asn = 4294967296, peer_ip = "10.100.1.4" }
    }
  }

  expect_failures = [
    var.bgp_connections,
  ]
}

#
# Test: BGP Connection Valid IPv4 Address (PASS)
#
# Verifies that valid IPv4 addresses are accepted.
#
run "test_bgp_connection_valid_ipv4" {
  command = plan

  variables {
    bgp_connections = {
      nva1 = { peer_asn = 65001, peer_ip = "192.168.1.100" }
    }
  }

  assert {
    condition     = azurerm_route_server_bgp_connection.this["nva1"].peer_ip == "192.168.1.100"
    error_message = "Should accept valid IPv4 address"
  }
}

#
# Test: BGP Connection Invalid IP - Not IPv4 Format (FAIL)
#
# Verifies that invalid IP formats are rejected.
#
run "test_bgp_connection_invalid_ip_format" {
  command = plan

  variables {
    bgp_connections = {
      nva1 = { peer_asn = 65001, peer_ip = "not-an-ip" }
    }
  }

  expect_failures = [
    var.bgp_connections,
  ]
}

#
# Test: BGP Connection Invalid IP - IPv6 Not Supported (FAIL)
#
# Verifies that IPv6 addresses are rejected (only IPv4 supported).
#
run "test_bgp_connection_invalid_ip_ipv6" {
  command = plan

  variables {
    bgp_connections = {
      nva1 = { peer_asn = 65001, peer_ip = "2001:0db8::1" }
    }
  }

  expect_failures = [
    var.bgp_connections,
  ]
}

#
# Test: BGP Connection Invalid IP - Incomplete Address (FAIL)
#
# Verifies that incomplete IPv4 addresses are rejected.
#
run "test_bgp_connection_invalid_ip_incomplete" {
  command = plan

  variables {
    bgp_connections = {
      nva1 = { peer_asn = 65001, peer_ip = "10.100.1" }
    }
  }

  expect_failures = [
    var.bgp_connections,
  ]
}
