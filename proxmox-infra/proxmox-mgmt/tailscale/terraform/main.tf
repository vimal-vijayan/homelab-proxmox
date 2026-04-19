resource "proxmox_vm_qemu" "tailscale" {
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

  # Management bridge — vmbr-mgmt (10.10.99.0/24), static IP 10.10.99.10
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr-mgmt"
  }
}
