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
  default     = "opnsense-fw"
}

variable "vmid" {
  description = "VMID (must be free on Proxmox)"
  type        = number
  default     = 101
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
  default     = 6144
}

variable "disk_size" {
  description = "Boot disk size"
  type        = string
  default     = "16G"
}

variable "storage" {
  description = "Proxmox storage pool for the disk"
  type        = string
  default     = "nvme"
}

variable "iso" {
  description = "OPNsense ISO path on Proxmox (format: <storage>:iso/<filename>)"
  type        = string
  default     = "local:iso/OPNsense-24.7-dvd-amd64.iso"
}
