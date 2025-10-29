# Terraform Azure FortiGate Module

A comprehensive, production-ready Terraform module for deploying FortiGate Next-Generation Firewall VMs in Microsoft Azure with High Availability (HA) support, advanced security features, and comprehensive monitoring capabilities.

## Features

### Core Capabilities
- **High Availability (HA) Support**: Active-passive HA configuration with Azure SDN failover
- **Flexible Licensing**: BYOL (Bring Your Own License) and PAYG (Pay As You Go) models
- **Multiple Architectures**: Support for both x86 and ARM64 FortiGate instances
- **Custom Images**: Deploy from Azure Marketplace or custom VHD images
- **Flexible Network Architecture**: 4-6 network interfaces for management, WAN, LAN, HA sync, and optional DMZ/additional zones

### Security & Access Control
- **Azure Key Vault Integration**: Secure storage for passwords and service principal secrets
- **Configurable NSG Rules**: Dynamic management access restrictions with CIDR-based allow lists
- **Private-Only Deployment**: Optional removal of management public IP for VPN/ExpressRoute-only access
- **Comprehensive Input Validation**: 13+ validation rules ensuring configuration correctness

### Monitoring & Observability
- **Azure Monitor Integration**: VM metrics, network metrics, and NSG diagnostics
- **NSG Flow Logs**: Detailed traffic analysis with Traffic Analytics integration
- **Configurable Retention**: Separate policies for diagnostics and flow logs
- **Log Analytics Integration**: Centralized logging with KQL query support

### Enterprise Features
- **Lifecycle Protection**: Built-in prevent_destroy rules for production safety
- **Flexible Tagging Strategy**: Automatic, structured, and custom tags with validation
- **Configurable Disk Settings**: Customizable size, storage type, and caching modes
- **Bootstrap Configuration**: Automated initial configuration via cloud-init
- **Comprehensive Outputs**: Easy integration with other Terraform modules

## Architecture

This module deploys FortiGate with a flexible network interface architecture:

```
┌─────────────────────────────────────────────────┐
│         FortiGate VM (Azure)                    │
├─────────────────────────────────────────────────┤
│ port1 - HA Management (optional public IP)     │  → Management access
│ port2 - WAN/Public (with cluster VIP)          │  → External traffic
│ port3 - LAN/Private                            │  → Internal traffic
│ port4 - HA Sync                                │  → HA heartbeat/sync
│ port5 - Optional (DMZ/WAN2)                    │  → Additional zones
│ port6 - Optional (DMZ/WAN2)                    │  → Additional zones
└─────────────────────────────────────────────────┘
```

**Network Interfaces:**
- **port1 (HA Management)**: Administrative access, optional public IP
- **port2 (WAN/Public)**: External/internet-facing traffic with cluster VIP
- **port3 (LAN/Private)**: Internal network traffic
- **port4 (HA Sync)**: HA heartbeat and session synchronization
- **port5 (Optional)**: DMZ zones, additional WANs, dedicated monitoring
- **port6 (Optional)**: DMZ zones, additional WANs, dedicated monitoring

## Prerequisites

- **Terraform** >= 1.13.4
- **Azure Subscription** with appropriate permissions
- **Azure CLI** for authentication
- **Pre-existing Azure Infrastructure**:
  - Resource Group
  - Virtual Network with 4-6 subnets (depending on port requirements)
  - Public IP for cluster VIP (port2)
  - Storage account for boot diagnostics
  - Service Principal for Azure SDN connector
  - *(Optional)* Log Analytics workspace for monitoring
  - *(Optional)* Azure Key Vault for secret management

## Quick Start

### Basic PAYG Deployment

```hcl
module "fortigate" {
  source = "path/to/terraform-azurerm-fortigate"

  # VM Configuration
  name                = "fortigate-primary"
  computer_name       = "fgt-primary"
  size                = "Standard_F8s_v2"
  zone                = "1"
  location            = "eastus"
  resource_group_name = "rg-network-prod"

  # Network Configuration (4 required subnets)
  hamgmtsubnet_id  = azurerm_subnet.mgmt.id
  hasyncsubnet_id  = azurerm_subnet.sync.id
  publicsubnet_id  = azurerm_subnet.public.id
  privatesubnet_id = azurerm_subnet.private.id
  public_ip_id     = azurerm_public_ip.cluster_vip.id
  public_ip_name   = azurerm_public_ip.cluster_vip.name

  # Static IP Addresses
  port1 = "10.0.1.10"  # Management
  port2 = "10.0.2.10"  # WAN/Public
  port3 = "10.0.3.10"  # LAN/Private
  port4 = "10.0.4.10"  # HA Sync

  # Gateway Configuration
  port1gateway = "10.0.1.1"  # Management gateway
  port2gateway = "10.0.2.1"  # Default route

  # Authentication
  adminusername = "azureadmin"
  adminpassword = "YourSecurePassword123!"  # Use Key Vault in production
  client_secret = var.service_principal_secret

  # Boot Diagnostics
  boot_diagnostics_storage_endpoint = azurerm_storage_account.diag.primary_blob_endpoint

  # Licensing
  license_type = "payg"
  arch         = "x86"
  fgtversion   = "7.6.3"
}
```

## Configuration

### Input Variables

#### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `name` | FortiGate VM resource name | `string` |
| `computer_name` | FortiGate hostname (used as prefix for NICs, NSGs) | `string` |
| `resource_group_name` | Azure resource group name | `string` |
| `hamgmtsubnet_id` | Subnet ID for port1 (Management) | `string` |
| `hasyncsubnet_id` | Subnet ID for port4 (HA Sync) | `string` |
| `publicsubnet_id` | Subnet ID for port2 (WAN/Public) | `string` |
| `privatesubnet_id` | Subnet ID for port3 (LAN/Private) | `string` |
| `public_ip_id` | Public IP resource ID for cluster VIP | `string` |
| `public_ip_name` | Public IP name for Azure SDN connector | `string` |
| `boot_diagnostics_storage_endpoint` | Storage account URI for boot diagnostics | `string` |

#### Core Configuration Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `location` | Azure region | `string` | `"westus2"` |
| `size` | Azure VM size (must support required NIC count) | `string` | `"Standard_F8s_v2"` |
| `zone` | Availability zone (1, 2, or 3) | `string` | `"1"` |
| `license_type` | License type: "byol" or "payg" | `string` | `"payg"` |
| `arch` | Architecture: "x86" or "arm" | `string` | `"x86"` |
| `fgtversion` | FortiOS version | `string` | `"7.6.3"` |
| `bootstrap` | Bootstrap configuration file | `string` | `"config-active.conf"` |
| `custom` | Use custom image instead of marketplace | `bool` | `false` |

#### Network Configuration Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `port1` | Port1 (Management) private IP | `string` | `"172.1.3.10"` |
| `port2` | Port2 (WAN/Public) private IP | `string` | `"172.1.0.10"` |
| `port3` | Port3 (LAN/Private) private IP | `string` | `"172.1.1.10"` |
| `port4` | Port4 (HA Sync) private IP | `string` | `"172.1.2.10"` |
| `port1mask` | Port1 subnet mask | `string` | `"255.255.255.0"` |
| `port2mask` | Port2 subnet mask | `string` | `"255.255.255.0"` |
| `port3mask` | Port3 subnet mask | `string` | `"255.255.255.0"` |
| `port4mask` | Port4 subnet mask | `string` | `"255.255.255.0"` |
| `port1gateway` | Port1 gateway IP | `string` | `"172.1.3.1"` |
| `port2gateway` | Port2 gateway IP (default route) | `string` | `"172.1.0.1"` |
| `create_management_public_ip` | Create public IP for port1 | `bool` | `true` |

