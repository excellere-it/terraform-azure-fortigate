# FortiGate Azure Module Architecture

This document provides a detailed overview of the module's architecture, file organization, and resource relationships.

## Module File Structure

```
terraform-azurerm-fortigate/
├── main.tf                    # Module overview and custom image resource
├── data.tf                    # Data sources (Azure client config)
├── locals.tf                  # Computed local values
├── network.tf                 # Networking resources (NSGs, NICs, Public IPs)
├── compute.tf                 # Compute resources (VMs, Managed Disks)
├── variables.tf               # Input variable definitions
├── outputs.tf                 # Output value definitions
├── versions.tf                # Provider version requirements
├── fortinet_agreement.tf      # Azure Marketplace agreement
├── config-active.conf         # Bootstrap config for active node
├── config-passive.conf        # Bootstrap config for passive node
├── README.md                  # Module documentation
├── CHANGELOG.md               # Version history
├── CONTRIBUTING.md            # Contribution guidelines
├── ARCHITECTURE.md            # This file
├── Makefile                   # Development automation
├── .terraform-docs.yml        # Terraform-docs configuration
├── .gitignore                 # Git ignore rules
├── examples/                  # Usage examples
│   └── default/              # Basic single-instance example
│       ├── main.tf
│       ├── variables.tf
│       └── versions.tf
└── test/                      # Automated tests
    ├── module_test.go
    ├── go.mod
    └── go.sum
```

## File Descriptions

### Core Module Files

#### `main.tf`
- **Purpose**: Module entry point and overview documentation
- **Contains**: Custom FortiGate image resource (optional)
- **Lines**: ~55
- **Key Resources**: `azurerm_image.custom`

#### `data.tf`
- **Purpose**: All data source declarations
- **Contains**: Azure client configuration data source
- **Lines**: ~16
- **Key Data Sources**: `azurerm_client_config.current`

#### `locals.tf`
- **Purpose**: Computed values and reusable expressions
- **Contains**:
  - VM ID selection logic
  - Bootstrap template variables
  - Network interface ID ordering
  - Lifecycle rule configurations
- **Lines**: ~47

#### `network.tf`
- **Purpose**: All networking resources
- **Contains**:
  - Public IP addresses
  - Network Security Groups (NSGs)
  - NSG rules
  - Network Interfaces (NICs) for all 4 ports
  - NSG-to-NIC associations
- **Lines**: ~325
- **Key Resources**:
  - `azurerm_public_ip.mgmt_ip`
  - `azurerm_network_security_group.publicnetworknsg`
  - `azurerm_network_security_group.privatenetworknsg`
  - `azurerm_network_interface.port[1-4]`

#### `compute.tf`
- **Purpose**: All compute resources
- **Contains**:
  - FortiGate VMs (custom and marketplace)
  - Managed disks
  - Disk attachments
- **Lines**: ~150
- **Key Resources**:
  - `azurerm_linux_virtual_machine.customfgtvm`
  - `azurerm_linux_virtual_machine.fgtvm`
  - `azurerm_managed_disk.fgt_data_drive`

#### `variables.tf`
- **Purpose**: Input variable definitions
- **Contains**: All module input variables with descriptions and validations
- **Lines**: ~350
- **Sections**:
  - Required Variables
  - Azure Infrastructure
  - Network Variables
  - Custom Image Variables
  - Licensing and Marketplace
  - Admin Credentials
  - Network Interface IPs
  - HA Configuration
  - Bootstrap and Tagging

#### `outputs.tf`
- **Purpose**: Output value definitions
- **Contains**: All module outputs organized by category
- **Lines**: ~145
- **Sections**:
  - Virtual Machine Outputs
  - Management & Access
  - Network Interface Outputs
  - Network Security Group Outputs
  - Storage Outputs

#### `versions.tf`
- **Purpose**: Terraform and provider version constraints
- **Contains**: Required Terraform version and azurerm provider version
- **Lines**: ~23

