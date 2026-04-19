# Proxmox Management Bridge — Setup Rule

## Overview

The management bridge (`vmbr-mgmt`, `10.10.99.0/24`) is set up in three stages:

1. **Bridge creation** — Ansible (`proxomox-linux-bridge/`)
2. **VM provisioning** — Terraform (new dir: `proxmox-infra/proxmox-mgmt-vms/`)
3. **VM configuration** — Ansible (new dir: `proxmox-infra/proxmox-mgmt-config/`)

---

## Stage 1 — Bridge Setup (Ansible)

**Directory:** `proxmox-infra/proxomox-linux-bridge/ansible/`

Add `vmbr-mgmt` to `group_vars/proxmox.yml` under `proxmox_network_bridges`:

```yaml
- iface: "vmbr-mgmt"
  iface_type: bridge
  cidr: "10.10.99.1/24"
  autostart: true
  comments: "Management bridge — Proxmox UI, PBS, Tailscale VM"
  state: present
```

Run:
```bash
cd proxmox-infra/proxomox-linux-bridge/ansible/
ansible-playbook -i inventory/hosts.ini site.yml
```

The role uses the Proxmox REST API (token auth) — no SSH to the Proxmox host required.

---

## Stage 2 — VM Provisioning (Terraform)

**Directory:** `proxmox-infra/proxmox-mgmt-vms/`

Use the `Telmate/proxmox` provider (same as OPNsense). Provision three VMs attached to `vmbr-mgmt`:

| VM | IP | Purpose |
|---|---|---|
| Tailscale Subnet Router | 10.10.99.10 | WireGuard node — advertises all private subnets |
| Proxmox Backup Server (PBS) | 10.10.99.20 | VM snapshots + etcd backup |
| Bastion VM (optional) | 10.10.99.30 | SSH break-glass |

Credentials follow the same pattern as OPNsense Terraform:
- Use `values.tfvars` for secrets — never commit it.
- Use env vars `PM_USER` / `PM_PASS` or Proxmox API token variables.
- Add `*.tfvars`, `terraform.tfstate*` to `.gitignore`.

Run:
```bash
cd proxmox-infra/proxmox-mgmt-vms/
terraform init
terraform plan -var-file="values.tfvars"
terraform apply -var-file="values.tfvars"
```

---

## Stage 3 — VM Configuration (Ansible)

**Directory:** `proxmox-infra/proxmox-mgmt-config/`

A separate Ansible project (SSH-based, not API-based) that configures the provisioned VMs. Structure mirrors `proxmox-kubernetes-cluster/`:

```
proxmox-mgmt-config/
├── inventory.yml          # Static hosts: tailscale, pbs, bastion
├── group_vars/
│   └── all.yml            # Shared vars (subnet CIDRs, DNS server)
├── setup-hosts.yml        # Hostname + static IP (netplan)
└── roles/
    ├── tailscale/         # Install tailscale, advertise routes
    ├── pbs/               # PBS install + backup job config
    └── bastion/           # sshd hardening, fail2ban
```

Run order:
```bash
cd proxmox-infra/proxmox-mgmt-config/

# Step 1: Configure hostnames and static IPs
ansible-playbook -i inventory.yml setup-hosts.yml

# Step 2: Apply per-role configuration
ansible-playbook -i inventory.yml site.yml
```

---

## Static IP Assignments

| Host | IP | Gateway | DNS |
|---|---|---|---|
| Tailscale VM | 10.10.99.10/24 | 10.10.99.1 | 10.10.10.1 (OPNsense) |
| PBS | 10.10.99.20/24 | 10.10.99.1 | 10.10.10.1 |
| Bastion | 10.10.99.30/24 | 10.10.99.1 | 10.10.10.1 |

Gateway `10.10.99.1` is OPNsense's `vmbr-mgmt` interface (not provisioned here — manual OPNsense setup).

---

## Firewall Rules (OPNsense)

These rules must be applied manually in OPNsense after bridge creation:

- `vmbr-mgmt → all` — ALLOWED (management can reach everything)
- `vmbr1 → vmbr-mgmt` — BLOCKED (K8s cannot reach management)
- `vmbr2 → vmbr-mgmt` — BLOCKED (SIEM cannot reach management)

---

## Lifecycle Note

- Bridge deletion: set `state: absent` in `proxmox_network_bridges` and re-run the Ansible playbook.
- VM teardown: `terraform destroy -var-file="values.tfvars"` in `proxmox-mgmt-vms/`.
- Bridge must exist before Terraform provisions VMs attached to it — run Stage 1 first.
