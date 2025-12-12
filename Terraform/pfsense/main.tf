resource "proxmox_vm_qemu" "pfsense" {
  name        = var.name
  vmid        = var.vmid
  target_node = var.node
  memory      = var.memory

  scsihw = "virtio-scsi-pci"

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
  #   network {
  #     model  = var.net_model
  #     bridge = var.bridge
  #   }
}
