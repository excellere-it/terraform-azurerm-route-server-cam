# =============================================================================
# Module: Azure Route Server
# =============================================================================
#
# Purpose:
#   This module creates and manages Azure Route Server resources to enable
#   dynamic routing between Azure virtual networks and on-premises networks
#   using Border Gateway Protocol (BGP).
#
# Features:
#   - Azure Route Server deployment with Standard SKU
#   - Standard SKU Public IP address (required for Route Server)
#   - BGP configuration with optional branch-to-branch traffic
#   - Integration with Network Virtual Appliances (NVAs)
#   - Standardized naming using terraform-namer module
#   - Automatic tagging for governance and compliance
#   - Optional diagnostics integration for monitoring
#   - Support for multiple BGP peering scenarios
#
# Resources Created:
#   - azurerm_public_ip - Standard SKU public IP for Route Server
#   - azurerm_route_server - Azure Route Server instance
#   - module.diagnostics - Optional diagnostic settings (when enabled)
#
# Dependencies:
#   - terraform-namer-cam (app.terraform.io/cardi/namer-cam/terraform v0.0.1)
#   - azurerm provider >= 3.41 (for Route Server support)
#   - Optional: diagnostics-cam module (app.terraform.io/cardi/diagnostics-cam/azurerm v0.0.1)
#
# Common Use Cases:
#   1. Hub-Spoke with NVA Routing
#      - Deploy Route Server in hub VNet
#      - Peer with FortiGate, Palo Alto, or other NVAs
#      - Enable dynamic route propagation to spoke VNets
#
#   2. SD-WAN Integration
#      - Connect SD-WAN appliances via BGP
#      - Exchange routes between Azure and SD-WAN fabric
#      - Enable multi-cloud connectivity
#
#   3. Multi-NVA Redundancy
#      - Peer with multiple NVA instances for high availability
#      - Automatic failover through BGP route withdrawal
#      - Active-active or active-passive configurations
#
#   4. ExpressRoute Integration
#      - Use with ExpressRoute Gateway for on-premises connectivity
#      - Enable route exchange between ExpressRoute and NVAs
#      - Support hybrid cloud routing scenarios
#
# BGP Peering Scenarios:
#   - Route Server automatically uses ASN 65515 (Azure-managed)
#   - Supports up to 8 BGP peer connections
#   - Each peer connection requires NVA configuration (separate resource)
#   - Peering uses private IPs from RouteServerSubnet
#
# Important Notes:
#   - Route Server MUST be deployed in a dedicated subnet named "RouteServerSubnet"
#   - RouteServerSubnet must be /27 or larger (minimum 32 IP addresses)
#   - Standard SKU public IP is required (Basic SKU not supported)
#   - Route Server provides virtual router IPs (2 IPs for HA)
#   - ASN 65515 is fixed and cannot be changed
#   - Branch-to-branch traffic is DISABLED by default for security
#   - Route Server does NOT inspect or filter traffic (routing only)
#
# Security Considerations:
#   - Branch-to-branch traffic should only be enabled when needed
#   - NVAs should implement proper security controls (firewall, IDS/IPS)
#   - Use Network Security Groups (NSGs) on NVA subnets
#   - Monitor BGP sessions for unauthorized peering attempts
#   - Use Azure Policy to enforce Route Server deployment standards
#   - Implement least-privilege RBAC for Route Server management
#
# Performance Considerations:
#   - Route Server is highly available (active-active)
#   - Supports thousands of routes per BGP session
#   - Sub-second BGP convergence for failover scenarios
#   - No bandwidth limitations (control plane only)
#   - Recommended: Use Azure Accelerated Networking on NVAs
#
# Cost Considerations:
#   - Route Server has hourly charges (Standard SKU pricing)
#   - Public IP has separate hourly charges
#   - No charges for data transfer (control plane only)
#   - Consider cost impact of continuous operation vs. alternatives
#
# Monitoring and Diagnostics:
#   - Enable diagnostics to track Route Server events
#   - Monitor BGP peer status and route advertisements
#   - Use Azure Monitor for alerting on BGP session failures
#   - Review route propagation to VNet route tables
#
# =============================================================================

# Section: Naming and Tagging
# =============================================================================

module "naming" {
  source  = "app.terraform.io/cardi/namer-cam/terraform"
  version = "0.0.1"

  contact     = var.name.contact
  environment = var.name.environment
  location    = var.resource_group.location
  repository  = var.name.repository
  workload    = var.name.workload
  instance    = try(var.name.instance, "0")
}

# Section: Public IP Address
# =============================================================================
# Route Server requires a Standard SKU public IP address
# Static allocation is required for Standard SKU

resource "azurerm_public_ip" "route_server" {
  name                = "pip-${module.naming.resource_suffix}"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.public_ip_sku
  tags                = merge(module.naming.tags, var.optional_tags)

  lifecycle {
    precondition {
      condition     = var.public_ip_sku == "Standard"
      error_message = "Route Server requires Standard SKU public IP. Basic SKU is not supported."
    }
  }
}

# Section: Azure Route Server
# =============================================================================
# Route Server enables dynamic routing with BGP for hybrid connectivity

resource "azurerm_route_server" "this" {
  name                             = "rs-${module.naming.resource_suffix}"
  location                         = var.resource_group.location
  resource_group_name              = var.resource_group.name
  sku                              = var.sku
  public_ip_address_id             = azurerm_public_ip.route_server.id
  subnet_id                        = var.subnet.id
  branch_to_branch_traffic_enabled = var.branch_to_branch_traffic_enabled
  tags                             = merge(module.naming.tags, var.optional_tags)

  lifecycle {
    precondition {
      condition     = can(regex("RouteServerSubnet$", var.subnet.id))
      error_message = "Route Server must be deployed in a subnet named 'RouteServerSubnet'. Current subnet ID does not match this requirement."
    }
  }
}

# Section: BGP Connections
# =============================================================================
# Establishes BGP peering sessions with Network Virtual Appliances (NVAs)
# Route Server uses ASN 65515 (fixed) and provides 2 IPs for HA
# Each connection creates a BGP session for route exchange

resource "azurerm_route_server_bgp_connection" "this" {
  for_each = var.bgp_connections

  name            = "bgp-${each.key}"
  route_server_id = azurerm_route_server.this.id
  peer_asn        = each.value.peer_asn
  peer_ip         = each.value.peer_ip
}

# Section: Diagnostics (Optional)
# =============================================================================
# Enable diagnostic logging for Route Server monitoring

module "diagnostics" {
  count   = var.diagnostics.enabled ? 1 : 0
  source  = "app.terraform.io/cardi/diagnostics-cam/azurerm"
  version = "0.0.1"

  log_analytics_workspace_id = var.diagnostics.log_analytics_workspace_id

  monitored_services = {
    route_server = {
      id = azurerm_route_server.this.id
    }
  }
}
