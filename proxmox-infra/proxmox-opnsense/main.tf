resource "proxmox_vm_qemu" "opnsense" {
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
    scsi {
      scsi0 {
        cdrom {
          iso = var.iso
        }
      }
      scsi1 {
        disk {
          size    = var.disk_size
          storage = var.storage
        }
      }
    }
  }

  # WAN — uplink to home router via vmbr0
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  # LAN — K8s private network (10.10.10.0/24)
  network {
    id     = 1
    model  = "virtio"
    bridge = "vmbr1"
  }

  # OPT1 — SIEM lab network (10.10.20.0/24)
  network {
    id     = 2
    model  = "virtio"
    bridge = "vmbr2"
  }
}
