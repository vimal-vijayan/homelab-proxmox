resource "proxmox_vm_qemu" "bastion" {
  name        = var.name
  vmid        = var.vmid
  target_node = var.node
  memory      = var.memory

  cpu {
    cores   = var.cores
    sockets = 1
    type    = "host"
  }

  lifecycle {
    ignore_changes = [startup_shutdown]
  }

  disks {
    ide {
      ide2 {
        cdrom {
          iso = var.iso
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          size    = var.disk_size
          storage = var.storage
        }
      }
    }
  }

  # Management bridge — vmbr-mgmt (10.10.99.0/24), static IP 10.10.99.30
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr99" # vmbr-mgmt is vmbr99 on the Proxmox host
  }

  # WAN bridge — vmbr0, backed by nic1 (enx2c44fd2e3080), DHCP from home router
  # Used for initial bootstrap before Tailscale is set up
  network {
    id     = 1
    model  = "virtio"
    bridge = "vmbr0"
  }
}
