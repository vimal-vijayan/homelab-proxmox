variable "pm_api_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://192.168.178.44:8006/api2/json"
}

variable "pm_user" {
  description = "Proxmox API user"
  type        = string
}

variable "pm_password" {
  description = "Proxmox API password"
  type        = string
  sensitive   = true
}
