# OPNsense Ansible Configuration

Automates OPNsense post-boot configuration via the [`ansibleguy.opnsense`](https://github.com/ansibleguy/collection_opnsense) collection. All changes go through the OPNsense REST API — **no SSH to the firewall required**.

## Prerequisites

```bash
# Install the collection
ansible-galaxy collection install -r requirements.yml

# Set API credentials (generate in OPNsense: System → Access → Users → [user] → API keys)
export OPNSENSE_API_KEY="<your-api-key>"
export OPNSENSE_API_SECRET="<your-api-secret>"
```

## Usage

```bash
cd proxmox-infra/proxmox-opnsense/ansible/

# Dry-run everything (always do this first)
ansible-playbook -i inventory.yml site.yml --check --diff

# Apply full baseline
ansible-playbook -i inventory.yml site.yml

# Apply a single component
ansible-playbook -i inventory.yml aliases.yml
ansible-playbook -i inventory.yml firewall.yml
ansible-playbook -i inventory.yml nat.yml
ansible-playbook -i inventory.yml dhcp.yml
ansible-playbook -i inventory.yml unbound.yml
ansible-playbook -i inventory.yml suricata.yml

# Run a specific tag across all playbooks
ansible-playbook -i inventory.yml site.yml --tags firewall

# Verbose (show API calls)
ansible-playbook -i inventory.yml site.yml -v
```

> Use the `/opnsense-ansible` Claude Code skill for guided execution with pre-flight checks and completion summaries.

## Playbook Order

Run order matters — aliases must exist before firewall rules reference them:

```
1. aliases.yml      → network/host aliases
2. interfaces.yml   → LAN/OPT1/OPT2 IP assignments
3. firewall.yml     → segmentation + egress rules
4. nat.yml          → outbound NAT masquerade
5. dhcp.yml         → dynamic pools on LAN + OPT1
6. unbound.yml      → DNS + DNS-over-TLS to Cloudflare
7. suricata.yml     → IDS/IPS (start in IDS mode)
```

`site.yml` runs them in this order automatically.

## Suricata IDS vs IPS

Suricata defaults to **IDS mode** (alerts only). To promote to IPS (active blocking) after validating no false positives:

```bash
ansible-playbook -i inventory.yml suricata.yml -e "suricata_ips_mode=true"
```

## Structure

```
ansible/
├── inventory.yml           # OPNsense host (REST API, not SSH)
├── group_vars/all.yml      # Credentials + network vars
├── requirements.yml        # ansibleguy.opnsense collection
├── site.yml                # Full baseline (ordered)
├── aliases.yml             # Individual component playbooks
├── interfaces.yml
├── firewall.yml
├── nat.yml
├── dhcp.yml
├── unbound.yml
├── suricata.yml
└── roles/
    ├── aliases/tasks/main.yml
    ├── interfaces/tasks/main.yml
    ├── firewall/tasks/main.yml
    ├── nat/tasks/main.yml
    ├── dhcp/tasks/main.yml
    ├── unbound/tasks/main.yml
    └── suricata/tasks/main.yml
```