#### Optional Network Interfaces (port5, port6)

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `port5subnet_id` | Subnet ID for optional port5 | `string` | `null` |
| `port5` | Port5 private IP | `string` | `null` |
| `port6subnet_id` | Subnet ID for optional port6 | `string` | `null` |
| `port6` | Port6 private IP | `string` | `null` |

#### Authentication & Secrets

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `adminusername` | FortiGate admin username | `string` | `"azureadmin"` |
| `adminpassword` | Admin password (use Key Vault in production) | `string` | `null` |
| `adminsport` | HTTPS management port | `string` | `"8443"` |
| `client_secret` | Azure service principal secret | `string` | `null` |
| `key_vault_id` | Azure Key Vault resource ID for secrets | `string` | `null` |
| `admin_password_secret_name` | Key Vault secret name for admin password | `string` | `"fortigate-admin-password"` |
| `client_secret_secret_name` | Key Vault secret name for client secret | `string` | `"fortigate-client-secret"` |

#### Security & Access Control

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_management_access_restriction` | Restrict management access to specific CIDRs | `bool` | `true` |
| `management_access_cidrs` | CIDR blocks allowed for management access | `list(string)` | `[]` |
| `management_ports` | TCP ports for management access | `list(number)` | `[443, 8443, 22]` |

#### Storage & Disk Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `data_disk_size_gb` | Data disk size (1-32767 GB) | `number` | `30` |
| `data_disk_storage_type` | Storage type: Standard_LRS, StandardSSD_LRS, Premium_LRS, etc. | `string` | `"Standard_LRS"` |
| `data_disk_caching` | Caching mode: None, ReadOnly, ReadWrite | `string` | `"ReadWrite"` |

#### Monitoring & Diagnostics

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_diagnostics` | Enable Azure Monitor diagnostics | `bool` | `false` |
| `log_analytics_workspace_id` | Log Analytics workspace resource ID | `string` | `null` |
| `diagnostic_retention_days` | Diagnostic logs retention (0-365 days) | `number` | `30` |
| `enable_nsg_flow_logs` | Enable NSG flow logs | `bool` | `false` |
| `nsg_flow_logs_storage_account_id` | Storage account for flow logs | `string` | `null` |
| `nsg_flow_logs_retention_days` | Flow logs retention (0-365 days) | `number` | `7` |

#### High Availability

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `active_peerip` | Active FortiGate peer IP for HA | `string` | `null` |
| `passive_peerip` | Passive FortiGate peer IP for HA | `string` | `null` |

#### Resource Tagging

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `environment` | Environment name (e.g., Production, Staging) | `string` | `""` |
| `cost_center` | Cost center or billing code | `string` | `""` |
| `owner` | Owner or team responsible | `string` | `""` |
| `project` | Project name | `string` | `""` |
| `tags` | Additional custom tags | `map(string)` | `{}` |

### Outputs

#### VM & Management

| Output | Description |
|--------|-------------|
| `fortigate_vm_id` | FortiGate VM resource ID |
| `fortigate_vm_name` | FortiGate VM name |
| `fortigate_computer_name` | FortiGate hostname |
| `fortigate_management_url` | HTTPS management URL (null if no public IP) |
| `fortigate_admin_username` | Admin username |
| `management_public_ip` | Management public IP address (null if disabled) |
| `management_public_ip_id` | Management public IP resource ID (null if disabled) |

#### Network Interfaces

| Output | Description |
|--------|-------------|
| `port1_id` / `port1_private_ip` | Port1 (Management) resource ID and private IP |
| `port2_id` / `port2_private_ip` | Port2 (WAN/Public) resource ID and private IP |
| `port3_id` / `port3_private_ip` | Port3 (LAN/Private) resource ID and private IP |
| `port4_id` / `port4_private_ip` | Port4 (HA Sync) resource ID and private IP |
| `port5_id` / `port5_private_ip` | Port5 (Optional) resource ID and private IP (null if not configured) |
| `port6_id` / `port6_private_ip` | Port6 (Optional) resource ID and private IP (null if not configured) |
| `all_private_ips` | Map of all private IPs by port |

#### Security & Storage

| Output | Description |
|--------|-------------|
| `public_nsg_id` / `public_nsg_name` | Public NSG resource ID and name |
| `private_nsg_id` / `private_nsg_name` | Private NSG resource ID and name |
| `data_disk_id` / `data_disk_name` | Data disk resource ID and name |

#### Monitoring

| Output | Description |
|--------|-------------|
| `diagnostics_enabled` | Indicates if diagnostics are enabled |
| `nsg_flow_logs_enabled` | Indicates if NSG flow logs are enabled |
| `log_analytics_workspace_id` | Log Analytics workspace ID (if configured) |

## Advanced Configuration

### Security Features

#### Azure Key Vault Integration (Recommended for Production)

Store sensitive credentials in Azure Key Vault for enhanced security:

```hcl
# Create Key Vault secrets
resource "azurerm_key_vault_secret" "admin_password" {
  name         = "fortigate-admin-password"
  value        = "YourSecurePassword123!"
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "client_secret" {
  name         = "fortigate-client-secret"
  value        = azurerm_service_principal.fortigate.client_secret
  key_vault_id = azurerm_key_vault.main.id
}

# Use Key Vault in module
module "fortigate" {
  source = "path/to/terraform-azurerm-fortigate"

  # ... other configuration ...

  # Key Vault integration
  key_vault_id                 = azurerm_key_vault.main.id
  admin_password_secret_name   = "fortigate-admin-password"
  client_secret_secret_name    = "fortigate-client-secret"

  # Leave these as null when using Key Vault
  adminpassword = null
  client_secret = null
}
```

**Secret Resolution Priority:**
1. Azure Key Vault secrets (if `key_vault_id` is provided)
2. Direct variables (`adminpassword`, `client_secret`)
3. Default values (fallback)

**Requirements:**
- Terraform identity must have `Get` permission on Key Vault secrets
- Secrets must exist in Key Vault before applying

#### Management Access Control

Restrict FortiGate management access to specific IP ranges:

```hcl
module "fortigate" {
  source = "path/to/terraform-azurerm-fortigate"

  # ... other configuration ...

  # Enable management access restrictions
  enable_management_access_restriction = true

  # Only allow from corporate networks
  management_access_cidrs = [
    "203.0.113.0/24",      # Corporate office
    "198.51.100.0/24",     # Branch office
    "192.0.2.50/32",       # Admin workstation
  ]

  # Restrict to specific ports
  management_ports = [8443, 22]  # HTTPS and SSH only
}
```

**Dynamic NSG Rules:**
- Creates individual NSG rule for each CIDR/port combination
- Priorities automatically assigned starting from 1000
- Fallback unrestricted rule when `management_access_cidrs` is empty (development only)

#### Private-Only Deployment (No Management Public IP)

Deploy FortiGate accessible only via VPN/ExpressRoute:

```hcl
module "fortigate" {
  source = "path/to/terraform-azurerm-fortigate"

  # ... other configuration ...

  # Disable management public IP
  create_management_public_ip = false
}
```

**Access Methods:**
1. **Azure Bastion**: Connect via Bastion host
2. **VPN Gateway**: Site-to-site or point-to-site VPN
3. **ExpressRoute**: Private connection from on-premises
4. **Jump Host**: SSH tunnel through bastion VM

