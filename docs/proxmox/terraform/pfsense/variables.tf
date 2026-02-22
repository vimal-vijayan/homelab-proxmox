variable "name" {
  description = "Name of the VM"
  type        = string
  default     = "pfsense"
}

variable "vmid" {
  description = "VMID to assign (must be free on Proxmox)"
  type        = number
  default     = 101
}

variable "node" {
  description = "Proxmox node to place the VM on"
  type        = string
  default     = "pve"
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "sockets" {
  description = "CPU sockets"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 4096
}

variable "disk_size" {
  description = "Disk size (e.g., 10G)"
  type        = string
  default     = "10G"
}

variable "storage" {
  description = "Storage to use for the VM disk (e.g., local-lvm)"
  type        = string
  default     = "local-lvm"
}

variable "iso" {
  description = "ISO path on Proxmox (format: <storage>:iso/<filename>)"
  type        = string
  default     = "local:iso/netgate-installer-v1.1.1-RELEASE-amd64.iso"
}

variable "net_model" {
  description = "Network device model"
  type        = string
  default     = "virtio"
}

variable "bridge" {
  description = "Bridge to attach the VM NIC to"
  type        = string
  default     = "vmbr0"
}
