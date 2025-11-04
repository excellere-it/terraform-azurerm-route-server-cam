# Azure Route Server Terraform Module

This module creates and manages Azure Route Server resources for dynamic routing between Azure virtual networks and on-premises networks using BGP.

## Features

- Azure Route Server deployment with Standard SKU
- Standard SKU Public IP address (required for Route Server)
- BGP configuration with optional branch-to-branch traffic
- Integration with Network Virtual Appliances (NVAs)
- Standardized naming using terraform-namer module
- Automatic tagging for governance and compliance
- Optional diagnostics integration for monitoring
- Support for up to 8 BGP peer connections

## Prerequisites

- Terraform >= 1.6.0
- Azure subscription
- RouteServerSubnet (/27 or larger) in target VNet
- Azure CLI (for authentication)

## Quick Start

```hcl
module "route_server" {
  source = "path/to/terraform-azurerm-route-server"

  name = {
    contact     = "admin@example.com"
    environment = "prod"
    repository  = "infrastructure"
    workload    = "routing"
  }

  resource_group = {
    location = "eastus"
    name     = "rg-networking"
  }

  subnet = {
    id = azurerm_subnet.route_server_subnet.id
  }

  branch_to_branch_traffic_enabled = true

  diagnostics = {
    enabled                    = true
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }
}
```

## Important Notes

- Route Server must be deployed in a subnet named **RouteServerSubnet**
- RouteServerSubnet must be **/27 or larger** (minimum 32 IP addresses)
- Route Server uses fixed ASN **65515** (cannot be changed)
- Supports up to **8 BGP peer connections**
- Branch-to-branch traffic is **disabled by default** for security
- Standard SKU public IP is required (Basic SKU not supported)

## Common Use Cases

### 1. Hub-Spoke with NVA Routing
Deploy Route Server in hub VNet to enable dynamic routing with FortiGate, Palo Alto, or other NVAs.

### 2. SD-WAN Integration
Connect SD-WAN appliances via BGP for multi-cloud connectivity.

### 3. Multi-NVA Redundancy
Peer with multiple NVA instances for high availability with automatic failover.

### 4. ExpressRoute Integration
Use with ExpressRoute Gateway for hybrid cloud routing scenarios.

## BGP Peering

After deploying the Route Server:
1. Use `virtual_router_ips` output to configure NVA BGP peers
2. Use ASN `65515` for Route Server in NVA configuration
3. Configure BGP peering on NVAs using azurerm_route_server_bgp_connection

## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## License

See LICENSE file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

<!-- BEGIN_TF_DOCS -->


## Example