**Impact:**
- `fortigate_management_url` output will be `null`
- `management_public_ip` output will be `null`
- Access FortiGate using `port1_private_ip` via private connectivity

### Additional Network Interfaces

Add port5 and port6 for DMZ zones, multiple WANs, or dedicated monitoring:

```hcl
module "fortigate" {
  source = "path/to/terraform-azurerm-fortigate"

  # ... standard configuration (port1-port4) ...

  # Optional port5 (e.g., DMZ)
  port5subnet_id = azurerm_subnet.dmz.id
  port5          = "10.0.5.10"

  # Optional port6 (e.g., second WAN)
  port6subnet_id = azurerm_subnet.wan2.id
  port6          = "10.0.6.10"
}
```

**Use Cases:**
- **DMZ Zones**: Separate network segments for public-facing services
- **Multiple WANs**: Additional internet links or MPLS connections
- **Dedicated Monitoring**: Isolated interface for traffic analysis
- **Multi-Tenant**: Separate interfaces per tenant or application
- **Compliance**: Additional security zones for regulatory requirements

**Requirements:**
- VM size must support 6 NICs (e.g., Standard_F8s_v2 supports 8 NICs)
- Both `portXsubnet_id` and `portX` must be configured to enable interface
- Interfaces are attached in order: port1, port2, port3, port4, port5, port6

### Monitoring & Diagnostics

Enable comprehensive Azure Monitor integration:

```hcl
# Create Log Analytics workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-fortigate"
  location            = "eastus"
  resource_group_name = "rg-monitoring"
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Create storage account for flow logs
resource "azurerm_storage_account" "flow_logs" {
  name                     = "stfortigateflowlogs"
  location                 = "eastus"
  resource_group_name      = "rg-monitoring"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Configure monitoring
module "fortigate" {
  source = "path/to/terraform-azurerm-fortigate"

  # ... other configuration ...

  # Enable Azure Monitor diagnostics
  enable_diagnostics            = true
  log_analytics_workspace_id    = azurerm_log_analytics_workspace.main.id
  diagnostic_retention_days     = 30  # 0 for indefinite

  # Enable NSG Flow Logs with Traffic Analytics
  enable_nsg_flow_logs              = true
  nsg_flow_logs_storage_account_id  = azurerm_storage_account.flow_logs.id
  nsg_flow_logs_retention_days      = 7
}
```

**Collected Metrics & Logs:**

1. **Virtual Machine**: CPU, Memory, Disk I/O, Network I/O
2. **Network Interfaces**: Bytes sent/received, Packets, Errors (port1-port4)
3. **Network Security Groups**: Rule match events, Traffic counters
4. **NSG Flow Logs**: Source/dest IPs and ports, Protocol, Allow/deny decisions, Traffic Analytics (10-min intervals)

**Sample KQL Queries:**

```kusto
// VM CPU usage over time
AzureMetrics
| where ResourceProvider == "MICROSOFT.COMPUTE"
| where MetricName == "Percentage CPU"
| summarize avg(Average) by bin(TimeGenerated, 5m)

// NSG rule matches
AzureDiagnostics
| where Category == "NetworkSecurityGroupEvent"
| project TimeGenerated, ruleName_s, direction_s, sourceIP_s, destIP_s

// Top talkers from flow logs
AzureNetworkAnalytics_CL
| where SubType_s == "FlowLog"
| summarize TotalBytes = sum(FlowCount_d) by SrcIP_s, DestIP_s
| top 10 by TotalBytes
```

**Cost Optimization:**
- Diagnostics disabled by default to avoid unexpected costs
- Adjust retention based on requirements (0 = indefinite, higher cost)
- NSG flow logs can generate significant data in high-traffic environments

### High Availability Deployment

Deploy a complete HA pair with active-passive failover:

**1. Deploy Active FortiGate:**

```hcl
module "fortigate_active" {
  source = "path/to/terraform-azurerm-fortigate"

  name          = "fortigate-active"
  computer_name = "fgt-active"

  # Network configuration
  port1 = "10.0.1.10"
  port2 = "10.0.2.10"
  port3 = "10.0.3.10"
  port4 = "10.0.4.10"

  # HA configuration
  active_peerip  = "10.0.4.11"  # Passive port4 IP
  passive_peerip = null

  # Bootstrap for active node
  bootstrap = "config-active.conf"

  # ... other configuration ...
}
```

**2. Deploy Passive FortiGate:**

```hcl
module "fortigate_passive" {
  source = "path/to/terraform-azurerm-fortigate"

  name          = "fortigate-passive"
  computer_name = "fgt-passive"

  # Different IPs in same subnets
  port1 = "10.0.1.11"
  port2 = "10.0.2.11"
  port3 = "10.0.3.11"
  port4 = "10.0.4.11"

  # HA configuration
  active_peerip  = "10.0.4.10"  # Active port4 IP
  passive_peerip = "10.0.4.11"

  # Bootstrap for passive node
  bootstrap = "config-passive.conf"

  # ... other configuration (must match active) ...
}
```

**HA Configuration Notes:**
- Both FortiGates must be in the same Azure region and availability zone
- Service Principal needs permissions to update routes and IPs for failover
- Azure SDN connector handles automatic failover
- Cluster VIP (port2 public IP) moves between active/passive nodes

### Disk Configuration

Customize data disk for logs and configuration:

```hcl
module "fortigate" {
  source = "path/to/terraform-azurerm-fortigate"

  # ... other configuration ...

  # Production configuration with high-performance disk
  data_disk_size_gb      = 100           # Larger for extensive logging
  data_disk_storage_type = "Premium_LRS" # Premium SSD
  data_disk_caching      = "ReadWrite"   # Best for logs
}
```

**Disk Size Recommendations:**
- **Development**: 30 GB (default)
- **Production with local logging**: 50-100 GB
- **Production with FortiAnalyzer**: 30-50 GB

**Storage Types:**
- `Standard_LRS`: Standard HDD, lowest cost
- `StandardSSD_LRS`: Standard SSD, balanced performance
- `Premium_LRS`: Premium SSD, highest performance (requires Premium-capable VM size)
- `StandardSSD_ZRS`: Zone-redundant Standard SSD
- `Premium_ZRS`: Zone-redundant Premium SSD

### Resource Tagging

The module provides three layers of tagging:

**1. Automatic Tags** (always applied):
```hcl
{
  ManagedBy         = "Terraform"
  Module            = "terraform-azurerm-fortigate"
  FortiGateInstance = var.computer_name
}
```

**2. Structured Tags** (optional, validated):
```hcl
module "fortigate" {
  source = "path/to/terraform-azurerm-fortigate"

  # ... other configuration ...

  environment = "Production"
  cost_center = "IT-Network"
  owner       = "network-team@example.com"
  project     = "Network-Security"
}
```

**3. Custom Tags** (optional, merged with above):
```hcl
module "fortigate" {
  source = "path/to/terraform-azurerm-fortigate"

  # ... other configuration ...

  tags = {
    Purpose     = "EdgeFirewall"
    Backup      = "Daily"
    Compliance  = "PCI-DSS"
    Application = "Firewall"
  }
}
```

**Tag Merging Priority:**
1. Default tags (lowest priority)
2. Structured tags
3. Custom tags (highest priority - can override)

## Deployment Examples

### Example 1: Basic Single FortiGate (PAYG)

