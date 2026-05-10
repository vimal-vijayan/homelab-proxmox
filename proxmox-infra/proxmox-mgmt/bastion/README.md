# Bastion VM

SSH break-glass host on `vmbr-mgmt` (`10.10.99.30`) — used when Tailscale is unavailable.

## Directory Layout

```
bastion/
├── terraform/   # Proxmox VM provisioning
└── ansible/     # Host configuration (SSH hardening, fail2ban, packages)
```

---

## End-to-End Provisioning Steps

### Step 1 — Start MinIO (Terraform S3 Backend)

Terraform state is stored in a local MinIO instance. It must be running before any `terraform` command.

```bash
cd utilities/Minio/
docker compose up -d

# Verify it is healthy
docker compose ps
```

MinIO console: http://localhost:9001 (user: `minioadmin`, password: `minioadmin`)

Create the state bucket if it does not already exist:

```bash
# Using the mc CLI
mc alias set local http://localhost:9000 minioadmin minioadmin
mc mb local/proxmox-infra-mgmt-bastio
```

---

### Step 2 — Terraform: Provision the VM

#### Prerequisites

The Ubuntu cloud image ships with `PasswordAuthentication no` enforced via `/etc/ssh/sshd_config.d/60-cloudimg-settings.conf`. This cannot be overridden at runtime — an SSH public key **must** be injected via cloud-init so Ansible can connect from first boot.

Add your public key to `terraform.tfvars` before applying:

```bash
# Print your public key
cat ~/.ssh/id_rsa.pub
```

```hcl
# terraform.tfvars
ci_ssh_public_key = "ssh-rsa AAAA... you@machine"
```

#### Apply

```bash
cd proxmox-infra/proxmox-mgmt/bastion/terraform/

# Set Proxmox credentials — never commit these
export TF_VAR_pm_user="vimal@pve"
export TF_VAR_pm_password="<proxmox-password>"
export TF_VAR_ci_password="<cloud-init-password>"

# First-time only (or after provider/backend changes)
terraform init

# Preview
terraform plan

# Apply
terraform apply
```

This creates the VM with two NICs:
- `ens18` → `vmbr99` (vmbr-mgmt) — static `10.10.99.30/24`
- `ens19` → `vmbr0` — static bootstrap IP `192.168.178.35/24` (cloud-init, WAN)

---

### Step 3 — Ansible: Configure the VM

The VM is only reachable via the bootstrap WAN IP (`192.168.178.35`) on first boot. `inventory.yml` defaults `ansible_host` to this address and disables host key checking for the fresh VM. Authentication uses the SSH key injected in Step 2 — password auth is disabled by the cloud image.

#### 3a — Setup hostname and static IP (run first)

```bash
cd proxmox-infra/proxmox-mgmt/bastion/ansible/

ansible-playbook -i inventory.yml setup-hosts.yml --ask-become-pass
```

#### 3b — Switch to the static management IP

Once `setup-hosts.yml` completes, update `ansible_host` in `inventory.yml`:

```yaml
ansible_host: 10.10.99.30   # static IP — vmbr-mgmt
```

#### 3c — Apply full configuration

```bash
ansible-playbook -i inventory.yml site.yml
```

---

## Network Interfaces

| Interface | Bridge | IP | Purpose |
|---|---|---|---|
| `ens18` | `vmbr99` (vmbr-mgmt) | `10.10.99.30/24` | Primary — management network |
| `ens19` | `vmbr0` | `192.168.178.35/24` (static, cloud-init) | Break-glass bootstrap only |

Gateway: `10.10.99.1` (OPNsense `vmbr-mgmt` interface)

---

## Firewall Rules (OPNsense)

- `vmbr-mgmt → all` — ALLOWED
- `vmbr1 → vmbr-mgmt` — BLOCKED
- `vmbr2 → vmbr-mgmt` — BLOCKED

---

## Terraform State Backend

State is stored in MinIO at `http://localhost:9000`:

| Setting | Value |
|---|---|
| Bucket | `proxmox-infra-mgmt-bastio` |
| Key | `proxmox-mgmt-bastion/terraform.tfstate` |
| Access key | `minioadmin` |
| Secret key | `minioadmin` |

MinIO data is persisted in a named Docker volume (`minio-data`). Stop with `docker compose down` — do **not** use `docker compose down -v` or state will be lost.
