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
  default     = "bastion"
}

variable "vmid" {
  description = "VMID (must be free on Proxmox)"
  type        = number
  default     = 111
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

variable "template_name" {
  description = "Name of the Proxmox cloud-init VM template to clone"
  type        = string
  default     = "ubuntu-2404-cloudinit-template"
}

variable "ci_user" {
  description = "Cloud-init default user"
  type        = string
  default     = "ubuntu"
}

variable "ci_password" {
  description = "Cloud-init user password — supply via TF_VAR_ci_password env var"
  type        = string
  sensitive   = true
}