```hcl
module "fortigate" {
  source = "path/to/terraform-azurerm-fortigate"

  name                = "fgt-single"
  computer_name       = "fgt01"
  location            = "eastus"
  resource_group_name = "rg-network"

  # Network
  hamgmtsubnet_id  = azurerm_subnet.mgmt.id
  hasyncsubnet_id  = azurerm_subnet.sync.id
  publicsubnet_id  = azurerm_subnet.public.id
  privatesubnet_id = azurerm_subnet.private.id
  public_ip_id     = azurerm_public_ip.cluster.id
  public_ip_name   = azurerm_public_ip.cluster.name

  # IPs
  port1 = "10.0.1.10"
  port2 = "10.0.2.10"
  port3 = "10.0.3.10"
  port4 = "10.0.4.10"

  # Auth (Use strong password or Key Vault - see examples)
  adminusername = "azureadmin"
  adminpassword = "YourStr0ng!P@ssw0rd123"  # 12+ chars, mixed case, numbers, special chars
  client_secret = var.sp_secret

  # Boot diagnostics
  boot_diagnostics_storage_endpoint = azurerm_storage_account.diag.primary_blob_endpoint
}
```

### Example 2: Production with Full Security

```hcl
module "fortigate" {
  source = "path/to/terraform-azurerm-fortigate"

  name                = "fgt-prod"
  computer_name       = "fgt-prod-01"
  location            = "eastus"
  resource_group_name = "rg-network-prod"
  size                = "Standard_F8s_v2"
  zone                = "1"

  # Network
  hamgmtsubnet_id  = azurerm_subnet.mgmt.id
  hasyncsubnet_id  = azurerm_subnet.sync.id
  publicsubnet_id  = azurerm_subnet.public.id
  privatesubnet_id = azurerm_subnet.private.id
  public_ip_id     = azurerm_public_ip.cluster.id
  public_ip_name   = azurerm_public_ip.cluster.name

  # IPs
  port1        = "10.0.1.10"
  port2        = "10.0.2.10"
  port3        = "10.0.3.10"
  port4        = "10.0.4.10"
  port1gateway = "10.0.1.1"
  port2gateway = "10.0.2.1"

  # Security - Key Vault
  key_vault_id                 = azurerm_key_vault.main.id
  admin_password_secret_name   = "fortigate-admin-password"
  client_secret_secret_name    = "fortigate-client-secret"
  adminusername                = "fgtadmin"

  # Security - Private management
  create_management_public_ip = false

  # Security - Restricted management access
  enable_management_access_restriction = true
  management_access_cidrs              = ["203.0.113.0/24"]
  management_ports                     = [8443]

  # Monitoring
  enable_diagnostics            = true
  log_analytics_workspace_id    = azurerm_log_analytics_workspace.main.id
  diagnostic_retention_days     = 90
  enable_nsg_flow_logs          = true
  nsg_flow_logs_storage_account_id = azurerm_storage_account.flow.id

  # Storage
  data_disk_size_gb      = 100
  data_disk_storage_type = "Premium_LRS"

  # Tags
  environment = "Production"
  cost_center = "IT-Security"
  owner       = "security-team@example.com"
  project     = "NetworkSecurity"

  boot_diagnostics_storage_endpoint = azurerm_storage_account.diag.primary_blob_endpoint
}
```

### Example 3: Advanced with DMZ and Monitoring

```hcl
module "fortigate" {
  source = "path/to/terraform-azurerm-fortigate"

  name                = "fgt-dmz"
  computer_name       = "fgt-dmz-01"
  location            = "eastus"
  resource_group_name = "rg-network"
  size                = "Standard_F8s_v2"

  # Standard 4 ports
  hamgmtsubnet_id  = azurerm_subnet.mgmt.id
  hasyncsubnet_id  = azurerm_subnet.sync.id
  publicsubnet_id  = azurerm_subnet.public.id
  privatesubnet_id = azurerm_subnet.private.id
  public_ip_id     = azurerm_public_ip.cluster.id
  public_ip_name   = azurerm_public_ip.cluster.name

  # Standard IPs
  port1 = "10.0.1.10"
  port2 = "10.0.2.10"
  port3 = "10.0.3.10"
  port4 = "10.0.4.10"

  # Additional ports for DMZ
  port5subnet_id = azurerm_subnet.dmz.id
  port5          = "10.0.5.10"
  port6subnet_id = azurerm_subnet.wan2.id
  port6          = "10.0.6.10"

  # Key Vault
  key_vault_id                 = azurerm_key_vault.main.id
  admin_password_secret_name   = "fgt-admin-pwd"
  client_secret_secret_name    = "fgt-sp-secret"

  # Monitoring
  enable_diagnostics               = true
  log_analytics_workspace_id       = azurerm_log_analytics_workspace.main.id
  enable_nsg_flow_logs             = true
  nsg_flow_logs_storage_account_id = azurerm_storage_account.flow.id

  boot_diagnostics_storage_endpoint = azurerm_storage_account.diag.primary_blob_endpoint

  tags = {
    Environment = "Production"
    Purpose     = "DMZ-Firewall"
  }
}
```

## Testing

The module includes a comprehensive test suite using Terraform's native testing framework.

### Running Tests

```bash
# Run all tests
terraform test

# Run specific test file
terraform test -filter=tests/basic.tftest.hcl

# Run with verbose output
terraform test -verbose
```

### Test Coverage

- **Basic Configuration** (`tests/basic.tftest.hcl`): VM creation, NICs, NSGs, data disks, outputs
- **Security Features** (`tests/security.tftest.hcl`): Private deployment, NSG rules, Key Vault, tagging
- **Advanced Features** (`tests/advanced.tftest.hcl`): Additional NICs, monitoring, HA, disk config
- **Input Validation** (`tests/validation.tftest.hcl`): All variable validation rules

See [tests/README.md](tests/README.md) for detailed testing documentation.

## Troubleshooting

### VM Size Requirements

**Error**: "Network interface count exceeds maximum for VM size"

**Solution**: Ensure your VM size supports the required number of NICs:
- 4 NICs (standard): Most F-series and D-series VMs (e.g., Standard_F4s_v2, Standard_D4s_v3)
- 6 NICs (with port5/port6): Use Standard_F8s_v2, Standard_D8s_v3, or larger

Verify NIC support: https://docs.microsoft.com/en-us/azure/virtual-machines/sizes

### Azure Marketplace Agreement

**Error**: "MarketplacePurchaseEligibilityFailed"

**Solution**: Accept the FortiGate marketplace terms:

```bash
# Accept marketplace terms
az vm image terms accept \
  --publisher fortinet \
  --offer fortinet_fortigate-vm_v5 \
  --plan fortinet_fg-vm_payg_2023

# Verify acceptance
az vm image terms show \
  --publisher fortinet \
  --offer fortinet_fortigate-vm_v5 \
  --plan fortinet_fg-vm_payg_2023
```

Or set `accept = "true"` in variables (requires manual acceptance on first run).

### NSG Flow Logs Failure

**Error**: "Network Watcher not found in region"

**Solution**: NSG flow logs require Network Watcher to be enabled in the region. Network Watcher is automatically created in most regions, but verify:

```bash
# Check if Network Watcher exists
az network watcher list --output table

# Create Network Watcher if missing
az network watcher configure \
  --resource-group NetworkWatcherRG \
  --locations eastus \
  --enabled true
```

### HA Failover Issues

**Problem**: Failover not working between active/passive nodes

