resource "proxmox_vm_qemu" "opnsense" {
  name        = var.name
  vmid        = var.vmid
  target_node = var.node
  memory      = var.memory

  # OPNsense is ISO-based — no cloud-init, no ipconfig.
  # Interfaces (WAN/LAN/OPT1) are assigned manually on first boot via the console.
  boot   = "order=scsi1;scsi0"
  scsihw = "virtio-scsi-pci"
  agent  = 0

  cpu {
    cores   = var.cores
    sockets = 1
    type    = "host"
  }

  lifecycle {
    ignore_changes = [startup_shutdown]
  }

  vga {
    type = "std"
  }

  disks {
    scsi {
      # scsi0 — boot disk (persistent storage)
      scsi0 {
        disk {
          size    = var.disk_size
          storage = var.storage
        }
      }
      # scsi1 — OPNsense install ISO (cdrom); detach after install
      scsi1 {
        cdrom {
          iso = var.iso
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

  # OPT2 — Management bridge (10.10.99.0/24)
  network {
    id     = 3
    model  = "virtio"
    bridge = "vmbr3"
  }
}
