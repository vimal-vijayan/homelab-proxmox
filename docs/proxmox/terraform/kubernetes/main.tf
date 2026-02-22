resource "proxmox_vm_qemu" "kubernetes_controller" {
  for_each    = { for ctrl in local.controller : ctrl.name => ctrl }
  name        = each.value.name
  vmid        = each.value.vmid
  target_node = local.proxmox.node
  memory      = each.value.memory

  cpu {
    cores = each.value.cpu_cores
  }

  lifecycle {
    ignore_changes = [
      startup_shutdown, tags
    ]
  }

  # Attach the uploaded ISO as the CD-ROM (format: "<storage>:iso/<filename>")
  disks {
    scsi {
      scsi0 {
        cdrom {
          iso = each.value.iso
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
    model  = "virtio"
    bridge = "vmbr0"
  }

}


resource "proxmox_vm_qemu" "kubernetes_nodes" {
  for_each    = { for node in local.nodes : node.name => node }
  name        = each.value.name
  vmid        = each.value.vmid
  target_node = local.proxmox.node
  memory      = each.value.memory

  cpu {
    cores = each.value.cpu_cores
  }

  lifecycle {
    ignore_changes = [
      startup_shutdown, tags
    ]
  }

  # Attach the uploaded ISO as the CD-ROM (format: "<storage>:iso/<filename>")
  disks {
    scsi {
      scsi0 {
        cdrom {
          iso = each.value.iso
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
    model  = "virtio"
    bridge = "vmbr0"
  }

}