**Checklist**:
1. Verify Service Principal has correct permissions (Network Contributor on resource group)
2. Check `active_peerip` and `passive_peerip` are correctly configured
3. Verify both FortiGates can communicate on port4 (HA sync)
4. Check Azure SDN connector configuration in FortiGate
5. Review FortiGate HA status: `get system ha status`
6. Check NSG rules allow HA sync traffic on port4

## License

This module is provided as-is. FortiGate licensing (BYOL or PAYG) is subject to Fortinet's terms and conditions.

## Support

- **Issues**: Report bugs or request features via GitHub Issues
- **Documentation**: See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed architecture
- **Examples**: See [examples/](examples/) directory for complete deployment examples

## References

- [FortiGate Azure Documentation](https://docs.fortinet.com/azure)
- [Azure Virtual Machine Sizes](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes)
- [FortiGate HA on Azure](https://docs.fortinet.com/document/fortigate-public-cloud/latest/azure-administration-guide/161167/ha-for-fortigate-vm-on-azure)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

---

**Version**: 2.0.0
**Last Updated**: 2025-01-25
**Terraform**: >= 1.13.4
**Azure Provider**: >= 3.0.0

<!-- BEGIN_TF_DOCS -->


## Requirements

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13.4 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.0 |

## Providers

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.117.1 |

## Resources

The following resources are created by this module:

## Resources

| Name | Type |
|------|------|
| [azurerm_image.custom](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/image) | resource |
| [azurerm_linux_virtual_machine.customfgtvm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_linux_virtual_machine.fgtvm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_managed_disk.fgt_data_drive](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) | resource |
| [azurerm_marketplace_agreement.fortinet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/marketplace_agreement) | resource |
| [azurerm_monitor_diagnostic_setting.port1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.port2](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.port3](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.port4](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.private_nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.public_nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_network_interface.port1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface.port2](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface.port3](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface.port4](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface.port5](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface.port6](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface_security_group_association.port1nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | resource |
| [azurerm_network_interface_security_group_association.port2nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | resource |
| [azurerm_network_interface_security_group_association.port3nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | resource |
| [azurerm_network_interface_security_group_association.port4nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | resource |
| [azurerm_network_security_group.privatenetworknsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_group.publicnetworknsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_rule.incoming_private](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.management_access](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.management_access_unrestricted](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.outgoing_private](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.outgoing_public](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_watcher_flow_log.private_nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_watcher_flow_log) | resource |
| [azurerm_network_watcher_flow_log.public_nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_watcher_flow_log) | resource |
| [azurerm_public_ip.mgmt_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_virtual_machine_data_disk_attachment.fgt_log_drive_attachment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_key_vault_secret.admin_password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) | data source |
| [azurerm_key_vault_secret.client_secret](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) | data source |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_accept"></a> [accept](#input\_accept) | Accept Azure Marketplace agreement for FortiGate. Set to 'true' to accept terms on first deployment | `string` | `"false"` | no |
| <a name="input_active_peerip"></a> [active\_peerip](#input\_active\_peerip) | IP address of the active FortiGate peer in HA cluster. Used for HA synchronization. Set to null for standalone deployment | `string` | `null` | no |
| <a name="input_admin_password_secret_name"></a> [admin\_password\_secret\_name](#input\_admin\_password\_secret\_name) | Name of the Key Vault secret containing FortiGate admin password. Only used when key\_vault\_id is provided | `string` | `"fortigate-admin-password"` | no |
| <a name="input_adminpassword"></a> [adminpassword](#input\_adminpassword) | Administrator password for FortiGate VM. Leave null to use Azure Key Vault secret | `string` | `null` | no |
| <a name="input_adminsport"></a> [adminsport](#input\_adminsport) | HTTPS port for FortiGate web administration interface | `string` | `"8443"` | no |
| <a name="input_adminusername"></a> [adminusername](#input\_adminusername) | Administrator username for FortiGate VM | `string` | `"azureadmin"` | no |
| <a name="input_arch"></a> [arch](#input\_arch) | FortiGate VM architecture: 'x86' or 'arm' | `string` | `"x86"` | no |
| <a name="input_boot_diagnostics_storage_endpoint"></a> [boot\_diagnostics\_storage\_endpoint](#input\_boot\_diagnostics\_storage\_endpoint) | Storage account endpoint URI for boot diagnostics logs | `string` | n/a | yes |
| <a name="input_bootstrap"></a> [bootstrap](#input\_bootstrap) | Path to FortiGate bootstrap configuration file. Contains initial FortiGate config including network, HA, and policy settings | `string` | `"config-active.conf"` | no |
| <a name="input_client_secret"></a> [client\_secret](#input\_client\_secret) | Azure service principal client secret for Azure SDN connector. Leave null to use Azure Key Vault secret | `string` | `null` | no |
| <a name="input_client_secret_secret_name"></a> [client\_secret\_secret\_name](#input\_client\_secret\_secret\_name) | Name of the Key Vault secret containing Azure service principal client secret. Only used when key\_vault\_id is provided | `string` | `"fortigate-client-secret"` | no |
| <a name="input_contact"></a> [contact](#input\_contact) | Contact email for resource ownership and notifications. Used for tagging and operational communication. | `string` | n/a | yes |
| <a name="input_create_management_public_ip"></a> [create\_management\_public\_ip](#input\_create\_management\_public\_ip) | Create a public IP address for FortiGate management interface (port1). Set to false for private-only access via VPN/ExpressRoute | `bool` | `true` | no |
| <a name="input_custom"></a> [custom](#input\_custom) | Use custom FortiGate image instead of Azure Marketplace image. Set to true to deploy from VHD blob | `bool` | `false` | no |
| <a name="input_custom_image_resource_group_name"></a> [custom\_image\_resource\_group\_name](#input\_custom\_image\_resource\_group\_name) | Resource group name where custom image will be created. If null, uses var.resource\_group\_name. Only used when var.custom = true | `string` | `null` | no |
| <a name="input_customuri"></a> [customuri](#input\_customuri) | Azure blob URI for custom FortiGate VHD image. Only used when var.custom = true | `string` | `null` | no |
| <a name="input_data_disk_caching"></a> [data\_disk\_caching](#input\_data\_disk\_caching) | Disk caching mode for data disk. Options: None, ReadOnly, ReadWrite | `string` | `"ReadWrite"` | no |
| <a name="input_data_disk_size_gb"></a> [data\_disk\_size\_gb](#input\_data\_disk\_size\_gb) | Size of the FortiGate data disk in GB for logs and configuration storage | `number` | `30` | no |
| <a name="input_data_disk_storage_type"></a> [data\_disk\_storage\_type](#input\_data\_disk\_storage\_type) | Storage account type for data disk. Options: Standard\_LRS, StandardSSD\_LRS, Premium\_LRS, StandardSSD\_ZRS, Premium\_ZRS | `string` | `"Standard_LRS"` | no |
| <a name="input_diagnostic_retention_days"></a> [diagnostic\_retention\_days](#input\_diagnostic\_retention\_days) | Number of days to retain diagnostic logs. Set to 0 for indefinite retention | `number` | `30` | no |
| <a name="input_enable_diagnostics"></a> [enable\_diagnostics](#input\_enable\_diagnostics) | Enable Azure Monitor diagnostic settings for FortiGate VM and network resources | `bool` | `false` | no |
| <a name="input_enable_management_access_restriction"></a> [enable\_management\_access\_restriction](#input\_enable\_management\_access\_restriction) | Enable restricted management access. If true, only specified CIDRs can access management interface | `bool` | `true` | no |
| <a name="input_enable_nsg_flow_logs"></a> [enable\_nsg\_flow\_logs](#input\_enable\_nsg\_flow\_logs) | Enable NSG flow logs for network traffic analysis. Requires enable\_diagnostics = true | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name for the FortiGate deployment. Used for naming, tagging, and environment-specific configuration. | `string` | n/a | yes |
| <a name="input_fgtoffer"></a> [fgtoffer](#input\_fgtoffer) | Azure Marketplace offer for FortiGate VM | `string` | `"fortinet_fortigate-vm_v5"` | no |
| <a name="input_fgtsku"></a> [fgtsku](#input\_fgtsku) | FortiGate SKU mapping by architecture (x86/arm) and license type (byol/payg) | `map(any)` | <pre>{<br/>  "arm": {<br/>    "byol": "fortinet_fg-vm_arm64",<br/>    "payg": "fortinet_fg-vm_payg_2023_arm64"<br/>  },<br/>  "x86": {<br/>    "byol": "fortinet_fg-vm_g2",<br/>    "payg": "fortinet_fg-vm_payg_2023_g2"<br/>  }<br/>}</pre> | no |
| <a name="input_fgtversion"></a> [fgtversion](#input\_fgtversion) | FortiOS version to deploy from Azure Marketplace | `string` | `"7.6.3"` | no |
| <a name="input_hamgmtsubnet_id"></a> [hamgmtsubnet\_id](#input\_hamgmtsubnet\_id) | Azure subnet ID for port1 (HA Management interface). Used for FortiGate administrative access | `string` | n/a | yes |
| <a name="input_hasyncsubnet_id"></a> [hasyncsubnet\_id](#input\_hasyncsubnet\_id) | Azure subnet ID for port4 (HA Sync interface). Used for HA heartbeat and session synchronization | `string` | n/a | yes |
| <a name="input_key_vault_id"></a> [key\_vault\_id](#input\_key\_vault\_id) | Azure Key Vault resource ID for retrieving secrets. If provided, secrets will be read from Key Vault | `string` | `null` | no |
| <a name="input_license"></a> [license](#input\_license) | Path to FortiGate BYOL license file (e.g., 'license.lic'). Only required when license\_type = 'byol' | `string` | `"license.txt"` | no |
| <a name="input_license_format"></a> [license\_format](#input\_license\_format) | BYOL license format: 'file' (license file) or 'token' (FortiFlex token). Only applicable when license\_type = 'byol' | `string` | `"file"` | no |
| <a name="input_license_type"></a> [license\_type](#input\_license\_type) | FortiGate license type: 'byol' (Bring Your Own License) or 'payg' (Pay As You Go) | `string` | `"payg"` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region where FortiGate resources will be deployed (e.g., centralus, eastus2). Used for naming and resource placement. | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | Azure Log Analytics workspace resource ID for diagnostic logs and metrics. Required when enable\_diagnostics = true | `string` | `null` | no |
| <a name="input_management_access_cidrs"></a> [management\_access\_cidrs](#input\_management\_access\_cidrs) | List of CIDR blocks allowed to access FortiGate management interface (port1). Empty list allows from anywhere (not recommended) | `list(string)` | `[]` | no |
| <a name="input_management_ports"></a> [management\_ports](#input\_management\_ports) | List of TCP ports for FortiGate management access | `list(number)` | <pre>[<br/>  443,<br/>  8443,<br/>  22<br/>]</pre> | no |
| <a name="input_nsg_flow_logs_retention_days"></a> [nsg\_flow\_logs\_retention\_days](#input\_nsg\_flow\_logs\_retention\_days) | Number of days to retain NSG flow logs | `number` | `7` | no |
| <a name="input_nsg_flow_logs_storage_account_id"></a> [nsg\_flow\_logs\_storage\_account\_id](#input\_nsg\_flow\_logs\_storage\_account\_id) | Storage account resource ID for NSG flow logs. Required when enable\_nsg\_flow\_logs = true | `string` | `null` | no |
| <a name="input_passive_peerip"></a> [passive\_peerip](#input\_passive\_peerip) | IP address of the passive FortiGate peer in HA cluster. Used for HA synchronization. Set to null for standalone deployment | `string` | `null` | no |
| <a name="input_port1"></a> [port1](#input\_port1) | Static private IP address for port1 (HA Management interface) | `string` | `"172.1.3.10"` | no |
| <a name="input_port1gateway"></a> [port1gateway](#input\_port1gateway) | Default gateway IP for port1 (HA Management interface) | `string` | `"172.1.3.1"` | no |
| <a name="input_port1mask"></a> [port1mask](#input\_port1mask) | Subnet mask for port1 (HA Management interface) | `string` | `"255.255.255.0"` | no |
| <a name="input_port2"></a> [port2](#input\_port2) | Static private IP address for port2 (WAN/Public interface) | `string` | `"172.1.0.10"` | no |
| <a name="input_port2gateway"></a> [port2gateway](#input\_port2gateway) | Default gateway IP for port2 (WAN/Public interface). Used as default route for internet traffic | `string` | `"172.1.0.1"` | no |
| <a name="input_port2mask"></a> [port2mask](#input\_port2mask) | Subnet mask for port2 (WAN/Public interface) | `string` | `"255.255.255.0"` | no |
| <a name="input_port3"></a> [port3](#input\_port3) | Static private IP address for port3 (LAN/Private interface) | `string` | `"172.1.1.10"` | no |
| <a name="input_port3mask"></a> [port3mask](#input\_port3mask) | Subnet mask for port3 (LAN/Private interface) | `string` | `"255.255.255.0"` | no |
| <a name="input_port4"></a> [port4](#input\_port4) | Static private IP address for port4 (HA Sync interface) | `string` | `"172.1.2.10"` | no |
| <a name="input_port4mask"></a> [port4mask](#input\_port4mask) | Subnet mask for port4 (HA Sync interface) | `string` | `"255.255.255.0"` | no |
| <a name="input_port5"></a> [port5](#input\_port5) | Static private IP address for optional port5 interface. Set to null to disable port5 | `string` | `null` | no |
| <a name="input_port5subnet_id"></a> [port5subnet\_id](#input\_port5subnet\_id) | Azure subnet ID for optional port5 interface. Set to null to disable port5 | `string` | `null` | no |
| <a name="input_port6"></a> [port6](#input\_port6) | Static private IP address for optional port6 interface. Set to null to disable port6 | `string` | `null` | no |
| <a name="input_port6subnet_id"></a> [port6subnet\_id](#input\_port6subnet\_id) | Azure subnet ID for optional port6 interface. Set to null to disable port6 | `string` | `null` | no |
| <a name="input_privatesubnet_id"></a> [privatesubnet\_id](#input\_privatesubnet\_id) | Azure subnet ID for port3 (LAN/Private interface). Used for internal network traffic | `string` | n/a | yes |
| <a name="input_public_ip_id"></a> [public\_ip\_id](#input\_public\_ip\_id) | Azure public IP resource ID to associate with port2 for external connectivity. Managed by HA failover | `string` | n/a | yes |
| <a name="input_public_ip_name"></a> [public\_ip\_name](#input\_public\_ip\_name) | Name of the Azure public IP used for HA cluster VIP. Used in FortiGate SDN connector configuration | `string` | n/a | yes |
| <a name="input_publicsubnet_id"></a> [publicsubnet\_id](#input\_publicsubnet\_id) | Azure subnet ID for port2 (WAN/Public interface). Used for external/internet-facing traffic | `string` | n/a | yes |
| <a name="input_publisher"></a> [publisher](#input\_publisher) | Azure Marketplace publisher for FortiGate images | `string` | `"fortinet"` | no |
| <a name="input_repository"></a> [repository](#input\_repository) | Source repository name for tracking and documentation. Used for tagging to trace infrastructure source. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the Azure resource group where FortiGate will be deployed | `string` | n/a | yes |
| <a name="input_size"></a> [size](#input\_size) | Azure VM size for FortiGate. Must support at least 4 network interfaces for HA deployment | `string` | `"Standard_F8s_v2"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional custom tags to apply to all resources. Merged with terraform-namer tags. Example: { CostCenter = "IT-001", Owner = "security-team", Project = "firewall-migration" } | `map(string)` | `{}` | no |
| <a name="input_workload"></a> [workload](#input\_workload) | Workload or application name for resource identification. Used in resource naming (e.g., 'firewall', 'security'). | `string` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | Azure availability zone for FortiGate deployment (1, 2, or 3) | `string` | `"1"` | no |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_all_private_ips"></a> [all\_private\_ips](#output\_all\_private\_ips) | Map of all FortiGate private IP addresses by port (includes optional port5/port6) |
| <a name="output_common_tags"></a> [common\_tags](#output\_common\_tags) | The complete set of tags applied to all resources (terraform-namer + module-specific + user-provided) |
| <a name="output_data_disk_id"></a> [data\_disk\_id](#output\_data\_disk\_id) | Azure resource ID of the FortiGate data disk (used for logs) |
| <a name="output_data_disk_name"></a> [data\_disk\_name](#output\_data\_disk\_name) | Name of the FortiGate data disk |
| <a name="output_diagnostics_enabled"></a> [diagnostics\_enabled](#output\_diagnostics\_enabled) | Indicates if Azure Monitor diagnostics are enabled |
| <a name="output_fortigate_admin_username"></a> [fortigate\_admin\_username](#output\_fortigate\_admin\_username) | Administrator username for FortiGate login |
| <a name="output_fortigate_computer_name"></a> [fortigate\_computer\_name](#output\_fortigate\_computer\_name) | Computer name (hostname) of the FortiGate VM |
| <a name="output_fortigate_management_url"></a> [fortigate\_management\_url](#output\_fortigate\_management\_url) | HTTPS URL for FortiGate management interface (GUI access). Null if create\_management\_public\_ip = false |
| <a name="output_fortigate_vm_id"></a> [fortigate\_vm\_id](#output\_fortigate\_vm\_id) | Azure resource ID of the FortiGate virtual machine |
| <a name="output_fortigate_vm_name"></a> [fortigate\_vm\_name](#output\_fortigate\_vm\_name) | Name of the FortiGate virtual machine |
| <a name="output_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#output\_log\_analytics\_workspace\_id) | Log Analytics workspace ID used for diagnostics (if configured) |
| <a name="output_management_public_ip"></a> [management\_public\_ip](#output\_management\_public\_ip) | Public IP address for FortiGate management interface (port1). Null if create\_management\_public\_ip = false (private-only deployment) |
| <a name="output_management_public_ip_id"></a> [management\_public\_ip\_id](#output\_management\_public\_ip\_id) | Azure resource ID of the management public IP. Null if create\_management\_public\_ip = false |
| <a name="output_naming_suffix"></a> [naming\_suffix](#output\_naming\_suffix) | The standardized naming suffix from terraform-namer (e.g., 'firewall-centralus-prd-kmi-0') |
| <a name="output_naming_suffix_short"></a> [naming\_suffix\_short](#output\_naming\_suffix\_short) | The short naming suffix from terraform-namer (e.g., 'firewall-cu-prd-kmi-0') |
| <a name="output_naming_suffix_vm"></a> [naming\_suffix\_vm](#output\_naming\_suffix\_vm) | The VM-optimized naming suffix (max 15 chars) from terraform-namer |
| <a name="output_nsg_flow_logs_enabled"></a> [nsg\_flow\_logs\_enabled](#output\_nsg\_flow\_logs\_enabled) | Indicates if NSG flow logs are enabled |
| <a name="output_port1_id"></a> [port1\_id](#output\_port1\_id) | Azure resource ID of port1 network interface (HA Management) |
| <a name="output_port1_private_ip"></a> [port1\_private\_ip](#output\_port1\_private\_ip) | Private IP address of port1 (HA Management interface) |
| <a name="output_port2_id"></a> [port2\_id](#output\_port2\_id) | Azure resource ID of port2 network interface (WAN/Public) |
| <a name="output_port2_private_ip"></a> [port2\_private\_ip](#output\_port2\_private\_ip) | Private IP address of port2 (WAN/Public interface) |
| <a name="output_port3_id"></a> [port3\_id](#output\_port3\_id) | Azure resource ID of port3 network interface (LAN/Private) |
| <a name="output_port3_private_ip"></a> [port3\_private\_ip](#output\_port3\_private\_ip) | Private IP address of port3 (LAN/Private interface) |
| <a name="output_port4_id"></a> [port4\_id](#output\_port4\_id) | Azure resource ID of port4 network interface (HA Sync) |
| <a name="output_port4_private_ip"></a> [port4\_private\_ip](#output\_port4\_private\_ip) | Private IP address of port4 (HA Sync interface) |
| <a name="output_port5_id"></a> [port5\_id](#output\_port5\_id) | Azure resource ID of port5 network interface (optional additional interface). Null if port5 not configured |
| <a name="output_port5_private_ip"></a> [port5\_private\_ip](#output\_port5\_private\_ip) | Private IP address of port5 (optional additional interface). Null if port5 not configured |
| <a name="output_port6_id"></a> [port6\_id](#output\_port6\_id) | Azure resource ID of port6 network interface (optional additional interface). Null if port6 not configured |
| <a name="output_port6_private_ip"></a> [port6\_private\_ip](#output\_port6\_private\_ip) | Private IP address of port6 (optional additional interface). Null if port6 not configured |
| <a name="output_private_nsg_id"></a> [private\_nsg\_id](#output\_private\_nsg\_id) | Azure resource ID of the private network security group (port2, port3) |
| <a name="output_private_nsg_name"></a> [private\_nsg\_name](#output\_private\_nsg\_name) | Name of the private network security group |
| <a name="output_public_nsg_id"></a> [public\_nsg\_id](#output\_public\_nsg\_id) | Azure resource ID of the public network security group (port1, port4) |
| <a name="output_public_nsg_name"></a> [public\_nsg\_name](#output\_public\_nsg\_name) | Name of the public network security group |

## Example Usage

```hcl
# =============================================================================
# FORTIGATE DEPLOYMENT EXAMPLE - SINGLE INSTANCE
# =============================================================================
# This example demonstrates deploying a single FortiGate VM in Azure with
# Pay-As-You-Go (PAYG) licensing. Suitable for development, testing, or
# small office deployments.
#
# Prerequisites:
# - Existing Resource Group
# - Virtual Network with 4 subnets (management, sync, public, private)
# - Public IP for cluster VIP
# - Storage account for boot diagnostics
# - Service principal for Azure SDN connector
# =============================================================================

# =============================================================================
# DATA SOURCES
# =============================================================================

# Get information about existing resource group
data "azurerm_resource_group" "example" {
  name = "rg-network-example"
}

# Get information about existing virtual network
data "azurerm_virtual_network" "example" {
  name                = "vnet-example"
  resource_group_name = data.azurerm_resource_group.example.name
}

# Get subnet information
data "azurerm_subnet" "mgmt" {
  name                 = "snet-mgmt"
  virtual_network_name = data.azurerm_virtual_network.example.name
  resource_group_name  = data.azurerm_resource_group.example.name
}

data "azurerm_subnet" "sync" {
  name                 = "snet-sync"
  virtual_network_name = data.azurerm_virtual_network.example.name
  resource_group_name  = data.azurerm_resource_group.example.name
}

data "azurerm_subnet" "public" {
  name                 = "snet-public"
  virtual_network_name = data.azurerm_virtual_network.example.name
  resource_group_name  = data.azurerm_resource_group.example.name
}

data "azurerm_subnet" "private" {
  name                 = "snet-private"
  virtual_network_name = data.azurerm_virtual_network.example.name
  resource_group_name  = data.azurerm_resource_group.example.name
}

# Get existing public IP for cluster VIP
data "azurerm_public_ip" "cluster_vip" {
  name                = "pip-fortigate-cluster"
  resource_group_name = data.azurerm_resource_group.example.name
}

# Get storage account for boot diagnostics
data "azurerm_storage_account" "diag" {
  name                = "stdiagexample"
  resource_group_name = data.azurerm_resource_group.example.name
}

# =============================================================================
# FORTIGATE MODULE
# =============================================================================

module "fortigate" {
  source = "../.."

  # Required: terraform-namer inputs for consistent naming and tagging
  # VM name and computer name are automatically generated from these variables
  contact     = "ops@example.com"
  environment = "dev"
  location    = "centralus"
  repository  = "terraform-azurerm-fortigate"
  workload    = "firewall"

  # VM Configuration
  size = "Standard_F8s_v2" # Must support 4 NICs
  zone = "1"               # Availability zone

  # Resource Group
  resource_group_name = data.azurerm_resource_group.example.name

  # Network Configuration - 4 Subnets Required
  hamgmtsubnet_id  = data.azurerm_subnet.mgmt.id    # port1 - Management
  hasyncsubnet_id  = data.azurerm_subnet.sync.id    # port4 - HA Sync
  publicsubnet_id  = data.azurerm_subnet.public.id  # port2 - WAN/Public
  privatesubnet_id = data.azurerm_subnet.private.id # port3 - LAN/Private

  # Public IP for port2 (cluster VIP)
  public_ip_id   = data.azurerm_public_ip.cluster_vip.id
  public_ip_name = data.azurerm_public_ip.cluster_vip.name

  # Management Public IP (port1)
  # Set to false for private-only deployments (VPN/ExpressRoute access)
  # When false, access FortiGate via port1 private IP (10.0.1.10)
  create_management_public_ip = true # Set to false for production with VPN access

  # Static IP Addresses (must be within subnet ranges)
  port1 = "10.0.1.10" # Management subnet
  port2 = "10.0.2.10" # Public subnet
  port3 = "10.0.3.10" # Private subnet
  port4 = "10.0.4.10" # Sync subnet

  # Subnet Masks
  port1mask = "255.255.255.0"
  port2mask = "255.255.255.0"
  port3mask = "255.255.255.0"
  port4mask = "255.255.255.0"

  # Gateway IPs
  port1gateway = "10.0.1.1" # Management gateway
  port2gateway = "10.0.2.1" # Default route gateway

  # Optional Additional Network Interfaces (port5, port6)
  # Uncomment to enable additional interfaces for DMZ, additional WANs, etc.
  # Ensure VM size supports 6 NICs (e.g., Standard_F8s_v2 supports 8 NICs)
  # port5subnet_id = data.azurerm_subnet.dmz.id
  # port5          = "10.0.5.10"
  #
  # port6subnet_id = data.azurerm_subnet.wan2.id
  # port6          = "10.0.6.10"

  # Authentication (CHANGE THESE IN PRODUCTION!)
  adminusername = "azureadmin"
  adminsport    = "8443" # HTTPS management port

  # Method 1: Azure Key Vault (Recommended for Production)
  # Uncomment these lines and comment out Method 2 to use Key Vault
  # key_vault_id                 = data.azurerm_key_vault.main.id
  # admin_password_secret_name   = "fortigate-admin-password"
  # client_secret_secret_name    = "fortigate-client-secret"

  # Method 2: Direct Variables (Development Only - NOT for production!)
  # For production, use Key Vault integration above
  # Password MUST be 12+ chars with uppercase, lowercase, numbers, and special characters
  adminpassword = "DevP@ssw0rd123!SecureExample"  # ⚠️  REPLACE with your own strong password!
  client_secret = var.service_principal_secret

  # Bootstrap Configuration
  bootstrap = "config-active.conf"

  # Boot Diagnostics
  boot_diagnostics_storage_endpoint = data.azurerm_storage_account.diag.primary_blob_endpoint

  # Licensing
  license_type = "payg" # Pay-As-You-Go
  arch         = "x86"  # x86 or arm

  # FortiOS Version
  fgtversion = "7.6.3"

  # HA Configuration (null for standalone)
  active_peerip  = null # Set for HA pair
  passive_peerip = null # Set for HA pair

  # Disk Configuration (optional)
  data_disk_size_gb      = 30             # 30 GB data disk
  data_disk_storage_type = "Standard_LRS" # Standard HDD
  data_disk_caching      = "ReadWrite"    # ReadWrite caching

  # Network Security Configuration
  # For production, restrict management access to specific CIDRs
  enable_management_access_restriction = false # Set to true for production
  management_access_cidrs              = []    # Add your admin IPs/networks here
  management_ports                     = [443, 8443, 22]

  # Monitoring & Diagnostics (optional)
  # Uncomment to enable Azure Monitor integration for VM and network metrics
  # enable_diagnostics            = true
  # log_analytics_workspace_id    = data.azurerm_log_analytics_workspace.main.id
  # diagnostic_retention_days     = 30
  #
  # # NSG Flow Logs (optional - requires enable_diagnostics)
  # enable_nsg_flow_logs              = true
  # nsg_flow_logs_storage_account_id  = data.azurerm_storage_account.flow_logs.id
  # nsg_flow_logs_retention_days      = 7

  # Additional Custom Tags (optional)
  # terraform-namer automatically provides: company, contact, environment, location, repository, workload
  # Add any additional tags you need below
  tags = {
    CostCenter  = "IT-Network"
    Owner       = "network-team@example.com"
    Project     = "Network-Security"
    Purpose     = "Testing"
    Backup      = "Daily"
    Application = "Firewall"
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "fortigate_vm_id" {
  description = "Azure resource ID of the FortiGate VM"
  value       = module.fortigate.fortigate_vm_id
}

output "fortigate_management_url" {
  description = "HTTPS URL for FortiGate management interface"
  value       = module.fortigate.fortigate_management_url
}

output "management_public_ip" {
  description = "Public IP address for FortiGate management"
  value       = module.fortigate.management_public_ip
}

output "port1_private_ip" {
  description = "Port1 (Management) private IP address"
  value       = module.fortigate.port1_private_ip
}

output "port2_private_ip" {
  description = "Port2 (WAN/Public) private IP address"
  value       = module.fortigate.port2_private_ip
}

output "port3_private_ip" {
  description = "Port3 (LAN/Private) private IP address"
  value       = module.fortigate.port3_private_ip
}

output "port4_private_ip" {
  description = "Port4 (HA Sync) private IP address"
  value       = module.fortigate.port4_private_ip
}
```
<!-- END_TF_DOCS -->