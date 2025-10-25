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

- **Terraform** >= 1.3.4
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
  source = "path/to/terraform-azure-fortigate"

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
  source = "path/to/terraform-azure-fortigate"

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
  source = "path/to/terraform-azure-fortigate"

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
  source = "path/to/terraform-azure-fortigate"

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
  source = "path/to/terraform-azure-fortigate"

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
  source = "path/to/terraform-azure-fortigate"

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
  source = "path/to/terraform-azure-fortigate"

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
  source = "path/to/terraform-azure-fortigate"

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
  source = "path/to/terraform-azure-fortigate"

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
  Module            = "terraform-azure-fortigate"
  FortiGateInstance = var.computer_name
}
```

**2. Structured Tags** (optional, validated):
```hcl
module "fortigate" {
  source = "path/to/terraform-azure-fortigate"

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
  source = "path/to/terraform-azure-fortigate"

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
  source = "path/to/terraform-azure-fortigate"

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

  # Auth
  adminusername = "azureadmin"
  adminpassword = "ChangeMe123!"
  client_secret = var.sp_secret

  # Boot diagnostics
  boot_diagnostics_storage_endpoint = azurerm_storage_account.diag.primary_blob_endpoint
}
```

### Example 2: Production with Full Security

```hcl
module "fortigate" {
  source = "path/to/terraform-azure-fortigate"

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
  source = "path/to/terraform-azure-fortigate"

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
**Terraform**: >= 1.3.4
**Azure Provider**: >= 3.0.0
