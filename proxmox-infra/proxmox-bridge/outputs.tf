output "vmbr1_name" {
  description = "K8s LAN bridge name"
  value       = proxmox_network_linux_bridge.vmbr1.name
}

output "vmbr2_name" {
  description = "SIEM lab bridge name"
  value       = proxmox_network_linux_bridge.vmbr2.name
}

output "vmbr_mgmt_name" {
  description = "Management bridge name"
  value       = proxmox_network_linux_bridge.vmbr_mgmt.name
}
