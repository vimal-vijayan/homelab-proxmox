---
description: Provisions the bastion VM end-to-end: starts MinIO (Terraform S3 backend), runs Terraform to create the VM, then hands off to Ansible for host configuration. Handles the interactive gate between Terraform and Ansible where the bootstrap DHCP IP is required.
---

# Provision Bastion — 3-Stage Pipeline

Orchestrate the full bastion VM lifecycle in order:
1. MinIO (S3 backend) → 2. Terraform (VM provisioning) → 3. Ansible (VM configuration)

## Invocation

```
/provision-bastion <action>
```

Where `<action>` is one of: `apply`, `plan`, `destroy`

If no action is provided, default to `plan`.

---

## Paths (absolute, never change)

| Resource | Path |
|---|---|
| MinIO docker-compose | `/Users/vimalvijayan/Documents/Learning/homelab-proxmox/utilities/Minio/docker-compose.yml` |
| Terraform dir | `/Users/vimalvijayan/Documents/Learning/homelab-proxmox/proxmox-infra/proxmox-mgmt/bastion/terraform/` |
| Ansible dir | `/Users/vimalvijayan/Documents/Learning/homelab-proxmox/proxmox-infra/proxmox-mgmt/bastion/ansible/` |
| MinIO S3 endpoint | `http://localhost:9000` |
| MinIO bucket | `proxmox-infra-mgmt-bastio` |

---

## Stage 1 — MinIO Health Check

Before doing anything, check if MinIO is already running and healthy:

```bash
curl -sf http://localhost:9000/minio/health/live
```

- If healthy → skip docker compose, print "MinIO already running — skipping."
- If not healthy → start it:

```bash
docker compose -f /Users/vimalvijayan/Documents/Learning/homelab-proxmox/utilities/Minio/docker-compose.yml up -d
```

Then wait for healthy (poll up to 30s):

```bash
for i in $(seq 1 10); do
  curl -sf http://localhost:9000/minio/health/live && echo "MinIO ready" && break
  echo "Waiting for MinIO... ($i/10)"
  sleep 3
done
```

If MinIO never becomes healthy after 30s, stop and report the failure. Do not continue to Terraform.

Verify the S3 bucket exists. If not, create it:

```bash
AWS_ACCESS_KEY_ID=minioadmin AWS_SECRET_ACCESS_KEY=minioadmin \
  aws s3 mb s3://proxmox-infra-mgmt-bastio \
  --endpoint-url http://localhost:9000 \
  --region us-east-1 2>/dev/null || echo "Bucket already exists"
```

---

## Stage 2 — Terraform

Working directory: `/Users/vimalvijayan/Documents/Learning/homelab-proxmox/proxmox-infra/proxmox-mgmt/bastion/terraform/`

### Pre-flight checks

1. Check `terraform.tfvars` exists — if missing, warn the user: "terraform.tfvars not found. Ensure PM credentials are set via TF_VAR_pm_user / TF_VAR_pm_password env vars or create terraform.tfvars."
2. Check `.terraform/` exists — if missing, run `terraform init` first.

### For `plan` action

```bash
cd /Users/vimalvijayan/Documents/Learning/homelab-proxmox/proxmox-infra/proxmox-mgmt/bastion/terraform/
terraform plan -var-file="terraform.tfvars"
```

Print the plan output. Do not proceed to Ansible for `plan` — stop here.

### For `apply` action

```bash
cd /Users/vimalvijayan/Documents/Learning/homelab-proxmox/proxmox-infra/proxmox-mgmt/bastion/terraform/
terraform apply -var-file="terraform.tfvars" -auto-approve
```

If `apply` fails, stop immediately and report the error. Do not proceed to Ansible.

### For `destroy` action

```bash
cd /Users/vimalvijayan/Documents/Learning/homelab-proxmox/proxmox-infra/proxmox-mgmt/bastion/terraform/
terraform destroy -var-file="terraform.tfvars" -auto-approve
```

For `destroy`, do not proceed to Ansible after completion — just report success.

---

## Stage 3 — Ansible (only runs after successful `apply`)

After Terraform apply succeeds, wait 30 seconds for cloud-init to complete before running Ansible:

```bash
echo "Waiting 30s for cloud-init to complete..."
sleep 30
```

The bootstrap IP is statically assigned via cloud-init: `192.168.178.35` (vmbr0 WAN interface). No manual lookup required.

### Step 3a — setup-hosts.yml (bootstrap via static WAN IP)

```bash
cd /Users/vimalvijayan/Documents/Learning/homelab-proxmox/proxmox-infra/proxmox-mgmt/bastion/ansible/
ansible-playbook -i inventory.yml setup-hosts.yml \
  -e "ansible_host=192.168.178.35"
```

If this playbook fails, stop and report the error. After `setup-hosts.yml` applies netplan, the VM switches to its static IP (`10.10.99.30`). SSH via the bootstrap IP will drop — this is expected.

### Step 3b — site.yml (via static IP)

Wait 10 seconds for netplan to settle, then:

```bash
cd /Users/vimalvijayan/Documents/Learning/homelab-proxmox/proxmox-infra/proxmox-mgmt/bastion/ansible/
ansible-playbook -i inventory.yml site.yml
```

This connects via `ansible_host: 10.10.99.30` as defined in `inventory.yml`.

---

## Completion Summary

After all stages complete, print a summary:

```
Bastion provisioning complete.

  VM:        bastion (VMID 111)
  Mgmt IP:   10.10.99.30 (vmbr99 / vmbr-mgmt)
  Bridge:    vmbr0 (WAN, break-glass DHCP)
  SSH:       ssh ubuntu@10.10.99.30

Next steps (manual):
  - Verify Tailscale subnet router can reach 10.10.99.30
  - Confirm OPNsense firewall rule: vmbr-mgmt → all ALLOWED
  - Test break-glass: ssh ubuntu@<dhcp-ip> (WAN fallback)
```

---

## Error Handling Rules

- Never skip a stage on failure — stop and surface the error clearly.
- Never run `terraform apply` without first confirming MinIO is healthy.
- Never run Ansible without first confirming Terraform apply succeeded.
- Never auto-approve `terraform destroy` without confirming the action with the user first — print "About to destroy the bastion VM (VMID 111). Confirm? (yes/no)" and wait.
