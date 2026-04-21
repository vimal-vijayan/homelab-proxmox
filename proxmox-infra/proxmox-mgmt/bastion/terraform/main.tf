resource "proxmox_vm_qemu" "bastion" {
  name        = var.name
  vmid        = var.vmid
  target_node = var.node
  memory      = var.memory

  # Clone from cloud-init template instead of booting from ISO
  clone      = var.template_name
  full_clone = true

  os_type    = "cloud-init"
  boot       = "order=scsi0"
  scsihw     = "virtio-scsi-pci"
  agent      = 0
  ipconfig0  = "ip=10.10.99.30/24,gw=10.10.99.1"
  ipconfig1  = "ip=dhcp"
  nameserver = "10.10.10.1"

  ciuser      = var.ci_user
  cipassword  = var.ci_password
  # cicustom    = "user=local:snippets/bastion-user-data.yml"

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
        disk {
          size    = var.disk_size
          storage = var.storage
        }
      }
    }
    ide {
      ide2 {
        cloudinit {
          storage = var.storage
        }
      }
    }
  }

  # Management bridge — vmbr99 (vmbr-mgmt, 10.10.99.0/24), static IP 10.10.99.30
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr99"
  }

  # WAN bridge — vmbr0, DHCP from home router (bootstrap / break-glass access)
  network {
    id     = 1
    model  = "virtio"
    bridge = "vmbr0"
  }
}
