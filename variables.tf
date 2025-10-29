# =============================================================================
# FORTIGATE AZURE MODULE - VARIABLE DEFINITIONS
# =============================================================================
# This module deploys a FortiGate VM in Azure with HA capabilities
# Supports both custom images and Azure Marketplace images
# Supports both x86 and ARM64 architectures

# =============================================================================
# NAMING VARIABLES (terraform-namer)
# =============================================================================

variable "contact" {
  type        = string
  description = "Contact email for resource ownership and notifications. Used for tagging and operational communication."

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.contact))
    error_message = "Contact must be a valid email address (e.g., ops@company.com)"
  }
}

variable "environment" {
  type        = string
  description = "Environment name for the FortiGate deployment. Used for naming, tagging, and environment-specific configuration."

  validation {
    condition     = contains(["dev", "stg", "prd", "sbx", "tst", "ops", "hub"], var.environment)
    error_message = "Environment must be one of: dev, stg, prd, sbx, tst, ops, hub"
  }
}

variable "location" {
  type        = string
  description = "Azure region where FortiGate resources will be deployed (e.g., centralus, eastus2). Used for naming and resource placement."

  validation {
    condition = contains([
      "centralus", "eastus", "eastus2", "westus", "westus2", "westus3",
      "northcentralus", "southcentralus", "westcentralus",
      "canadacentral", "canadaeast",
      "brazilsouth",
      "northeurope", "westeurope",
      "uksouth", "ukwest",
      "francecentral", "francesouth",
      "germanywestcentral",
      "switzerlandnorth",
      "norwayeast",
      "eastasia", "southeastasia",
      "japaneast", "japanwest",
      "australiaeast", "australiasoutheast",
      "centralindia", "southindia", "westindia"
    ], var.location)
    error_message = "Location must be a valid Azure region (e.g., centralus, eastus2)"
  }
}

variable "repository" {
  type        = string
  description = "Source repository name for tracking and documentation. Used for tagging to trace infrastructure source."

  validation {
    condition     = length(var.repository) > 0
    error_message = "Repository name cannot be empty. Provide the infrastructure repository name (e.g., terraform-azurerm-fortigate)"
  }
}

variable "workload" {
  type        = string
  description = "Workload or application name for resource identification. Used in resource naming (e.g., 'firewall', 'security')."

  validation {
    condition     = length(var.workload) > 0 && length(var.workload) <= 20
    error_message = "Workload name must be 1-20 characters for Azure resource name constraints"
  }
}

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================
# Note: VM name and computer name are now automatically generated from terraform-namer
# to ensure consistent naming across all resources

variable "client_secret" {
  description = "Azure service principal client secret for Azure SDN connector. Leave null to use Azure Key Vault secret"
  type        = string
  default     = null
  sensitive   = true
}

variable "boot_diagnostics_storage_endpoint" {
  description = "Storage account endpoint URI for boot diagnostics logs"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure resource group where FortiGate will be deployed"
  type        = string
}

# =============================================================================
# AZURE INFRASTRUCTURE VARIABLES
# =============================================================================
# NOTE: location variable now defined in NAMING VARIABLES section above

# For HA, choose instance size that supports 4 NICs at minimum
# Reference: https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes
# x86 recommended: Standard_F8s_v2
# ARM recommended: Standard_D2ps_v5
variable "size" {
  description = "Azure VM size for FortiGate. Must support at least 4 network interfaces for HA deployment"
  type        = string
  default     = "Standard_F8s_v2"
}

# Availability zones only supported in certain regions
# Reference: https://docs.microsoft.com/en-us/azure/availability-zones/az-overview
variable "zone" {
  description = "Azure availability zone for FortiGate deployment (1, 2, or 3)"
  type        = string
  default     = "1"

  validation {
    condition     = contains(["1", "2", "3"], var.zone)
    error_message = "Zone must be '1', '2', or '3'."
  }
}

# =============================================================================
# NETWORK VARIABLES
# =============================================================================

variable "hamgmtsubnet_id" {
  description = "Azure subnet ID for port1 (HA Management interface). Used for FortiGate administrative access"
  type        = string
}

