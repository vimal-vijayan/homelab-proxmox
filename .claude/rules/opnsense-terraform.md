# OPNsense VM — Terraform Instructions

## Location

proxmox-infra/proxmox-opensense/ — Terraform configs for provisioning the OPNsense firewall VM in Proxmox. This is a separate directory from the K3s cluster provisioning (`proxmox-kubernetes-cluster/`) to isolate the firewall configuration and avoid coupling it with cluster lifecycle.

## VM Configuration (current defaults)

| Setting | Value |
|---|---|
| VMID | 101 |
| Name | `opnsense-fw` |
| CPU | 2 cores |
| Memory | 6 GB |
| Disks | 1x 16 GB (SCSI) |
| Network Interfaces | 3x VirtIO (`vtnet0`, `vtnet1`, `vtnet2`) |
| Bridges | `vmbr0` (WAN), `vmbr1` (LAN), `vmbr2` (OPT1) |

> `vmbr-mgmt` (`10.10.99.0/24`) is **not** attached here — OPNsense does not route the management bridge.


## Commands

```bash
cd proxmox-infra/proxmox-opnsense/

# First-time init (or after provider changes)
terraform init

# Preview changes
terraform plan -var-file="values.tfvars"

# Apply
terraform apply -var-file="values.tfvars"

# Destroy VM
terraform destroy -var-file="values.tfvars"
```

## Secrets / Credentials

**WARNING:** `provider.tf` currently contains a hardcoded `pm_password`. Before committing any changes to that file:

1. Move credentials to environment variables:
   ```bash
   export PM_USER="vimal@pve"
   export PM_PASS="<password>"
   ```
   Then replace the `provider.tf` fields:
   ```hcl
   pm_user     = var.pm_user   # or omit and rely on PM_USER env var
   pm_password = var.pm_pass   # or omit and rely on PM_PASS env var
   ```
2. Add `*.tfvars` and `terraform.tfstate*` to `.gitignore` if not already present.
3. Never commit `terraform.tfstate` — it contains plaintext resource metadata.

## Provider

- **Source**: `Telmate/proxmox` v`3.0.2-rc06`
- **API endpoint**: `https://192.168.178.44:8006/api2/json`
- `pm_tls_insecure = true` — Proxmox uses a self-signed cert; acceptable on the private management network.

## Post-Terraform Steps

After `terraform apply`, OPNsense requires **manual first-boot setup** inside the Proxmox console:

1. Boot from ISO and run the installer.
2. Assign interfaces: WAN → `vtnet0`, LAN → `vtnet1`, OPT1 → `vtnet2`.
3. Set WAN IP (DHCP from home router on `vmbr0`).
4. Set LAN IP to `10.10.10.1/24`, OPT1 to `10.10.20.1/24`.
5. Configure DHCP server on LAN and OPT1.
6. Enable DNS-over-TLS (Cloudflare `1.1.1.1:853`) under Services → Unbound DNS.
7. Install and configure Suricata IDS/IPS.
8. Add firewall rules: block `vmbr1 ↔ vmbr2`, block `vmbr1/vmbr2 → vmbr-mgmt`, allow NAT egress.

## Lifecycle Note

`startup_shutdown` is in `ignore_changes` — Proxmox controls VM start/stop order independently of Terraform state.
