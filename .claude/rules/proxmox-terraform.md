# Proxmox Terraform Instructions

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
