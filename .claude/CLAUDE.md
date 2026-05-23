# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Infrastructure-as-code and GitOps configuration for a production-style homelab built on Proxmox. The stack spans three layers: Proxmox hypervisor → OPNsense firewall/router → K3s Kubernetes cluster, managed via Ansible, Terraform, and Flux CD.

## Repository Layout

| Directory | Purpose |
|---|---|
| `proxmox-infra/proxmox-kubernetes-cluster/` | Ansible playbooks for K3s cluster provisioning |
| `proxmox-infra/proxmox-kubernetes-vm/` | VM provisioning automation |
| `proxmox-infra/proxomox-linux-bridge/` | Proxmox bridge/VLAN configuration |
| `docs/proxmox/terraform/` | Terraform configs for OPNsense and K3s VMs |
| `fluxcd/` | Flux CD GitOps — apps, infrastructure, cluster configs |
| `docs/` | Setup guides and architecture diagrams |

## Key Commands

### Ansible — K3s Cluster
```bash
cd proxmox-infra/proxmox-kubernetes-cluster/

# Step 1: Configure hostnames and static IPs via netplan
ansible-playbook -i inventory.yml setup-hosts.yml

# Step 2: Install K3s (cluster-init on first control-plane, then join others)
ansible-playbook -i inventory.yml install-k3s.yml
```

K3s cluster variables live in `proxmox-infra/proxmox-kubernetes-cluster/group_vars/all.yml`.

### Terraform — VM Provisioning
```bash
# OPNsense firewall VM
cd docs/proxmox/terraform/pfsense/
terraform plan -var-file="values.tfvars" && terraform apply

# K3s VMs (control-plane + workers via for_each)
cd docs/proxmox/terraform/kubernetes/
terraform plan && terraform apply
```

### Flux CD — GitOps Bootstrap
```bash
# One-time: install Flux Operator
helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  --namespace flux-system --create-namespace

# Apply the FluxInstance (syncs this repo, path: fluxcd/clusters/home-lab)
kubectl apply -f fluxcd/clusters/home-lab/flux-system/fluxinstance.yaml

# Check reconciliation status
kubectl get fluxinstances -n flux-system
flux get all -n flux-system
```

## Architecture Overview (v2.1)

> **Current iteration scope:** K8s cluster (vmbr1), management bridge (vmbr-mgmt), and OPNsense are fully provisioned. The SIEM lab bridge (vmbr2) is created and firewalled, but **no VMs are deployed on it yet** — that is a future iteration.

### Network Topology

The diagram source is at [docs/architecture/homelab-architecture-v2_1.drawio](docs/architecture/homelab-architecture-v2_1.drawio).

| Bridge | Subnet | Physical NIC | Role | Status |
|---|---|---|---|---|
| vmbr0 | 192.168.178.44/24 | nic1 (enx2c44fd2e3080) | WAN — uplink to home router | ✅ Active |
| vmbr1 | 10.10.10.0/24 | none (internal) | K8s private LAN | ✅ Active |
| vmbr2 | 10.10.20.0/24 | none (internal) | SIEM lab — network reserved, isolated | 🔜 Reserved |
| vmbr-mgmt | 10.10.99.0/24 | none (internal) | Management — Proxmox UI, PBS, Tailscale VM | ✅ Active |

> **Note:** Only vmbr0 has a physical NIC. All other bridges are internal-only. The Tailscale VM on vmbr-mgmt reaches the internet via OPNsense NAT (vmbr-mgmt → vmbr0), not via a direct NIC attachment.

**OPNsense firewall rules (key):**
- `vmbr1 ↔ vmbr2` — BLOCKED (K8s and SIEM are isolated from each other)
- `vmbr1/vmbr2 → vmbr-mgmt` — BLOCKED
- `vmbr-mgmt → all` — ALLOWED (management can reach everything)
- `vmbr1/vmbr2 → WAN` — ALLOWED (internet egress via NAT)
- `vmbr1/vmbr2 → OPNsense port 53` — ALLOWED (DNS)
- `Tailscale VM → all bridges` — ALLOWED

### VM Inventory