#### `fortinet_agreement.tf`
- **Purpose**: Azure Marketplace agreement acceptance
- **Contains**: Marketplace agreement resource for BYOL licensing
- **Lines**: ~29

## Resource Relationships

```
┌─────────────────────────────────────────────────────────┐
│                    Azure Subscription                    │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    Resource Group                        │
│                  (var.resource_group_name)               │
└─────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
   ┌─────────┐      ┌──────────────┐    ┌──────────────┐
   │  Image  │      │   Network    │    │   Compute    │
   │(optional)│     │  Resources   │    │  Resources   │
   └─────────┘      └──────────────┘    └──────────────┘
                            │                   │
        ┌───────────────────┼──────────┬────────┼───────────┐
        ▼                   ▼          ▼        ▼           ▼
   ┌─────────┐      ┌──────────┐  ┌─────┐  ┌──────┐  ┌─────────┐
   │ Public  │      │   NSGs   │  │NICs │  │  VM  │  │  Disk   │
   │   IP    │      │   (2)    │  │ (4) │  │      │  │Attachment│
   └─────────┘      └──────────┘  └─────┘  └──────┘  └─────────┘
                            │          │        │
                            └──────────┴────────┘
                                     │
                           NSG-NIC Associations
```

## Network Architecture

### 4-Port Configuration

```
                     ┌──────────────────────────┐
                     │    FortiGate VM          │
                     │                          │
  Internet ◄─────────┤ port1 (HA Management)    │◄───── Public IP (MGMT)
                     │   - 10.0.1.x/24          │
                     │   - NSG: publicnetworknsg│
                     ├──────────────────────────┤
  Internet ◄─────────┤ port2 (WAN/Public)       │◄───── Public IP (VIP)
                     │   - 10.0.2.x/24          │
                     │   - NSG: privatenetworknsg│
                     ├──────────────────────────┤
  Private  ◄─────────┤ port3 (LAN/Private)      │
  Network            │   - 10.0.3.x/24          │
                     │   - NSG: privatenetworknsg│
                     ├──────────────────────────┤
  HA Peer  ◄────────►│ port4 (HA Sync)          │◄────► HA Peer
                     │   - 10.0.4.x/24          │
                     │   - NSG: publicnetworknsg│
                     └──────────────────────────┘
```

### Network Security Groups

**publicnetworknsg** (port1, port4):
- Allows all inbound/outbound (should be restricted in production)
- Used for management and HA sync traffic
- Attached to: port1, port4

**privatenetworknsg** (port2, port3):
- Allows all inbound/outbound
- Used for data plane traffic
- FortiGate provides actual security inspection
- Attached to: port2, port3

## Resource Dependencies

### Creation Order

1. **Data Sources** (`data.tf`)
   - Azure client configuration lookup

2. **Network Security Groups** (`network.tf`)
   - NSG creation
   - NSG rules

3. **Network Resources** (`network.tf`)
   - Public IPs
   - Network Interfaces

4. **NSG Associations** (`network.tf`)
   - Link NSGs to NICs

5. **Virtual Machine** (`compute.tf`)
   - FortiGate VM (depends on NICs)

6. **Storage** (`compute.tf`)
   - Managed disk
   - Disk attachment (depends on VM)

### Implicit Dependencies

```
azurerm_client_config (data)
    │
    ├──> VM (uses in custom_data)
    │
azurerm_image.custom (if var.custom = true)
    │
    └──> VM (source_image_id)

azurerm_network_interface.portX
    │
    ├──> NSG associations
    └──> VM (network_interface_ids)

azurerm_linux_virtual_machine
    │
    └──> Disk attachment
```

## Local Values Usage

### `local.vm_id`
- **Purpose**: Select correct VM ID based on deployment type
- **Used by**: Disk attachment resource
- **Logic**: Returns custom VM ID if `var.custom = true`, else marketplace VM ID

