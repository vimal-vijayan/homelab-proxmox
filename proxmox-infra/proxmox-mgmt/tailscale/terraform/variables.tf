variable "pm_api_url" {
  description = "Proxmox API endpoint"
  type        = string
  default     = "https://192.168.178.44:8006/api2/json"
}

variable "pm_user" {
  description = "Proxmox API user (e.g. vimal@pve)"
  type        = string
}

variable "pm_password" {
  description = "Proxmox API password — supply via TF_VAR_pm_password env var"
  type        = string
  sensitive   = true
}

variable "name" {
  description = "VM name"
  type        = string
  default     = "tailscale-router"
}

variable "vmid" {
  description = "VMID (must be free on Proxmox)"
  type        = number
  default     = 110
}

variable "node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

variable "cores" {
  description = "CPU cores"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 2048
}

variable "disk_size" {
  description = "Boot disk size"
  type        = string
  default     = "20G"
}

variable "storage" {
  description = "Proxmox storage pool for the disk"
  type        = string
  default     = "nvme"
}

variable "iso" {
  description = "Ubuntu ISO path on Proxmox (format: <storage>:iso/<filename>)"
  type        = string
  default     = "local:iso/ubuntu-24.04.3-live-server-amd64.iso"
}
