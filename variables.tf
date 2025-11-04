# =============================================================================
# Required Variables
# =============================================================================

variable "name" {
  type = object({
    contact     = string
    environment = string
    repository  = string
    workload    = string
    instance    = optional(string, "0")
  })
  description = "Naming configuration object containing contact email, environment name, repository name, workload identifier, and optional instance number for resource naming"
}

variable "resource_group" {
  type = object({
    location = string
    name     = string
  })
  description = "Resource group configuration object containing the Azure region location and resource group name where the Route Server will be deployed"
}

variable "subnet" {
  type = object({
    id = string
  })
  description = "Subnet configuration object containing the subnet ID for RouteServerSubnet (must be /27 or larger and named 'RouteServerSubnet')"

  validation {
    condition     = can(regex("RouteServerSubnet", var.subnet.id))
    error_message = "The subnet must be named 'RouteServerSubnet'. This is a requirement for Azure Route Server deployment."
  }
}

# =============================================================================
# Route Server Configuration
# =============================================================================

variable "branch_to_branch_traffic_enabled" {
  type        = bool
  description = "Enable branch-to-branch traffic between BGP peers. When enabled, Route Server propagates routes learned from one peer to other peers. Default is false for security. Only enable when you need NVAs to communicate with each other through the Route Server."
  default     = false
}

variable "sku" {
  type        = string
  description = "The SKU of the Route Server. Only 'Standard' is currently supported by Azure."
  default     = "Standard"

  validation {
    condition     = var.sku == "Standard"
    error_message = "Route Server only supports 'Standard' SKU. No other SKUs are available."
  }
}

# =============================================================================
# BGP Connection Configuration
# =============================================================================

variable "bgp_connections" {
  type = map(object({
    peer_asn = number
    peer_ip  = string
  }))
  description = <<-EOT
    Map of BGP peer connections to establish with Network Virtual Appliances (NVAs) or other BGP-capable devices.
    Each connection requires a unique name (map key), the peer's ASN, and the peer's IP address.

    The Route Server will use ASN 65515 (Azure-managed, cannot be changed).
    Route Server supports up to 8 BGP peer connections.

    IMPORTANT SECURITY NOTES:
    - BGP MD5 authentication is NOT YET supported by this module (planned for v0.1.0)
    - Ensure peer IPs are within the same VNet or peered VNets
    - Use Network Security Groups (NSGs) to restrict BGP access (TCP/179) to trusted NVA subnets only
    - Monitor BGP sessions for unauthorized peering attempts
    - Implement route filtering and prefix limits on NVA side

    Example:
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

    Common peer ASNs:
    - Private ASN range: 64512-65534 (for on-premises networks)
    - Private ASN range (RFC 6996): 4200000000-4294967294 (32-bit)
    - NVA vendors often use: 65001, 65002, etc.
  EOT
  default     = {}

  validation {
    condition     = length(var.bgp_connections) <= 8
    error_message = "Azure Route Server supports a maximum of 8 BGP peer connections. Current count: ${length(var.bgp_connections)}"
  }

  validation {
    condition = alltrue([
      for conn in var.bgp_connections :
      conn.peer_asn >= 1 && conn.peer_asn <= 4294967295
    ])
    error_message = "Peer ASN must be a valid BGP AS number between 1 and 4294967295 (32-bit ASN)."
  }

  validation {
    condition = alltrue([
      for conn in var.bgp_connections :
      can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", conn.peer_ip))
    ])
    error_message = "Peer IP must be a valid IPv4 address."
  }
}

# =============================================================================
# Public IP Configuration
# =============================================================================

variable "public_ip_allocation_method" {
  type        = string
  description = "The allocation method for the public IP address. Must be 'Static' for Standard SKU. Valid values: Static, Dynamic (Dynamic only for Basic SKU which is not supported)."
  default     = "Static"

  validation {
    condition     = var.public_ip_allocation_method == "Static"
    error_message = "Route Server requires Static allocation method for Standard SKU public IP."
  }
}

variable "public_ip_sku" {
  type        = string
  description = "The SKU of the public IP address. Must be 'Standard' for Route Server. Valid values: Standard, Basic (Basic is not supported)."
  default     = "Standard"

  validation {
    condition     = var.public_ip_sku == "Standard"
    error_message = "Route Server requires Standard SKU public IP. Basic SKU is not supported."
  }
}

# =============================================================================
# Diagnostics Configuration
# =============================================================================

variable "diagnostics" {
  type = object({
    enabled                    = bool
    log_analytics_workspace_id = optional(string)
  })
  description = "Diagnostics configuration object. When enabled is true, diagnostic logs are sent to the specified Log Analytics workspace for monitoring and analysis. The log_analytics_workspace_id is required when enabled is true."
  default = {
    enabled                    = false
    log_analytics_workspace_id = null
  }

  validation {
    condition     = !var.diagnostics.enabled || (var.diagnostics.enabled && var.diagnostics.log_analytics_workspace_id != null)
    error_message = "When diagnostics.enabled is true, diagnostics.log_analytics_workspace_id must be provided."
  }
}

# =============================================================================
# Tagging Configuration
# =============================================================================

variable "optional_tags" {
  type        = map(string)
  description = "Optional additional tags to apply to all resources. These tags are merged with the standard tags from the naming module (company, contact, environment, location, repository, workload)."
  default     = {}
}
