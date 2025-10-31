# FortiGate Appliance Configuration with FortiOS Provider

This module supports automated FortiGate appliance configuration using the [FortiOS Terraform Provider](https://registry.terraform.io/providers/fortinetdev/fortios/latest/docs). When enabled, Terraform will configure the FortiGate firewall settings after the Azure infrastructure is deployed.

## Overview

The FortiOS provider integration allows you to manage FortiGate configuration as code, including:

- **System Settings**: Hostname, timezone, NTP, DNS, admin settings
- **Network Interfaces**: Configure port1-port6 with IP addresses, roles, and access policies
- **Static Routes**: Default routes, management routes, and custom routing
- **High Availability**: HA cluster configuration with active-passive failover
- **Azure SDN Connector**: Integration with Azure for automated public IP failover
- **Firewall Policies**: Basic outbound/inbound traffic policies
- **Firewall Objects**: Address objects and service groups

## Architecture

```
┌────────────────────────────────────────────────────────┐
│  Terraform Module Workflow                              │
├────────────────────────────────────────────────────────┤
│                                                          │
│  1. Deploy Azure Infrastructure (azurerm provider)      │
│     ├── Virtual Machine                                 │
│     ├── Network Interfaces                              │
│     ├── Public IPs                                      │
│     ├── Network Security Groups                         │
│     └── Managed Disks                                   │
│                                                          │
│  2. Wait for FortiGate VM Boot (3-5 minutes)            │
│                                                          │
│  3. Configure FortiGate Appliance (fortios provider)    │
│     ├── System Settings (hostname, NTP, DNS)            │
│     ├── Interface Configuration (port1-port6)           │
│     ├── Static Routes (default, management)             │
│     ├── HA Configuration (if enabled)                   │
│     ├── Azure SDN Connector                             │
│     └── Firewall Policies                               │
│                                                          │
│  4. FortiGate Ready for Production Traffic              │
│                                                          │
└────────────────────────────────────────────────────────┘
```

## Quick Start

### Basic FortiGate Deployment with Appliance Configuration

**IMPORTANT**: This module requires you to configure the FortiOS provider externally. The provider must be configured in your root module and passed to the FortiGate module.

```hcl
# Configure FortiOS provider for FortiGate management
provider "fortios" {
  hostname = module.fortigate.port1_private_ip  # or use public IP if create_management_public_ip = true
  username = "azureadmin"
  password = data.azurerm_key_vault_secret.fgt_password.value
  port     = "8443"
  insecure = true  # Skip SSL verification (self-signed certs)
  timeout  = 300   # 5 minutes to allow VM boot time
  retries  = 30    # Retry connection attempts
}

module "fortigate" {
  source  = "app.terraform.io/infoex/fortigate/azurerm"
  version = "0.x.x"

  # Naming (terraform-namer integration)
  contact     = "ops@company.com"
  environment = "prd"
  location    = "centralus"
  repository  = "terraform-azurerm-fortigate"
  workload    = "firewall"

  # Azure Infrastructure
  resource_group_name = azurerm_resource_group.network.name
  size                = "Standard_F8s_v2"
  zone                = "1"

  # Network Configuration
  hamgmtsubnet_id  = azurerm_subnet.mgmt.id
  hasyncsubnet_id  = azurerm_subnet.sync.id
  publicsubnet_id  = azurerm_subnet.public.id
  privatesubnet_id = azurerm_subnet.private.id
  public_ip_id     = azurerm_public_ip.cluster_vip.id
  public_ip_name   = azurerm_public_ip.cluster_vip.name

  # Interface IP Configuration
  port1        = "10.0.1.10"  # Management
  port1gateway = "10.0.1.1"
  port2        = "10.0.2.10"  # WAN/Public
  port2gateway = "10.0.2.1"   # Default route
  port3        = "10.0.3.10"  # LAN/Private
  port4        = "10.0.4.10"  # HA Sync

  # Authentication
  adminusername = "azureadmin"
  adminpassword = data.azurerm_key_vault_secret.fgt_password.value  # From Key Vault

  # Managed Identity for Azure SDN Connector
  user_assigned_identity_id = azurerm_user_assigned_identity.fortigate.id

  # Boot Diagnostics
  boot_diagnostics_storage_endpoint = azurerm_storage_account.diag.primary_blob_endpoint

  # Management Access
  create_management_public_ip       = true
  management_access_cidrs           = ["203.0.113.0/24"]  # Your VPN/office IP

  # ===================================================
  # ENABLE FORTIGATE APPLIANCE CONFIGURATION
  # ===================================================
  enable_fortigate_configuration = true

  # Licensing
  license_type = "payg"
  arch         = "x86"
  fgtversion   = "7.6.3"
}
```

## Configuration Variables

### FortiOS Provider Configuration

**IMPORTANT**: The FortiOS provider must be configured in your root module (not within this module). The module requires only one variable to enable FortiOS resource creation:

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `enable_fortigate_configuration` | Enable FortiGate appliance configuration via FortiOS provider | `bool` | `false` | No |

**Provider Settings** (configure in your root module's provider block):

| Provider Argument | Description | Recommended Value |
|-------------------|-------------|-------------------|
| `hostname` | FortiGate management IP address | `module.fortigate.port1_private_ip` or public IP |
| `username` | Admin username | `var.adminusername` (same as module input) |
| `password` | Admin password | From Azure Key Vault secret |
| `port` | HTTPS admin port | `"8443"` (default) |
| `insecure` | Skip SSL verification | `true` (self-signed certs) |
| `timeout` | Connection timeout (seconds) | `300` (5 minutes for VM boot) |
| `retries` | Number of retry attempts | `30` (handles boot delay) |

### Connection Methods

The module supports three methods for connecting to FortiGate:

#### 1. Management Public IP (Recommended for Testing)

```hcl
create_management_public_ip = true
fortigate_hostname          = "management_ip"
management_access_cidrs     = ["YOUR_IP/32"]  # Restrict access
```

**Use when:**
- Development/testing environments
- You need direct internet access to FortiGate management
- Running Terraform from a public cloud CI/CD pipeline

**Security:**
- Always restrict access with `management_access_cidrs`
- Use strong passwords or Key Vault
- Consider NSG flow logs for audit trail

#### 2. Private IP via VPN/Bastion (Recommended for Production)

```hcl
create_management_public_ip = false
fortigate_hostname          = "10.0.1.10"  # Private management IP
```

**Use when:**
- Production environments
- Access via site-to-site VPN, ExpressRoute, or Azure Bastion
- Running Terraform from on-premises or Azure-connected environment

**Security:**
- No public exposure of management interface
- Access only via trusted networks
- Ideal for zero-trust architecture

#### 3. Custom Hostname/IP

```hcl
fortigate_hostname = "fortigate.internal.company.com"
```

**Use when:**
- Custom DNS resolution in place
- Using Azure Private DNS or on-premises DNS
- Load balancer in front of FortiGate cluster

## What Gets Configured

When `enable_fortigate_configuration = true`, the module configures:

### 1. System Settings

```hcl
# Configured automatically:
- Hostname: Based on terraform-namer output (e.g., "vm-firewall-cu-prd-kmi")
- Timezone: UTC (ID 12)
- Admin HTTPS port: From var.adminsport (default: 8443)
- Admin SSH port: 22
- Admin timeout: 480 minutes (8 hours)
- Config auto-save: Enabled
- GUI theme: Blue
```

### 2. DNS and NTP

```hcl
# DNS Servers:
- Primary: 168.63.129.16 (Azure DNS)
- Secondary: 8.8.8.8 (Google DNS backup)

# NTP Server:
- Server: time.windows.com (Azure Time)
- Sync interval: 60 seconds
```

### 3. Network Interfaces

```hcl
# port1 (Management):
- IP: var.port1/mask
- Role: LAN
- Access: HTTPS, SSH, HTTP, PING
- Alias: "mgmt"

# port2 (WAN/Public):
- IP: var.port2/mask
- Role: WAN
- Access: PING
- Alias: "wan"

# port3 (LAN/Private):
- IP: var.port3/mask
- Role: LAN
- Access: PING
- Alias: "lan"

# port4 (HA Sync):
- IP: var.port4/mask
- Role: LAN
- Access: PING
- Alias: "hasync"

# port5 (Optional DMZ):
- IP: var.port5/mask (if configured)
- Role: LAN
- Alias: "dmz"

# port6 (Optional DMZ2):
- IP: var.port6/mask (if configured)
- Role: LAN
- Alias: "dmz2"
```

### 4. Static Routes

```hcl
# Default Route:
- Destination: 0.0.0.0/0
- Gateway: var.port2gateway
- Interface: port2
- Distance: 10

# Azure Metadata Service Route:
- Destination: 168.63.129.16/32
- Gateway: var.port1gateway
- Interface: port1
- Distance: 5
```

### 5. High Availability (if configured)

```hcl
# HA Configuration (when var.active_peerip or var.passive_peerip is set):
- Group name: "azure-ha-cluster"
- Mode: Active-Passive
- Heartbeat: port4
- Monitor interfaces: port2, port3
- Session pickup: Enabled
- Priority: 200 (active) or 100 (passive)
- Override: Enabled (active) or Disabled (passive)
```

### 6. Azure SDN Connector

```hcl
# Azure SDN Connector (when var.user_assigned_identity_id is set):
- Name: "azure-sdn"
- Type: Azure
- Authentication: Managed Identity (IAM)
- Update interval: 60 seconds
- Tenant ID: From azurerm_client_config
- Subscription ID: From azurerm_client_config
- Resource Group: var.resource_group_name
```

**Purpose:** Enables automatic public IP failover during HA events

### 7. Firewall Policies

```hcl
# Outbound Policy (LAN to WAN):
- Source: port3 (LAN)
- Destination: port2 (WAN)
- Source address: Azure VNET (10.0.0.0/8)
- Destination address: all
- Service: ALL
- NAT: Enabled
- Action: Accept
- Logging: All traffic

# Inbound Policy (WAN to LAN):
- Source: port2 (WAN)
- Destination: port3 (LAN)
- Source address: all
- Destination address: Azure VNET (10.0.0.0/8)
- Service: ALL
- NAT: Disabled
- Action: Deny (explicit deny)
- Logging: All traffic
```

## High Availability Configuration

### Active-Passive HA Deployment

**IMPORTANT**: For HA deployments, configure separate FortiOS providers for each instance using provider aliases.

```hcl
# ============================================
# FORTIOS PROVIDERS FOR HA PAIR
# ============================================

# Provider for Active FortiGate
provider "fortios" {
  alias    = "active"
  hostname = module.fortigate_active.port1_private_ip
  username = "azureadmin"
  password = data.azurerm_key_vault_secret.fgt_password.value
  port     = "8443"
  insecure = true
  timeout  = 300
  retries  = 30
}

# Provider for Passive FortiGate
provider "fortios" {
  alias    = "passive"
  hostname = module.fortigate_passive.port1_private_ip
  username = "azureadmin"
  password = data.azurerm_key_vault_secret.fgt_password.value
  port     = "8443"
  insecure = true
  timeout  = 300
  retries  = 30
}

# ============================================
# ACTIVE FORTIGATE
# ============================================
module "fortigate_active" {
  source = "app.terraform.io/infoex/fortigate/azurerm"

  providers = {
    fortios = fortios.active  # Use active provider
  }

  # ... (same configuration as above) ...

  # HA Configuration
  is_passive      = false  # This is the ACTIVE instance
  active_peerip   = "10.0.4.11"  # Passive peer IP on port4
  passive_peerip  = "10.0.4.10"  # This instance IP on port4

  # FortiOS Configuration
  enable_fortigate_configuration = true
}

# ============================================
# PASSIVE FORTIGATE
# ============================================
module "fortigate_passive" {
  source = "app.terraform.io/infoex/fortigate/azurerm"

  providers = {
    fortios = fortios.passive  # Use passive provider
  }

  # ... (same configuration as above) ...

  # Different IPs for passive instance
  port1 = "10.0.1.11"
  port2 = "10.0.2.11"  # Public IP NOT associated (managed by HA)
  port3 = "10.0.3.11"
  port4 = "10.0.4.11"

  # HA Configuration
  is_passive      = true  # This is the PASSIVE instance
  active_peerip   = "10.0.4.10"  # Active peer IP on port4
  passive_peerip  = "10.0.4.11"  # This instance IP on port4

  # FortiOS Configuration
  enable_fortigate_configuration = true
}
```

### HA Failover Behavior

When configured with Azure SDN connector:

1. **Normal Operation:**
   - Active FortiGate processes all traffic
   - Passive FortiGate syncs configuration and monitors active
   - Public IP associated with active instance port2

2. **Failover Event:**
   - Passive detects active failure (heartbeat loss)
   - Passive promotes itself to active
   - Azure SDN connector moves public IP to new active
   - Typical failover time: 30-60 seconds

3. **Configuration Sync:**
   - All configuration changes synced from active to passive
   - Session tables synced in real-time
   - Firewall policies, routes, objects all synchronized

## Outputs

The module provides comprehensive outputs for FortiOS configuration:

```hcl
# FortiGate Configuration Status
output "fortigate_configuration_enabled" {
  value = true/false  # Indicates if FortiOS config is enabled
}

# Management Connection Info
output "fortigate_management_host" {
  value = "203.0.113.10"  # IP/hostname used for FortiOS API
}

# System Configuration
output "fortigate_system_hostname" {
  value = "vm-firewall-cu-prd-kmi"  # Hostname configured on FortiGate
}

# HA Status
output "fortigate_ha_enabled" {
  value = true/false  # Indicates if HA is configured
}

output "fortigate_ha_mode" {
  value = "active" | "passive"  # HA role of this instance
}

# Interfaces
output "fortigate_interfaces_configured" {
  value = [
    "port1 (mgmt)",
    "port2 (wan)",
    "port3 (lan)",
    "port4 (hasync)"
  ]
}

# Azure Integration
output "fortigate_azure_sdn_connector_enabled" {
  value = true/false  # Indicates if Azure SDN is configured
}

# Complete Summary
output "fortigate_configuration_summary" {
  value = {
    hostname              = "vm-firewall-cu-prd-kmi"
    management_url        = "https://203.0.113.10:8443"
    admin_username        = "azureadmin"
    ha_enabled            = true
    ha_role               = "active"
    azure_sdn_enabled     = true
    interfaces_count      = 4
    fortios_provider_host = "203.0.113.10"
    configuration_applied = true
  }
}
```

## Troubleshooting

### Common Issues

#### 1. Connection Timeout

**Error:**
```
Error: Error connecting to FortiOS API: timeout waiting for connection
```

**Solutions:**
- Increase `fortigate_connection_timeout` to 600 (10 minutes)
- Verify FortiGate VM is fully booted (check Azure serial console)
- Verify network connectivity from Terraform execution environment
- Check NSG rules allow traffic on `adminsport` (default: 8443)
- Verify management public IP is created if using "management_ip"

#### 2. SSL Certificate Verification Failed

**Error:**
```
Error: x509: certificate signed by unknown authority
```

**Solutions:**
- Set `fortigate_insecure_connection = true` (development/test only)
- For production, import FortiGate certificate to Terraform host trust store
- Use custom SSL certificate on FortiGate
- Configure proper DNS and PKI infrastructure

#### 3. Authentication Failed

**Error:**
```
Error: Authentication failed - invalid credentials
```

**Solutions:**
- Verify `adminusername` matches FortiGate admin user
- Verify `adminpassword` is correct (check Key Vault if used)
- Ensure password meets FortiGate complexity requirements
- Check if admin account is locked (console access required to unlock)

#### 4. HA Configuration Conflicts

**Error:**
```
Error: HA peer IP not reachable
```

**Solutions:**
- Verify `active_peerip` and `passive_peerip` are correct
- Ensure port4 subnet allows traffic between peers
- Verify no NSG rules blocking port4 traffic
- Check FortiGate port4 interface is up (use serial console)

#### 5. Azure SDN Connector Fails

**Error:**
```
Error: Azure SDN connector authentication failed
```

**Solutions:**
- Verify `user_assigned_identity_id` is valid
- Ensure managed identity has "Reader" role on subscription
- Ensure managed identity has "Network Contributor" on resource group
- Verify FortiGate can reach Azure metadata endpoint (168.63.129.16)

### Debugging Tips

#### Check FortiGate Boot Status

```bash
# Via Azure CLI
az vm boot-diagnostics get-boot-log \
  --resource-group rg-network-prod \
  --name vm-firewall-cu-prd-kmi
```

#### Test FortiOS API Connectivity

```bash
# From Terraform execution environment
curl -k https://203.0.113.10:8443/api/v2/cmdb/system/status

# Expected: JSON response with system status
# If timeout: Network/firewall issue
# If connection refused: FortiGate not booted yet
```

#### Enable Terraform Debug Logging

```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log
terraform apply
```

#### Check FortiGate Configuration Manually

```bash
# SSH to FortiGate
ssh azureadmin@203.0.113.10

# Check system status
get system status

# Check HA status
get system ha status

# Check Azure SDN connector
diagnose test application azured 1

# Check interfaces
get system interface physical

# Check routes
get router info routing-table all
```

## Security Best Practices

### Production Recommendations

1. **Never expose management interface publicly:**
   ```hcl
   create_management_public_ip = false
   fortigate_hostname          = "10.0.1.10"  # Private IP
   ```

2. **Always use Azure Key Vault for secrets:**
   ```hcl
   key_vault_id                = azurerm_key_vault.main.id
   admin_password_secret_name  = "fortigate-admin-password"
   adminpassword               = null  # Don't hardcode!
   ```

3. **Enable SSL verification in production:**
   ```hcl
   fortigate_insecure_connection = false  # Verify certificates
   ```

4. **Restrict management access:**
   ```hcl
   management_access_cidrs = [
     "10.0.0.0/8",           # Corporate network
     "172.16.100.0/24"       # VPN users
   ]
   ```

5. **Use managed identities:**
   ```hcl
   user_assigned_identity_id     = azurerm_user_assigned_identity.fortigate.id
   enable_system_assigned_identity = false  # Use user-assigned
   ```

6. **Enable comprehensive logging:**
   ```hcl
   enable_diagnostics            = true
   log_analytics_workspace_id    = azurerm_log_analytics_workspace.main.id
   enable_nsg_flow_logs          = true
   nsg_flow_logs_retention_days  = 90
   ```

## Limitations

1. **Initial Boot Time:** FortiGate VMs take 3-5 minutes to boot. The module retries connections automatically.

2. **Custom Policies:** The module provides basic firewall policies. Customize policies by:
   - Modifying `fortigate-config.tf` in the module
   - Creating additional FortiOS resources in your root module
   - Using FortiManager for centralized policy management

3. **Configuration Drift:** Changes made via FortiGate GUI will cause Terraform drift. Use `terraform apply` to revert.

4. **Provider Limitations:** FortiOS provider does not support all FortiGate features. Check [provider documentation](https://registry.terraform.io/providers/fortinetdev/fortios/latest/docs) for supported resources.

5. **Concurrent Modifications:** Do not modify FortiGate via GUI while Terraform is running.

## Next Steps

- Review [examples/](examples/) for complete deployment scenarios
- Check [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines
- See [CHANGELOG.md](CHANGELOG.md) for version history and breaking changes
- Refer to [FortiOS Provider Documentation](https://registry.terraform.io/providers/fortinetdev/fortios/latest/docs) for advanced configuration

## Support

For issues related to:
- **Azure Infrastructure**: File issue in this repository
- **FortiOS Configuration**: Check [FortiOS Provider Issues](https://github.com/fortinetdev/terraform-provider-fortios/issues)
- **FortiGate Product**: Contact [Fortinet Support](https://support.fortinet.com/)
