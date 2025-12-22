locals {
  proxmox = {
    node = "pve"
  }
  controller = [
    {
      name      = "k8s-controller"
      vmid      = 201
      iso       = "local:iso/ubuntu-24.04.3-live-server-amd64.iso"
      net_model = "virtio"
      bridge    = "vmbr0"
      memory    = 16384
      cpu_cores = 4
    }
  ]

  nodes = [
    {
      name      = "k8s-node-1"
      vmid      = 210
      iso       = "local:iso/ubuntu-24.04.3-live-server-amd64.iso"
      net_model = "virtio"
      bridge    = "vmbr0"
      memory    = 8192
      cpu_cores = 2
    },
    {
      name      = "k8s-node-2"
      vmid      = 211
      iso       = "local:iso/ubuntu-24.04.3-live-server-amd64.iso"
      net_model = "virtio"
      bridge    = "vmbr0"
      memory    = 8192
      cpu_cores = 2
    }
  ]
}
