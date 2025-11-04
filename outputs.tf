# =============================================================================
# Route Server Outputs
# =============================================================================

output "id" {
  value       = azurerm_route_server.this.id
  description = "The resource ID of the Azure Route Server"
}

output "name" {
  value       = azurerm_route_server.this.name
  description = "The name of the Azure Route Server"
}

output "virtual_router_asn" {
  value       = azurerm_route_server.this.virtual_router_asn
  description = "The Autonomous System Number (ASN) of the Route Server. This is always 65515 for Azure Route Server and is used for BGP peering configuration with NVAs."
}

output "virtual_router_ips" {
  value       = azurerm_route_server.this.virtual_router_ips
  description = "The list of virtual router IP addresses (2 IPs for high availability). Use these IP addresses to configure BGP peering on your Network Virtual Appliances (NVAs)."
}

# =============================================================================
# Public IP Outputs
# =============================================================================

output "public_ip_address" {
  value       = azurerm_public_ip.route_server.ip_address
  description = "The public IP address assigned to the Route Server"
}

output "public_ip_id" {
  value       = azurerm_public_ip.route_server.id
  description = "The resource ID of the public IP address"
}

# =============================================================================
# Convenience Outputs
# =============================================================================

output "tags" {
  value       = azurerm_route_server.this.tags
  description = "The tags applied to the Route Server (merged standard tags from naming module and optional tags)"
}

# =============================================================================
# BGP Connection Outputs
# =============================================================================

output "bgp_connections" {
  value = {
    for key, conn in azurerm_route_server_bgp_connection.this : key => {
      id       = conn.id
      name     = conn.name
      peer_asn = conn.peer_asn
      peer_ip  = conn.peer_ip
    }
  }
  description = "Map of BGP peer connections with their resource IDs, names, peer ASNs, and peer IP addresses. Use this output to reference BGP connection details in other modules or for monitoring."
}

output "bgp_connection_ids" {
  value       = { for key, conn in azurerm_route_server_bgp_connection.this : key => conn.id }
  description = "Map of BGP connection names to their Azure resource IDs"
}

output "bgp_connection_count" {
  value       = length(azurerm_route_server_bgp_connection.this)
  description = "The number of BGP peer connections configured. Azure Route Server supports up to 8 connections."
}