### `local.bootstrap_vars`
- **Purpose**: Consolidate all bootstrap template variables
- **Used by**: Both VM resources in `custom_data`
- **Contains**: Network config, Azure SDN config, licensing info

### `local.network_interface_ids`
- **Purpose**: Maintain correct NIC ordering
- **Used by**: Both VM resources
- **Order**: [port1, port2, port3, port4]

## Bootstrap Configuration Flow

```
1. variables.tf defines input variables
        │
        ▼
2. locals.tf creates local.bootstrap_vars map
        │
        ▼
3. compute.tf uses templatefile() function
        │
        ▼
4. Template file (config-active.conf or config-passive.conf)
        │
        ▼
5. base64encode() for custom_data
        │
        ▼
6. Cloud-init applies configuration on first boot
```

## High Availability Architecture

### Active-Passive HA Pair

```
┌──────────────────┐                    ┌──────────────────┐
│  FortiGate       │   HA Heartbeat    │  FortiGate       │
│  Active          │◄──────────────────►│  Passive         │
│  Priority: 255   │    port4 sync     │  Priority: 1     │
│                  │                    │                  │
│  VIP: Active     │                    │  VIP: Standby    │
└──────────────────┘                    └──────────────────┘
         │                                       │
         └───────────────┬───────────────────────┘
                         │
                    Azure SDN
                    Connector
                         │
              ┌──────────┴──────────┐
              │                     │
         Update IPs          Update Routes
```

### HA Configuration Variables

- `active_peerip`: Set to passive node's port4 IP
- `passive_peerip`: Set to active node's port4 IP
- Both set to `null` for standalone deployment

## Lifecycle Management

### Resources with `prevent_destroy = true`

All critical resources have lifecycle protection:
- Public IPs
- Network Security Groups
- NSG Rules
- Network Interfaces
- NSG Associations
- Virtual Machines
- Managed Disks
- Disk Attachments

### Resources with `ignore_changes`

**port2 NIC**:
- `ignore_changes = [ip_configuration[0].public_ip_address_id]`
- Reason: HA failover changes public IP association

**Both VMs**:
- `ignore_changes = [custom_data]`
- Reason: Prevent VM recreation on bootstrap config changes

## Module Outputs Organization

Outputs are organized into logical groups:

1. **VM Information**: IDs, names, hostnames
2. **Management & Access**: URLs, IPs, credentials
3. **Network Interfaces**: IDs and IPs for all 4 ports
4. **Security**: NSG IDs and names
5. **Storage**: Data disk information

## Best Practices Implemented

1. **Separation of Concerns**: Logical file separation (network, compute, data)
2. **DRY Principle**: Local values eliminate repetition
3. **Clear Naming**: Descriptive resource and variable names
4. **Comprehensive Documentation**: Inline comments and external docs
5. **Input Validation**: Variable constraints and validations
6. **Secure Defaults**: Sensitive variables marked appropriately
7. **Lifecycle Protection**: Critical resources protected from deletion
8. **Flexible Deployment**: Support for multiple scenarios (BYOL/PAYG, x86/ARM, custom images)

## Testing Strategy

### Unit Tests (`test/module_test.go`)

- **TestFortiGateValidation**: Fast validation without deployment
- **TestFortiGateDefault**: Full deployment test (15-20 minutes)

### Manual Testing

Run through Makefile:
```bash
make validate    # Quick validation
make plan       # Preview changes
make deploy     # Deploy example
make destroy    # Clean up
```

## Future Enhancements

Potential additions to consider:

1. **Multiple Instance Support**: Module wrapper for HA pairs
2. **Additional Ports**: Support for more than 4 interfaces
3. **Auto-scaling**: Integration with Azure VMSS
4. **Advanced NSG Rules**: Template-based rule generation
5. **Monitoring**: Azure Monitor integration
6. **Backup**: Automated FortiGate config backup
