# Basic Functionality Tests
#
# Tests core functionality of the terraform-azurerm-route-server module including:
# - Basic Route Server creation with Public IP
# - Branch-to-branch traffic configuration
# - Resource naming conventions
# - Tag application
# - Diagnostics integration (enabled and disabled)
# - Output generation

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
# Test: Basic Route Server Creation
#
# Verifies that a Route Server and Public IP are created with correct configuration.
# This is a smoke test to ensure the module syntax and core resources are correct.
#
run "test_basic_route_server_creation" {
  command = plan

  assert {
    condition     = can(regex("^rs-routing-cu-sbx-", azurerm_route_server.this.name))
    error_message = "Route Server name should follow naming convention starting with: rs-<workload>-<location>-<env>-"
  }

  assert {
    condition     = can(regex("^pip-routing-cu-sbx-", azurerm_public_ip.route_server.name))
    error_message = "Public IP name should follow naming convention starting with: pip-<workload>-<location>-<env>-"
  }

  assert {
    condition     = azurerm_route_server.this.sku == "Standard"
    error_message = "Route Server SKU must be Standard"
  }

  assert {
    condition     = azurerm_public_ip.route_server.sku == "Standard"
    error_message = "Public IP SKU must be Standard for Route Server"
  }
}

#
# Test: Branch-to-Branch Traffic Disabled (Default)
#
# Verifies that branch-to-branch traffic is disabled by default for security.
# This is a critical security test.
#
run "test_branch_to_branch_disabled_default" {
  command = plan

  assert {
    condition     = azurerm_route_server.this.branch_to_branch_traffic_enabled == false
    error_message = "Branch-to-branch traffic should be disabled by default for security"
  }
}

#
# Test: Branch-to-Branch Traffic Enabled
#
# Verifies that branch-to-branch traffic can be explicitly enabled when needed.
#
run "test_branch_to_branch_enabled" {
  command = plan

  variables {
    branch_to_branch_traffic_enabled = true
  }

  assert {
    condition     = azurerm_route_server.this.branch_to_branch_traffic_enabled == true
    error_message = "Branch-to-branch traffic should be enabled when variable is set to true"
  }
}

#
# Test: Route Server Naming Integration
#
# Verifies that naming follows terraform-namer module pattern.
#
run "test_route_server_naming" {
  command = plan

  assert {
    condition     = can(regex("^rs-.*", azurerm_route_server.this.name))
    error_message = "Route Server name should start with 'rs-' prefix"
  }

  assert {
    condition     = module.naming.resource_suffix != null
    error_message = "Naming module should generate resource suffix"
  }

  assert {
    condition     = length(module.naming.resource_suffix) > 0
    error_message = "Resource suffix should not be empty"
  }
}

#
# Test: Public IP Configuration
#
# Verifies that Public IP is configured correctly for Route Server requirements.
#
run "test_public_ip_configuration" {
  command = plan

  assert {
    condition     = azurerm_public_ip.route_server.allocation_method == "Static"
    error_message = "Public IP must use Static allocation method"
  }

  assert {
    condition     = azurerm_public_ip.route_server.sku == "Standard"
    error_message = "Public IP must use Standard SKU"
  }

  assert {
    condition     = azurerm_public_ip.route_server.location == "centralus"
    error_message = "Public IP should be in the same location as resource group"
  }

  assert {
    condition     = azurerm_public_ip.route_server.resource_group_name == "rg-test"
    error_message = "Public IP should be in the correct resource group"
  }
}

#
# Test: Diagnostics Disabled
#
# Verifies that diagnostics module is NOT created when disabled.
#
run "test_diagnostics_disabled" {
  command = plan

  variables {
    diagnostics = {
      enabled = false
    }
  }

  assert {
    condition     = length(module.diagnostics) == 0
    error_message = "Diagnostics module should not be created when disabled"
  }
}

#
# Test: Diagnostics Enabled
#
# Verifies that diagnostics module IS created when enabled with workspace ID.
#
run "test_diagnostics_enabled" {
  command = plan

  variables {
    diagnostics = {
      enabled                    = true
      log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
    }
  }

  assert {
    condition     = length(module.diagnostics) == 1
    error_message = "Diagnostics module should be created when enabled"
  }
}

#
# Test: Optional Tags Merge
#
# Verifies that optional tags are properly merged with namer module tags.
#
run "test_optional_tags" {
  command = plan

  variables {
    optional_tags = {
      CostCenter  = "IT-001"
      Criticality = "High"
    }
  }

  assert {
    condition     = azurerm_route_server.this.tags["CostCenter"] == "IT-001"
    error_message = "Optional tags should be merged into Route Server tags"
  }

  assert {
    condition     = azurerm_route_server.this.tags["Criticality"] == "High"
    error_message = "Optional tags should be preserved in merged tags"
  }

  assert {
    condition     = azurerm_public_ip.route_server.tags["CostCenter"] == "IT-001"
    error_message = "Optional tags should be merged into Public IP tags"
  }
}

#
# Test: Standard Tags from Namer
#
# Verifies that standard tags from namer module are applied.
#
run "test_standard_tags" {
  command = plan

  assert {
    condition     = module.naming.tags != null
    error_message = "Namer module should generate tags"
  }

  assert {
    condition     = length(module.naming.tags) > 0
    error_message = "Namer module tags should not be empty"
  }

  assert {
    condition     = contains(keys(azurerm_route_server.this.tags), "Environment")
    error_message = "Route Server tags should include Environment from namer"
  }

  assert {
    condition     = contains(keys(azurerm_route_server.this.tags), "Repository")
    error_message = "Route Server tags should include Repository from namer"
  }
}