variable "hasyncsubnet_id" {
  description = "Azure subnet ID for port4 (HA Sync interface). Used for HA heartbeat and session synchronization"
  type        = string
}

variable "publicsubnet_id" {
  description = "Azure subnet ID for port2 (WAN/Public interface). Used for external/internet-facing traffic"
  type        = string
}

variable "privatesubnet_id" {
  description = "Azure subnet ID for port3 (LAN/Private interface). Used for internal network traffic"
  type        = string
}

variable "public_ip_id" {
  description = "Azure public IP resource ID to associate with port2 for external connectivity. Managed by HA failover"
  type        = string
}

variable "public_ip_name" {
  description = "Name of the Azure public IP used for HA cluster VIP. Used in FortiGate SDN connector configuration"
  type        = string
}

variable "create_management_public_ip" {
  description = "Create a public IP address for FortiGate management interface (port1). Set to false for private-only access via VPN/ExpressRoute"
  type        = bool
  default     = true
}

# Optional additional network interfaces (port5, port6)
# Used for advanced deployments: DMZ zones, additional WANs, dedicated monitoring, etc.
variable "port5subnet_id" {
  description = "Azure subnet ID for optional port5 interface. Set to null to disable port5"
  type        = string
  default     = null
}

variable "port6subnet_id" {
  description = "Azure subnet ID for optional port6 interface. Set to null to disable port6"
  type        = string
  default     = null
}

# =============================================================================
# CUSTOM IMAGE VARIABLES
# =============================================================================

variable "custom" {
  description = "Use custom FortiGate image instead of Azure Marketplace image. Set to true to deploy from VHD blob"
  type        = bool
  default     = false
}

variable "customuri" {
  description = "Azure blob URI for custom FortiGate VHD image. Only used when var.custom = true"
  type        = string
  default     = null
}

variable "custom_image_resource_group_name" {
  description = "Resource group name where custom image will be created. If null, uses var.resource_group_name. Only used when var.custom = true"
  type        = string
  default     = null
}

# =============================================================================
# FORTIGATE LICENSING AND MARKETPLACE VARIABLES
# =============================================================================

variable "license_type" {
  description = "FortiGate license type: 'byol' (Bring Your Own License) or 'payg' (Pay As You Go)"
  type        = string
  default     = "payg"

  validation {
    condition     = contains(["byol", "payg"], var.license_type)
    error_message = "License type must be either 'byol' or 'payg'."
  }
}

variable "arch" {
  description = "FortiGate VM architecture: 'x86' or 'arm'"
  type        = string
  default     = "x86"

  validation {
    condition     = contains(["x86", "arm"], var.arch)
    error_message = "Architecture must be either 'x86' or 'arm'."
  }
}

variable "accept" {
  description = "Accept Azure Marketplace agreement for FortiGate. Set to 'true' to accept terms on first deployment"
  type        = string
  default     = "false"
}

variable "license_format" {
  description = "BYOL license format: 'file' (license file) or 'token' (FortiFlex token). Only applicable when license_type = 'byol'"
  type        = string
  default     = "file"

  validation {
    condition     = contains(["file", "token"], var.license_format)
    error_message = "License format must be either 'file' or 'token'."
  }
}

variable "publisher" {
  description = "Azure Marketplace publisher for FortiGate images"
  type        = string
  default     = "fortinet"
}

variable "fgtoffer" {
  description = "Azure Marketplace offer for FortiGate VM"
  type        = string
  default     = "fortinet_fortigate-vm_v5"
}

# FortiGate SKU mapping by architecture and license type
# x86 architecture:
#   - BYOL: fortinet_fg-vm_g2
#   - PAYG: fortinet_fg-vm_payg_2023_g2
# ARM64 architecture:
#   - BYOL: fortinet_fg-vm_arm64
#   - PAYG: fortinet_fg-vm_payg_2023_arm64
variable "fgtsku" {
  description = "FortiGate SKU mapping by architecture (x86/arm) and license type (byol/payg)"
  type        = map(any)
  default = {
    x86 = {
      byol = "fortinet_fg-vm_g2"
      payg = "fortinet_fg-vm_payg_2023_g2"
    },
    arm = {
      byol = "fortinet_fg-vm_arm64"
      payg = "fortinet_fg-vm_payg_2023_arm64"
    }
  }
}

