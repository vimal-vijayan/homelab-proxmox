# Terraform Skill — Proxmox Homelab

Assist the user with Terraform operations across the homelab Proxmox infrastructure.

## Terraform Projects

| Directory | What it provisions |
|---|---|
| `proxmox-infra/proxmox-opnsense/` | OPNsense firewall VM (VMID 101) |
| `docs/proxmox/terraform/kubernetes/` | K3s control-plane + worker VMs via `for_each` |
| `docs/proxmox/terraform/pfsense/` | Legacy pfSense VM (reference only) |

## Provider

All projects use `Telmate/proxmox` v`3.0.2-rc06` against `https://192.168.178.44:8006/api2/json` with `pm_tls_insecure = true` (self-signed cert).

## Credentials

Never hardcode credentials. Supply via env vars:
```bash
export TF_VAR_pm_user="vimal@pve"
export TF_VAR_pm_password="<password>"
```

`values.tfvars` holds non-secret overrides (ISO path, storage pool, VMID). Never commit `*.tfvars` or `*.tfstate*`.

## State Backend (MinIO on localhost)

All projects should use this backend block:
```hcl
terraform {
  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "<project-name>/terraform.tfstate"
    endpoint                    = "http://localhost:9000"
    region                      = "us-east-1"
    access_key                  = "minioadmin"
    secret_key                  = "minioadmin"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    force_path_style            = true
  }
}
```

MinIO runs locally on the Mac (`brew install minio`). Start with:
```bash
minio server ~/minio-data --console-address ":9001"
```

## Common Commands

```bash
cd <project-dir>

terraform init                          # first-time or after backend/provider changes
terraform plan -var-file="values.tfvars"
terraform apply -var-file="values.tfvars"
terraform destroy -var-file="values.tfvars"

# After migrating to MinIO backend
terraform init -migrate-state
```

## Network Bridges

Proxmox bridge names must be alphanumeric only — no hyphens. Use:
- `vmbr0` — WAN (192.168.178.44/24, physical NIC `nic1`)
- `vmbr1` — K8s LAN (10.10.10.0/24)
- `vmbr2` — SIEM (10.10.20.0/24)
- `vmbr99` — Management (10.10.99.0/24) — **not attached to OPNsense VM**

## Lifecycle Notes

- `startup_shutdown` is always in `ignore_changes` — Proxmox controls VM boot order independently.
- VMs are provisioned from ISO (CD-ROM on scsi0) + blank disk (scsi1, 20G on `nvme` storage pool).
- K3s VMs use `for_each` over `locals.tf` — add/remove VMs by editing the locals, not the resource block.
- After `terraform apply`, VMs need manual or Ansible-driven OS setup — Terraform only creates the VM shell.

## .gitignore Requirements

Ensure these are present:
```
*.tfvars
*.tfstate
*.tfstate.backup
.terraform/
.terraform.lock.hcl
```
