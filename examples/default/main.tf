# =============================================================================
# Example: Basic Azure Route Server Deployment
# =============================================================================
# This example demonstrates deploying an Azure Route Server with:
# - Resource Group and Virtual Network
# - RouteServerSubnet with proper /27 sizing
# - Route Server with branch-to-branch traffic enabled
# - Diagnostics integration for monitoring
#
# Note: This creates real Azure resources and will incur costs

locals {
  location       = "centralus"
  test_namespace = random_pet.instance_id.id
}

resource "random_pet" "instance_id" {}

# =============================================================================
# Resource Group
# =============================================================================

resource "azurerm_resource_group" "this" {
  location = local.location
  name     = "rg-routeserver-${local.test_namespace}"
}

# =============================================================================
# Virtual Network
# =============================================================================

resource "azurerm_virtual_network" "this" {
  name                = "vnet-hub-${local.test_namespace}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.100.0.0/16"]
}

# =============================================================================
# NVA Subnet (for BGP peer demonstration)
# =============================================================================
# This subnet would typically host Network Virtual Appliances (NVAs)
# such as FortiGate, Palo Alto, or other firewall/routing appliances

resource "azurerm_subnet" "nva" {
  name                 = "NVASubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.100.1.0/24"]
}

# =============================================================================
# RouteServerSubnet
# =============================================================================
# Route Server requires a dedicated subnet named "RouteServerSubnet"
# Subnet must be /27 or larger (32 IP addresses minimum)

resource "azurerm_subnet" "route_server" {
  name                 = "RouteServerSubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.100.0.0/27"]
}

# =============================================================================
# Log Analytics Workspace (for diagnostics)
# =============================================================================

resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-routeserver-${local.test_namespace}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# =============================================================================
# Azure Route Server
# =============================================================================

module "route_server" {
  source = "../.."

  name = {
    contact     = "nobody@infoex.dev"
    environment = "sbx"
    repository  = "terraform-azurerm-route-server"
    workload    = "routing"
  }

  resource_group = {
    location = azurerm_resource_group.this.location
    name     = azurerm_resource_group.this.name
  }

  subnet = {
    id = azurerm_subnet.route_server.id
  }

  # Enable branch-to-branch traffic to allow NVAs to exchange routes
  branch_to_branch_traffic_enabled = true

  # BGP connections to Network Virtual Appliances
  # These would typically be firewall/routing appliances in the NVA subnet
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

  # Enable diagnostics for monitoring
  diagnostics = {
    enabled                    = true
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }

  optional_tags = {
    Example = "basic-route-server"
    Purpose = "demonstration"
  }
}

# =============================================================================
# Outputs
# =============================================================================

output "route_server_id" {
  description = "The ID of the Route Server"
  value       = module.route_server.id
}

output "route_server_name" {
  description = "The name of the Route Server"
  value       = module.route_server.name
}

output "virtual_router_asn" {
  description = "The ASN of the Route Server (always 65515)"
  value       = module.route_server.virtual_router_asn
}

output "virtual_router_ips" {
  description = "The virtual router IP addresses for BGP peering (2 IPs for HA)"
  value       = module.route_server.virtual_router_ips
}

output "public_ip_address" {
  description = "The public IP address of the Route Server"
  value       = module.route_server.public_ip_address
}

output "tags" {
  description = "The tags applied to the Route Server"
  value       = module.route_server.tags
}

output "bgp_connections" {
  description = "BGP peer connection details"
  value       = module.route_server.bgp_connections
}

output "bgp_connection_count" {
  description = "Number of BGP peer connections configured"
  value       = module.route_server.bgp_connection_count
}

# =============================================================================
# Example BGP Peering Configuration Notes
# =============================================================================
# This example demonstrates configuring BGP peering with NVAs using the
# bgp_connections variable in the Route Server module.
#
# NVA BGP configuration requirements:
# - Peer with the two IPs from virtual_router_ips output (for high availability)
# - Use ASN 65515 for the Route Server neighbor (Azure-managed, fixed)
# - Configure your NVA's own ASN (65001 in this example, typical for private ASNs)
# - Advertise routes from your NVA to Azure (on-premises networks, other clouds)
#
# In a production environment:
# - Deploy actual NVA instances in the NVA subnet (10.100.1.0/24)
# - Configure NVA with peer IPs matching bgp_connections (10.100.1.4, 10.100.1.5)
# - Enable BGP on NVAs with ASN 65001
# - Configure BGP neighbors on NVA pointing to virtual_router_ips
# - Implement route filtering and prefix limits on NVA side for security
