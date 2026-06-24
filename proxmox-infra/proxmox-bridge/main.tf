# ============================================================
# Proxmox Linux Bridges
# Managed by bpg/proxmox provider — supports bridge resources
# natively unlike Telmate/proxmox.
#
# Bridge layout (v2.1):
#   vmbr1      — K8s LAN       10.10.10.0/24
#   vmbr2      — SIEM lab      10.10.20.0/24  (reserved, no VMs yet)
#   vmbr-mgmt  — Management    10.10.99.0/24
#
# NOTE: vmbr0 (WAN) is pre-configured on the Proxmox host and
# is NOT managed here — it has a physical NIC (enx2c44fd2e3080)
# and is configured via Proxmox host networking directly.
# ============================================================

locals {
  node = var.proxmox_node
}

# ------------------------------------------------------------------
# vmbr1 — Kubernetes LAN (10.10.10.0/24)
# Internal-only bridge; OPNsense vtnet1 is the gateway (10.10.10.1).
# Hosts: Pi-hole (10.10.10.2), K8s CP (10.10.10.10), Workers (.11/.12)
# MetalLB pool: 10.50.10.100/32
# ------------------------------------------------------------------
resource "proxmox_virtual_environment_network_linux_bridge" "vmbr1" {
  node_name = local.node
  name      = "vmbr1"
  comment   = "K8s private LAN — 10.10.10.0/24. OPNsense LAN (vtnet1): 10.10.10.1. Pi-hole: 10.10.10.2. K8s CP: 10.10.10.10. Workers: .11/.12. MetalLB: 10.50.10.100/32."

  # No IP on the bridge itself — OPNsense owns the gateway
  address = null
  gateway = null

  # Internal-only — no physical NIC
  ports = []

  autostart = true
}

# ------------------------------------------------------------------
# vmbr2 — SIEM Lab (10.10.20.0/24) — RESERVED, no VMs yet
# Isolated from vmbr1 by OPNsense firewall rules.
# Future: Wazuh Manager (10.10.20.10), Log Collector (10.10.20.11)
# ------------------------------------------------------------------
resource "proxmox_virtual_environment_network_linux_bridge" "vmbr2" {
  node_name = local.node
  name      = "vmbr2"
  comment   = "SIEM lab — 10.10.20.0/24. OPNsense OPT1 (vtnet2): 10.10.20.1. RESERVED — no VMs deployed. Future: Wazuh (10.10.20.10), Log Collector (10.10.20.11). Isolated from vmbr1 by OPNsense rules."

  address = null
  gateway = null
  ports   = []

  autostart = true
}

# ------------------------------------------------------------------
# vmbr-mgmt — Management Bridge (10.10.99.0/24)
# OPNsense OPT2 (vtnet3): 10.10.99.1 — full Suricata visibility.
# Hosts: Tailscale subnet router (10.10.99.10), PBS (10.10.99.20),
#        Bastion VM (10.10.99.30)
# LAN/OPT1 → MGMT is BLOCKED; MGMT → all is ALLOWED via OPNsense NAT.
# ------------------------------------------------------------------
resource "proxmox_virtual_environment_network_linux_bridge" "vmbr_mgmt" {
  node_name = local.node
  name      = "vmbr-mgmt"
  comment   = "Management bridge — 10.10.99.0/24. OPNsense OPT2 (vtnet3): 10.10.99.1. Tailscale subnet router: 10.10.99.10. PBS: 10.10.99.20. Bastion: 10.10.99.30. LAN/OPT1→MGMT BLOCKED. MGMT→all ALLOWED + NAT."

  address = null
  gateway = null
  ports   = []

  autostart = true
}