variable "fgtversion" {
  description = "FortiOS version to deploy from Azure Marketplace"
  type        = string
  default     = "7.6.3"
}

# =============================================================================
# FORTIGATE ADMIN CREDENTIALS
# =============================================================================

variable "adminusername" {
  description = "Administrator username for FortiGate VM"
  type        = string
  default     = "azureadmin"
}

# WARNING: Default password is insecure and should be changed in production
# RECOMMENDATION: Use Azure Key Vault (key_vault_id + admin_password_secret_name)
variable "adminpassword" {
  description = "Administrator password for FortiGate VM. Leave null to use Azure Key Vault secret"
  type        = string
  default     = null
  sensitive   = true
}

variable "key_vault_id" {
  description = "Azure Key Vault resource ID for retrieving secrets. If provided, secrets will be read from Key Vault"
  type        = string
  default     = null
}

variable "admin_password_secret_name" {
  description = "Name of the Key Vault secret containing FortiGate admin password. Only used when key_vault_id is provided"
  type        = string
  default     = "fortigate-admin-password"
}

variable "client_secret_secret_name" {
  description = "Name of the Key Vault secret containing Azure service principal client secret. Only used when key_vault_id is provided"
  type        = string
  default     = "fortigate-client-secret"
}

variable "license" {
  description = "Path to FortiGate BYOL license file (e.g., 'license.lic'). Only required when license_type = 'byol'"
  type        = string
  default     = "license.txt"
}

variable "adminsport" {
  description = "HTTPS port for FortiGate web administration interface"
  type        = string
  default     = "8443"

  validation {
    condition     = can(regex("^([1-9][0-9]{0,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$", var.adminsport))
    error_message = "Admin port must be a valid port number between 1 and 65535."
  }
}

# =============================================================================
# NETWORK INTERFACE IP CONFIGURATION
# =============================================================================

# Port1 (HA Management) IP Configuration
variable "port1" {
  description = "Static private IP address for port1 (HA Management interface)"
  type        = string
  default     = "172.1.3.10"

  validation {
    condition     = can(regex("^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$", var.port1))
    error_message = "Port1 IP must be a valid IPv4 address (e.g., 10.0.1.10)."
  }
}

variable "port1mask" {
  description = "Subnet mask for port1 (HA Management interface)"
  type        = string
  default     = "255.255.255.0"

  validation {
    condition     = can(regex("^(255\\.){3}(255|254|252|248|240|224|192|128|0)$|^(255\\.){2}(255|254|252|248|240|224|192|128|0)\\.0$|^255\\.(255|254|252|248|240|224|192|128|0)(\\.0){2}$|^(255|254|252|248|240|224|192|128)(\\.0){3}$", var.port1mask))
    error_message = "Port1 mask must be a valid subnet mask (e.g., 255.255.255.0)."
  }
}

variable "port1gateway" {
  description = "Default gateway IP for port1 (HA Management interface)"
  type        = string
  default     = "172.1.3.1"

  validation {
    condition     = can(regex("^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$", var.port1gateway))
    error_message = "Port1 gateway must be a valid IPv4 address (e.g., 10.0.1.1)."
  }
}

# Port2 (WAN/Public) IP Configuration
variable "port2" {
  description = "Static private IP address for port2 (WAN/Public interface)"
  type        = string
  default     = "172.1.0.10"

  validation {
    condition     = can(regex("^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$", var.port2))
    error_message = "Port2 IP must be a valid IPv4 address (e.g., 10.0.2.10)."
  }
}

variable "port2mask" {
  description = "Subnet mask for port2 (WAN/Public interface)"
  type        = string
  default     = "255.255.255.0"

  validation {
    condition     = can(regex("^(255\\.){3}(255|254|252|248|240|224|192|128|0)$|^(255\\.){2}(255|254|252|248|240|224|192|128|0)\\.0$|^255\\.(255|254|252|248|240|224|192|128|0)(\\.0){2}$|^(255|254|252|248|240|224|192|128)(\\.0){3}$", var.port2mask))
    error_message = "Port2 mask must be a valid subnet mask (e.g., 255.255.255.0)."
  }
}

