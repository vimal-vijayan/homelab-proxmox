terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "3.0.2-rc06"
    }
  }
}

provider "proxmox" {
  # Configuration options
}