| VM | IP | Bridge | Status | Purpose |
|---|---|---|---|---|
| OPNsense | gateway .1 per net | all | ✅ Active | Stateful firewall, DHCP, DNS→Cloudflare DoT, IDS/IPS (Suricata), NetFlow |
| Pi-hole | 10.10.10.2 | vmbr1 | ✅ Active | DNS sinkhole, ad/tracker blocking, upstream → OPNsense |
| K8s Control Plane | 10.10.10.10 | vmbr1 | ✅ Active | API server, etcd, scheduler, controller-manager |
| K8s Worker 1 | 10.10.10.11 | vmbr1 | ✅ Active | App pods, Cilium CNI |
| K8s Worker 2 | 10.10.10.12 | vmbr1 | ✅ Active | App pods, Cilium CNI |
| Tailscale Subnet Router | 10.10.99.10 | vmbr-mgmt | ✅ Active | Standalone WireGuard node — advertises all private subnets |
| Proxmox Backup Server (PBS) | 10.10.99.20 | vmbr-mgmt | ✅ Active | VM snapshots + etcd backup target |
| Bastion VM (optional) | 10.10.99.30 | vmbr-mgmt | ✅ Active | SSH break-glass if Tailscale is unavailable |
| Wazuh SIEM Manager | 10.10.20.10 | vmbr2 | 🔜 Future | Log aggregation, threat detection, alerting |
| Log Collector VM | 10.10.20.11 | vmbr2 | 🔜 Future | Logstash/Filebeat — syslog/NetFlow receiver → Wazuh |

### K3s Cluster

- **API endpoint**: `https://10.10.10.10:6443`
- **CNI**: Cilium (kube-proxy disabled)
- **Disabled**: Traefik, servicelb, network-policy
- **Load balancer**: MetalLB — pool `10.50.10.100/32` (L2 advertisement)
- **Ingress**: `cloudflared` DaemonSet + Ingress Controller (nginx/Traefik) — outbound-only TLS tunnel to Cloudflare, zero open inbound ports
- **Remote access**: Tailscale subnet router on vmbr-mgmt — advertises `10.10.10.0/24`, `10.10.20.0/24`, `10.10.99.0/24`

### GitOps Structure (Flux CD)

Flux Operator reconciles from `fluxcd/clusters/home-lab` on a 1h interval (Flux v2.7.x).

```
fluxcd/
├── clusters/home-lab/        # Entry point — FluxInstance definition
├── infrastructure/           # cert-manager, MetalLB, internet-gateway
└── apps/                     # ArgoCD, demo-store, demo-app, TFRun
```

Apps and infrastructure use Kustomize base/overlay pattern. HelmRelease resources handle cert-manager, MetalLB, and ArgoCD.

### Public Exposure

Apps are exposed via **Cloudflare Tunnel** (`cloudflared` DaemonSet in K8s) — outbound-only TLS connection to Cloudflare. No inbound ports are opened on OPNsense for public traffic.

### Log Sources → SIEM (Future — Phase 2)

> Not yet deployed. `vmbr2` (`10.10.20.0/24`) is reserved and firewalled.

Planned: Wazuh agents on all K8s nodes forward to the SIEM bridge. OPNsense ships syslog/NetFlow, Pi-hole ships query logs, Tailscale VM and PBS send syslog — all via the Log Collector VM at `10.10.20.11`.

## Infrastructure Build Order

### Phase 1 — Current (v2.1)

1. Proxmox: configure bridges (vmbr0, vmbr1, **vmbr2 reserved**, vmbr-mgmt) and storage
2. Terraform: provision OPNsense VM and K3s VMs
3. OPNsense: manual setup — WAN/LAN interfaces, DHCP, Suricata IDS/IPS, DNS-over-TLS, firewall rules (including `vmbr2` isolation rules even though no VMs exist yet)
4. Ansible: `setup-hosts.yml` then `install-k3s.yml`
5. Pi-hole: deploy on vmbr1 (`10.10.10.2`), set OPNsense as upstream
6. MetalLB: apply IP pool and L2Advertisement manifests
7. Flux: bootstrap operator → apply FluxInstance → cluster self-manages from Git
8. Tailscale subnet router VM: deploy on vmbr-mgmt, advertise all private subnets
9. PBS: deploy on vmbr-mgmt, configure VM snapshot and etcd backup jobs
10. Bastion VM: deploy on vmbr-mgmt, harden SSH

### Phase 2 — Future (SIEM lab)

11. SIEM: deploy Wazuh Manager (`10.10.20.10`) and Log Collector (`10.10.20.11`) on vmbr2
12. Wazuh agents: deploy on all K8s nodes, forward to SIEM bridge
13. Log sources: configure OPNsense syslog/NetFlow, Pi-hole query log, PBS and Tailscale syslog → Log Collector

## Git Conventions

Branch naming: `feat/<topic>` or `fix/<topic>`. Commits use conventional format: `feat(scope): description`.