variable "port2gateway" {
  description = "Default gateway IP for port2 (WAN/Public interface). Used as default route for internet traffic"
  type        = string
  default     = "172.1.0.1"

  validation {
    condition     = can(regex("^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$", var.port2gateway))
    error_message = "Port2 gateway must be a valid IPv4 address (e.g., 10.0.2.1)."
  }
}

# Port3 (LAN/Private) IP Configuration
variable "port3" {
  description = "Static private IP address for port3 (LAN/Private interface)"
  type        = string
  default     = "172.1.1.10"

  validation {
    condition     = can(regex("^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$", var.port3))
    error_message = "Port3 IP must be a valid IPv4 address (e.g., 10.0.3.10)."
  }
}

variable "port3mask" {
  description = "Subnet mask for port3 (LAN/Private interface)"
  type        = string
  default     = "255.255.255.0"

  validation {
    condition     = can(regex("^(255\\.){3}(255|254|252|248|240|224|192|128|0)$|^(255\\.){2}(255|254|252|248|240|224|192|128|0)\\.0$|^255\\.(255|254|252|248|240|224|192|128|0)(\\.0){2}$|^(255|254|252|248|240|224|192|128)(\\.0){3}$", var.port3mask))
    error_message = "Port3 mask must be a valid subnet mask (e.g., 255.255.255.0)."
  }
}

# Port4 (HA Sync) IP Configuration
variable "port4" {
  description = "Static private IP address for port4 (HA Sync interface)"
  type        = string
  default     = "172.1.2.10"

  validation {
    condition     = can(regex("^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$", var.port4))
    error_message = "Port4 IP must be a valid IPv4 address (e.g., 10.0.4.10)."
  }
}

variable "port4mask" {
  description = "Subnet mask for port4 (HA Sync interface)"
  type        = string
  default     = "255.255.255.0"

  validation {
    condition     = can(regex("^(255\\.){3}(255|254|252|248|240|224|192|128|0)$|^(255\\.){2}(255|254|252|248|240|224|192|128|0)\\.0$|^255\\.(255|254|252|248|240|224|192|128|0)(\\.0){2}$|^(255|254|252|248|240|224|192|128)(\\.0){3}$", var.port4mask))
    error_message = "Port4 mask must be a valid subnet mask (e.g., 255.255.255.0)."
  }
}

# Port5 (Optional - Additional Interface) IP Configuration
# Used for DMZ zones, additional WANs, dedicated monitoring, etc.
variable "port5" {
  description = "Static private IP address for optional port5 interface. Set to null to disable port5"
  type        = string
  default     = null

  validation {
    condition     = var.port5 == null || can(regex("^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$", var.port5))
    error_message = "Port5 IP must be null or a valid IPv4 address (e.g., 10.0.5.10)."
  }
}

# Port6 (Optional - Additional Interface) IP Configuration
# Used for DMZ zones, additional WANs, dedicated monitoring, etc.
variable "port6" {
  description = "Static private IP address for optional port6 interface. Set to null to disable port6"
  type        = string
  default     = null

  validation {
    condition     = var.port6 == null || can(regex("^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$", var.port6))
    error_message = "Port6 IP must be null or a valid IPv4 address (e.g., 10.0.6.10)."
  }
}

# =============================================================================
# HA CONFIGURATION
# =============================================================================

variable "active_peerip" {
  description = "IP address of the active FortiGate peer in HA cluster. Used for HA synchronization. Set to null for standalone deployment"
  type        = string
  default     = null
}

variable "passive_peerip" {
  description = "IP address of the passive FortiGate peer in HA cluster. Used for HA synchronization. Set to null for standalone deployment"
  type        = string
  default     = null
}

# =============================================================================
# BOOTSTRAP CONFIGURATION
# =============================================================================

variable "bootstrap" {
  description = "Path to FortiGate bootstrap configuration file. Contains initial FortiGate config including network, HA, and policy settings"
  type        = string
  default     = "config-active.conf"
}

# =============================================================================
# NETWORK SECURITY
# =============================================================================

