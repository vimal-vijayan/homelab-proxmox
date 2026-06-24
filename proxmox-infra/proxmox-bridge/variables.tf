variable "pm_api_url" {
  description = "Proxmox API URL (e.g. https://192.168.178.44:8006)"
  type        = string
  default     = "https://192.168.178.44:8006"
}

variable "pm_user" {
  description = "Proxmox username (e.g. vimal@pve)"
  type        = string
  sensitive   = true
}

variable "pm_password" {
  description = "Proxmox password"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name where bridges will be created"
  type        = string
  default     = "pve"
}