#
# Test: Resource Outputs
#
# Verifies that Route Server outputs are generated correctly.
# Note: Virtual router ASN and IPs are "known after apply" so we only test known values.
#
run "test_resource_outputs" {
  command = plan

  assert {
    condition     = output.name != null
    error_message = "Route Server name output should not be null"
  }

  assert {
    condition     = output.name == azurerm_route_server.this.name
    error_message = "Output name should match resource name"
  }

  assert {
    condition     = can(regex("^rs-", output.name))
    error_message = "Route Server name output should start with 'rs-' prefix"
  }

  assert {
    condition     = azurerm_route_server.this.location == "centralus"
    error_message = "Route Server should be in correct location"
  }
}

#
# Test: Minimal Configuration
#
# Verifies that the module works with minimal required variables only.
#
run "test_minimal_configuration" {
  command = plan

  variables {
    name = {
      contact     = "minimal@example.com"
      environment = "dev"
      repository  = "test-repo"
      workload    = "min"
    }

    resource_group = {
      location = "eastus2"
      name     = "rg-min"
    }

    subnet = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-min/providers/Microsoft.Network/virtualNetworks/vnet-min/subnets/RouteServerSubnet"
    }

    diagnostics = {
      enabled = false
    }

    optional_tags = {}
  }

  assert {
    condition     = azurerm_route_server.this.name != null
    error_message = "Minimal configuration should create Route Server"
  }

  assert {
    condition     = azurerm_public_ip.route_server.name != null
    error_message = "Minimal configuration should create Public IP"
  }

  assert {
    condition     = azurerm_route_server.this.branch_to_branch_traffic_enabled == false
    error_message = "Minimal configuration should use secure default (branch-to-branch disabled)"
  }
}

#
# Test: No BGP Connections (Default)
#
# Verifies that Route Server works with no BGP connections configured.
# This is the default behavior when bgp_connections is not specified or empty.
#
run "test_no_bgp_connections" {
  command = plan

  variables {
    bgp_connections = {}
  }

  assert {
    condition     = length(azurerm_route_server_bgp_connection.this) == 0
    error_message = "No BGP connections should be created when bgp_connections is empty"
  }

  assert {
    condition     = output.bgp_connection_count == 0
    error_message = "BGP connection count should be 0 when no connections are configured"
  }
}

#
# Test: Multiple BGP Connections
#
# Verifies that multiple BGP peer connections can be configured.
# This tests the for_each functionality and proper resource creation.
#
run "test_multiple_bgp_connections" {
  command = plan

  variables {
    bgp_connections = {
      fortigate-primary = {
        peer_asn = 65001
        peer_ip  = "10.100.1.4"
      }
      fortigate-secondary = {
        peer_asn = 65001
        peer_ip  = "10.100.1.5"
      }
    }
  }

  assert {
    condition     = length(azurerm_route_server_bgp_connection.this) == 2
    error_message = "Two BGP connections should be created when two peers are configured"
  }

  assert {
    condition     = output.bgp_connection_count == 2
    error_message = "BGP connection count should be 2"
  }

  assert {
    condition     = azurerm_route_server_bgp_connection.this["fortigate-primary"].name == "bgp-fortigate-primary"
    error_message = "BGP connection name should follow 'bgp-{key}' convention"
  }

  assert {
    condition     = azurerm_route_server_bgp_connection.this["fortigate-primary"].peer_asn == 65001
    error_message = "BGP connection should use the specified peer ASN"
  }

  assert {
    condition     = azurerm_route_server_bgp_connection.this["fortigate-primary"].peer_ip == "10.100.1.4"
    error_message = "BGP connection should use the specified peer IP"
  }

  assert {
    condition     = azurerm_route_server_bgp_connection.this["fortigate-secondary"].peer_ip == "10.100.1.5"
    error_message = "Second BGP connection should have correct peer IP"
  }
}

#
# Test: BGP Connection Outputs
#
# Verifies that BGP connection outputs are generated correctly.
#
run "test_bgp_connection_outputs" {
  command = plan

  variables {
    bgp_connections = {
      nva1 = {
        peer_asn = 65002
        peer_ip  = "10.100.1.10"
      }
    }
  }

  assert {
    condition     = output.bgp_connections != null
    error_message = "BGP connections output should not be null"
  }

  assert {
    condition     = contains(keys(output.bgp_connections), "nva1")
    error_message = "BGP connections output should contain the configured connection key"
  }

  assert {
    condition     = output.bgp_connections["nva1"].peer_asn == 65002
    error_message = "BGP connection output should include peer ASN"
  }

  assert {
    condition     = output.bgp_connections["nva1"].peer_ip == "10.100.1.10"
    error_message = "BGP connection output should include peer IP"
  }

  assert {
    condition     = output.bgp_connections["nva1"].name == "bgp-nva1"
    error_message = "BGP connection output should include connection name"
  }

  assert {
    condition     = output.bgp_connection_ids != null
    error_message = "BGP connection IDs output should not be null"
  }
}

#
# Test: BGP Connection with Different ASNs
#
# Verifies that connections can use different ASNs for different peers.
#
run "test_bgp_connections_different_asns" {
  command = plan

  variables {
    bgp_connections = {
      fortigate = {
        peer_asn = 65001
        peer_ip  = "10.100.1.4"
      }
      paloalto = {
        peer_asn = 65002
        peer_ip  = "10.100.1.20"
      }
    }
  }

  assert {
    condition     = azurerm_route_server_bgp_connection.this["fortigate"].peer_asn == 65001
    error_message = "FortiGate connection should use ASN 65001"
  }

  assert {
    condition     = azurerm_route_server_bgp_connection.this["paloalto"].peer_asn == 65002
    error_message = "Palo Alto connection should use ASN 65002"
  }
}
