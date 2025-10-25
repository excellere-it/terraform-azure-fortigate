# =============================================================================
# EXAMPLE VARIABLES
# =============================================================================

variable "service_principal_secret" {
  description = "Azure service principal client secret for FortiGate Azure SDN connector. Required for HA failover automation."
  type        = string
  sensitive   = true
  default     = "PLACEHOLDER_SECRET" # Replace with actual secret or use environment variable
}
