---
description: Ansible playbook and role structure for provisioning the Proxmox K3s cluster and related infrastructure. This includes inventory layout, key commands, conventions, and patterns for idempotent configuration management.
disable-model-invocation: true
---

## Repo Context

| Directory | Purpose |
|---|---|
| `proxmox-infra/proxmox-kubernetes-cluster/` | K3s cluster provisioning |
| `proxmox-infra/proxomox-linux-bridge/` | Proxmox bridge/VLAN config via REST API |
| `proxmox-infra/proxmox-mgmt-config/` | Management VM config (Tailscale, PBS, Bastion) |

## Inventory Layout

K3s cluster inventory at `proxmox-infra/proxmox-kubernetes-cluster/inventory.yml`:

- `k3s_init` — first control-plane (10.50.10.20), bootstraps the cluster
- `k3s_join` — additional control-planes (10.50.10.21–22), join via `k3s_api_server`
- `k3s_nodes` — workers (10.50.10.30–32)
- SSH user: `ubuntu`, key: `~/.ssh/id_rsa`

Shared vars in `group_vars/all.yml`: `k3s_version`, `k3s_token`, `k3s_tls_sans`, `k3s_common_args`.

## Key Playbook Commands

```bash
# K3s cluster
cd proxmox-infra/proxmox-kubernetes-cluster/
ansible-playbook -i inventory.yml setup-hosts.yml      # hostname + static IP
ansible-playbook -i inventory.yml install-k3s.yml      # K3s install + join

# Proxmox bridge config (REST API — no SSH to Proxmox host)
cd proxmox-infra/proxomox-linux-bridge/ansible/
ansible-playbook -i inventory/hosts.ini site.yml

# Management VMs (after Terraform provisioning)
cd proxmox-infra/proxmox-mgmt-config/
ansible-playbook -i inventory.yml setup-hosts.yml      # hostname + netplan static IP
ansible-playbook -i inventory.yml site.yml             # per-role config
```

## Conventions for This Repo

- **Static IPs via netplan** — `setup-hosts.yml` writes `/etc/netplan/99-homelab.yaml` and applies it
- **No SSH to Proxmox host** — bridge playbooks use the Proxmox REST API (token auth), not SSH
- **Role structure** mirrors `proxmox-kubernetes-cluster/`: `inventory.yml`, `group_vars/all.yml`, `setup-hosts.yml`, `roles/`
- **Idempotency** — all tasks must be idempotent; use `ansible.builtin` modules, not raw shell where a module exists
- **Privilege escalation** — use `become: true` only at the task level, not playbook-wide, unless every task needs root

## Static IP Netplan Template

Use this pattern in `setup-hosts.yml` for any VM on an internal bridge:

```yaml
- name: Write netplan config
  ansible.builtin.template:
    src: templates/netplan.j2
    dest: /etc/netplan/99-homelab.yaml
    mode: "0600"
  become: true

- name: Apply netplan
  ansible.builtin.command: netplan apply
  become: true
  changed_when: true
```

Template (`templates/netplan.j2`):
```yaml
network:
  version: 2
  ethernets:
    {{ ansible_default_ipv4.interface }}:
      addresses: ["{{ static_ip }}"]
      routes:
        - to: default
          via: "{{ gateway }}"
      nameservers:
        addresses: ["{{ dns_server }}"]
```

## IP / Gateway Reference

| Host group | Subnet | Gateway | DNS |
|---|---|---|---|
| k3s_* | 10.50.10.0/24 | 10.50.10.1 | 10.10.10.1 |
| mgmt VMs | 10.10.99.0/24 | 10.10.99.1 | 10.10.10.1 |
| SIEM VMs | 10.10.20.0/24 | 10.10.20.1 | 10.10.10.1 |

## Common Patterns

### Run only on specific hosts

```bash
ansible-playbook -i inventory.yml install-k3s.yml --limit k3s_init
```

### Dry-run / check mode

```bash
ansible-playbook -i inventory.yml setup-hosts.yml --check --diff
```

### Ad-hoc connectivity test

```bash
ansible all -i inventory.yml -m ping
```

### Run a single task by tag

```bash
ansible-playbook -i inventory.yml install-k3s.yml --tags k3s_install
```

## Role Skeletons

### New role

```bash
ansible-galaxy init roles/<role-name>
```

Minimal structure needed:
```
roles/<role-name>/
├── tasks/main.yml
├── defaults/main.yml   # role defaults (overridable)
└── templates/          # Jinja2 templates if needed
```

### Handler pattern for service restarts

```yaml
# tasks/main.yml
- name: Configure foo
  ansible.builtin.template:
    src: foo.conf.j2
    dest: /etc/foo/foo.conf
  notify: Restart foo

# handlers/main.yml
- name: Restart foo
  ansible.builtin.systemd:
    name: foo
    state: restarted
```

## Secrets / Sensitive Values

- Never commit `k3s_token`, API tokens, or passwords to the repo
- Store secrets in `group_vars/all.yml` only for local dev; use Ansible Vault for anything committed:
  ```bash
  ansible-vault encrypt_string 'secret' --name 'k3s_token'
  ```
- For Proxmox API token auth in bridge playbooks: use `PROXMOX_API_TOKEN` env var, not hardcoded values

## Debugging Tips

```bash
# Verbose output (show task details)
ansible-playbook -i inventory.yml install-k3s.yml -v

# Very verbose (show SSH connection details)
ansible-playbook -i inventory.yml install-k3s.yml -vvv

# Print all variables for a host
ansible -i inventory.yml k3s-server-01 -m debug -a "var=hostvars[inventory_hostname]"
```
