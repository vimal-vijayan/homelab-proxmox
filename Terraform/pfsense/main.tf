resource "proxmox_vm_qemu" "pfsense" {
  name        = var.name
  vmid        = var.vmid
  target_node = var.node
  memory      = var.memory

  cpu {
    cores = "1"
  }

  # Attach the uploaded ISO as the CD-ROM (format: "<storage>:iso/<filename>")
  disks {
    scsi {
      scsi0 {
        cdrom {
          iso = var.iso
        }
      }
      scsi1 {
        disk {
          size    = "20G"
          storage = "nvme"
        }
      }
    }
  }

  # Network interface
  network {
    id     = 0
    model  = var.net_model
    bridge = var.bridge
  }

  network {
    id     = 1
    model  = "virtio"
    bridge = "vmbr1"
  }

  network {
    id     = 2
    model  = "virtio"
    bridge = "vmbr2"
  }

}

resource "proxmox_vm_qemu" "pfsense_web" {
  name        = "pfsense-web"
  vmid        = 102
  target_node = var.node
  memory      = 2048

  cpu {
    cores = "1"
  }

  # Attach the uploaded ISO as the CD-ROM (format: "<storage>:iso/<filename>")
  disks {
    scsi {
      scsi0 {
        cdrom {
          iso = "local:iso/ubuntu-24.04.3-desktop-amd64.iso"
        }
      }
      scsi1 {
        disk {
          size    = "10G"
          storage = "nvme"
        }
      }
    }
  }

  # Network interface
  network {
    id     = 1
    model  = "virtio"
    bridge = "vmbr1"
  }
}