```hcl
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
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bgp_connections"></a> [bgp\_connections](#input\_bgp\_connections) | Map of BGP peer connections to establish with Network Virtual Appliances (NVAs) or other BGP-capable devices.<br/>Each connection requires a unique name (map key), the peer's ASN, and the peer's IP address.<br/><br/>The Route Server will use ASN 65515 (Azure-managed, cannot be changed).<br/>Route Server supports up to 8 BGP peer connections.<br/><br/>IMPORTANT SECURITY NOTES:<br/>- BGP MD5 authentication is NOT YET supported by this module (planned for v0.1.0)<br/>- Ensure peer IPs are within the same VNet or peered VNets<br/>- Use Network Security Groups (NSGs) to restrict BGP access (TCP/179) to trusted NVA subnets only<br/>- Monitor BGP sessions for unauthorized peering attempts<br/>- Implement route filtering and prefix limits on NVA side<br/><br/>Example:<br/>bgp\_connections = {<br/>  fortigate-primary = {<br/>    peer\_asn = 65001<br/>    peer\_ip  = "10.100.1.4"<br/>  }<br/>  fortigate-secondary = {<br/>    peer\_asn = 65001<br/>    peer\_ip  = "10.100.1.5"<br/>  }<br/>}<br/><br/>Common peer ASNs:<br/>- Private ASN range: 64512-65534 (for on-premises networks)<br/>- Private ASN range (RFC 6996): 4200000000-4294967294 (32-bit)<br/>- NVA vendors often use: 65001, 65002, etc. | <pre>map(object({<br/>    peer_asn = number<br/>    peer_ip  = string<br/>  }))</pre> | `{}` | no |
| <a name="input_branch_to_branch_traffic_enabled"></a> [branch\_to\_branch\_traffic\_enabled](#input\_branch\_to\_branch\_traffic\_enabled) | Enable branch-to-branch traffic between BGP peers. When enabled, Route Server propagates routes learned from one peer to other peers. Default is false for security. Only enable when you need NVAs to communicate with each other through the Route Server. | `bool` | `false` | no |
| <a name="input_diagnostics"></a> [diagnostics](#input\_diagnostics) | Diagnostics configuration object. When enabled is true, diagnostic logs are sent to the specified Log Analytics workspace for monitoring and analysis. The log\_analytics\_workspace\_id is required when enabled is true. | <pre>object({<br/>    enabled                    = bool<br/>    log_analytics_workspace_id = optional(string)<br/>  })</pre> | <pre>{<br/>  "enabled": false,<br/>  "log_analytics_workspace_id": null<br/>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | Naming configuration object containing contact email, environment name, repository name, workload identifier, and optional instance number for resource naming | <pre>object({<br/>    contact     = string<br/>    environment = string<br/>    repository  = string<br/>    workload    = string<br/>    instance    = optional(string, "0")<br/>  })</pre> | n/a | yes |
| <a name="input_optional_tags"></a> [optional\_tags](#input\_optional\_tags) | Optional additional tags to apply to all resources. These tags are merged with the standard tags from the naming module (company, contact, environment, location, repository, workload). | `map(string)` | `{}` | no |
| <a name="input_public_ip_allocation_method"></a> [public\_ip\_allocation\_method](#input\_public\_ip\_allocation\_method) | The allocation method for the public IP address. Must be 'Static' for Standard SKU. Valid values: Static, Dynamic (Dynamic only for Basic SKU which is not supported). | `string` | `"Static"` | no |
| <a name="input_public_ip_sku"></a> [public\_ip\_sku](#input\_public\_ip\_sku) | The SKU of the public IP address. Must be 'Standard' for Route Server. Valid values: Standard, Basic (Basic is not supported). | `string` | `"Standard"` | no |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | Resource group configuration object containing the Azure region location and resource group name where the Route Server will be deployed | <pre>object({<br/>    location = string<br/>    name     = string<br/>  })</pre> | n/a | yes |
| <a name="input_sku"></a> [sku](#input\_sku) | The SKU of the Route Server. Only 'Standard' is currently supported by Azure. | `string` | `"Standard"` | no |
| <a name="input_subnet"></a> [subnet](#input\_subnet) | Subnet configuration object containing the subnet ID for RouteServerSubnet (must be /27 or larger and named 'RouteServerSubnet') | <pre>object({<br/>    id = string<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bgp_connection_count"></a> [bgp\_connection\_count](#output\_bgp\_connection\_count) | The number of BGP peer connections configured. Azure Route Server supports up to 8 connections. |
| <a name="output_bgp_connection_ids"></a> [bgp\_connection\_ids](#output\_bgp\_connection\_ids) | Map of BGP connection names to their Azure resource IDs |
| <a name="output_bgp_connections"></a> [bgp\_connections](#output\_bgp\_connections) | Map of BGP peer connections with their resource IDs, names, peer ASNs, and peer IP addresses. Use this output to reference BGP connection details in other modules or for monitoring. |
| <a name="output_id"></a> [id](#output\_id) | The resource ID of the Azure Route Server |
| <a name="output_name"></a> [name](#output\_name) | The name of the Azure Route Server |
| <a name="output_public_ip_address"></a> [public\_ip\_address](#output\_public\_ip\_address) | The public IP address assigned to the Route Server |
| <a name="output_public_ip_id"></a> [public\_ip\_id](#output\_public\_ip\_id) | The resource ID of the public IP address |
| <a name="output_tags"></a> [tags](#output\_tags) | The tags applied to the Route Server (merged standard tags from naming module and optional tags) |
| <a name="output_virtual_router_asn"></a> [virtual\_router\_asn](#output\_virtual\_router\_asn) | The Autonomous System Number (ASN) of the Route Server. This is always 65515 for Azure Route Server and is used for BGP peering configuration with NVAs. |
| <a name="output_virtual_router_ips"></a> [virtual\_router\_ips](#output\_virtual\_router\_ips) | The list of virtual router IP addresses (2 IPs for high availability). Use these IP addresses to configure BGP peering on your Network Virtual Appliances (NVAs). |

## Resources

| Name | Type |
|------|------|
| [azurerm_public_ip.route_server](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_route_server.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_server) | resource |
| [azurerm_route_server_bgp_connection.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_server_bgp_connection) | resource |

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.41 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.117.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_diagnostics"></a> [diagnostics](#module\_diagnostics) | app.terraform.io/infoex/diagnostics/azurerm | 0.0.2 |
| <a name="module_naming"></a> [naming](#module\_naming) | app.terraform.io/infoex/namer/terraform | 0.0.3 |
<!-- END_TF_DOCS -->