variable "enable_management_access_restriction" {
  description = "Enable restricted management access. If true, only specified CIDRs can access management interface"
  type        = bool
  default     = true
}

variable "management_access_cidrs" {
  description = "List of CIDR blocks allowed to access FortiGate management interface (port1). Empty list allows from anywhere (not recommended)"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.management_access_cidrs :
      can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", cidr))
    ])
    error_message = "All management access CIDRs must be valid CIDR notation (e.g., 10.0.0.0/24, 203.0.113.0/32)."
  }
}

variable "management_ports" {
  description = "List of TCP ports for FortiGate management access"
  type        = list(number)
  default     = [443, 8443, 22]

  validation {
    condition = alltrue([
      for port in var.management_ports :
      port >= 1 && port <= 65535
    ])
    error_message = "Management ports must be between 1 and 65535."
  }
}

# =============================================================================
# DISK CONFIGURATION
# =============================================================================

variable "data_disk_size_gb" {
  description = "Size of the FortiGate data disk in GB for logs and configuration storage"
  type        = number
  default     = 30

  validation {
    condition     = var.data_disk_size_gb >= 1 && var.data_disk_size_gb <= 32767
    error_message = "Data disk size must be between 1 and 32767 GB."
  }
}

variable "data_disk_storage_type" {
  description = "Storage account type for data disk. Options: Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS, Premium_ZRS"
  type        = string
  default     = "Standard_LRS"

  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "StandardSSD_ZRS", "Premium_ZRS"], var.data_disk_storage_type)
    error_message = "Data disk storage type must be one of: Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS, Premium_ZRS."
  }
}

variable "data_disk_caching" {
  description = "Disk caching mode for data disk. Options: None, ReadOnly, ReadWrite"
  type        = string
  default     = "ReadWrite"

  validation {
    condition     = contains(["None", "ReadOnly", "ReadWrite"], var.data_disk_caching)
    error_message = "Data disk caching must be one of: None, ReadOnly, ReadWrite."
  }
}

# =============================================================================
# TAGGING
# =============================================================================
# Note: terraform-namer automatically provides these tags:
#   - company, contact, environment, location, repository, workload
# Use the tags variable below to add any additional custom tags (e.g., CostCenter, Owner, Project)

variable "tags" {
  description = "Additional custom tags to apply to all resources. Merged with terraform-namer tags. Example: { CostCenter = \"IT-001\", Owner = \"security-team\", Project = \"firewall-migration\" }"
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for k, v in var.tags : can(regex("^[a-zA-Z0-9-_]{1,50}$", k)) && length(v) <= 256])
    error_message = "Tag keys must be alphanumeric with hyphens/underscores (max 50 chars), values max 256 chars."
  }
}

# =============================================================================
# MONITORING & DIAGNOSTICS
# =============================================================================

variable "enable_diagnostics" {
  description = "Enable Azure Monitor diagnostic settings for FortiGate VM and network resources"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Azure Log Analytics workspace resource ID for diagnostic logs and metrics. Required when enable_diagnostics = true"
  type        = string
  default     = null
}

variable "diagnostic_retention_days" {
  description = "Number of days to retain diagnostic logs. Set to 0 for indefinite retention"
  type        = number
  default     = 30

  validation {
    condition     = var.diagnostic_retention_days >= 0 && var.diagnostic_retention_days <= 365
    error_message = "Diagnostic retention days must be between 0 and 365."
  }
}

variable "enable_nsg_flow_logs" {
  description = "Enable NSG flow logs for network traffic analysis. Requires enable_diagnostics = true"
  type        = bool
  default     = false
}

variable "nsg_flow_logs_storage_account_id" {
  description = "Storage account resource ID for NSG flow logs. Required when enable_nsg_flow_logs = true"
  type        = string
  default     = null
}

variable "nsg_flow_logs_retention_days" {
  description = "Number of days to retain NSG flow logs"
  type        = number
  default     = 7

  validation {
    condition     = var.nsg_flow_logs_retention_days >= 0 && var.nsg_flow_logs_retention_days <= 365
    error_message = "NSG flow logs retention days must be between 0 and 365."
  }
}
