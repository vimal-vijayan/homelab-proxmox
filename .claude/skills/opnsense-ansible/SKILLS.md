---
description: Execute ansibleguy.opnsense Ansible playbooks to configure OPNsense interfaces, firewall rules, NAT, DHCP, Unbound DNS, and Suricata IDS/IPS via the OPNsense REST API. Invoke with /opnsense-ansible <task> [--check].
---

# /opnsense-ansible — OPNsense Ansible Execution

Run `ansibleguy.opnsense` Ansible playbooks against the live OPNsense firewall at `10.10.10.1`. All changes go via the OPNsense REST API — no SSH to the firewall required.

## Invocation

```
/opnsense-ansible <task> [--check]
```

Where `<task>` is one of:

| Task | Playbook | What it configures |
|---|---|---|
| `all` | `site.yml` | Full baseline config in safe order |
| `interfaces` | `interfaces.yml` | WAN/LAN/OPT1/OPT2 IP assignments |
| `aliases` | `aliases.yml` | Network/host aliases used by rules |
| `firewall` | `firewall.yml` | All firewall rules (depends on aliases) |
| `nat` | `nat.yml` | Outbound NAT masquerade rules |
| `dhcp` | `dhcp.yml` | DHCP pools on LAN + OPT1 |
| `unbound` | `unbound.yml` | Unbound DNS + DNS-over-TLS to Cloudflare |
| `suricata` | `suricata.yml` | Suricata IDS/IPS interfaces + home networks |

Append `--check` to run in **dry-run mode** (no changes applied). Always run `--check` first on a production firewall.

---

## Paths

| Resource | Path |
|---|---|
| Ansible project root | `proxmox-infra/proxmox-opnsense/ansible/` |
| Inventory | `proxmox-infra/proxmox-opnsense/ansible/inventory.yml` |
| Group vars (credentials) | `proxmox-infra/proxmox-opnsense/ansible/group_vars/all.yml` |
| Site entry point | `proxmox-infra/proxmox-opnsense/ansible/site.yml` |

---

## Pre-flight Checks

Before running any playbook, perform these checks and **stop if any fail**:

### 1. Collection installed

```bash
ansible-galaxy collection list | grep ansibleguy.opnsense
```

If missing, install it:

```bash
ansible-galaxy collection install ansibleguy.opnsense
```

### 2. OPNsense API reachable

```bash
curl -sk -o /dev/null -w "%{http_code}" \
  https://10.10.10.1/api/core/firmware/status \
  -u "${OPNSENSE_API_KEY}:${OPNSENSE_API_SECRET}"
```

Expected: `200`. If not, stop and report: "OPNsense API not reachable at 10.10.10.1. Check API credentials and that you're on the Tailscale subnet or vmbr-mgmt."

### 3. Credentials available

Check that `OPNSENSE_API_KEY` and `OPNSENSE_API_SECRET` env vars are set **or** that `group_vars/all.yml` contains `opnsense_api_key` / `opnsense_api_secret`.

If neither is set, stop and prompt: "OPNsense API credentials not found. Set OPNSENSE_API_KEY and OPNSENSE_API_SECRET env vars, or add them to group_vars/all.yml."

---

## Execution

### Dry-run (--check)

```bash
cd proxmox-infra/proxmox-opnsense/ansible/
ansible-playbook -i inventory.yml <playbook>.yml --check --diff
```

Print the full diff output and ask: "Dry-run complete. Apply these changes? (yes/no)"
Do NOT proceed if the user answers no.

### Apply

```bash
cd proxmox-infra/proxmox-opnsense/ansible/
ansible-playbook -i inventory.yml <playbook>.yml
```

### Full baseline (`all`)

Run playbooks in this exact order — each depends on the previous:

```
1. aliases.yml      # aliases must exist before rules reference them
2. interfaces.yml   # interface IPs
3. firewall.yml     # rules reference aliases
4. nat.yml          # outbound NAT
5. dhcp.yml         # DHCP pools
6. unbound.yml      # DNS + DoT
7. suricata.yml     # IDS/IPS last (needs interfaces)
```

---

## Baseline Policy Guard

Before applying `firewall.yml`, verify the following rules are present in the generated task list. **If any are missing from the play output, stop and warn the user before proceeding:**

| Rule | Action |
|---|---|
| `vmbr1 ↔ vmbr2` (K8s ↔ SIEM) | BLOCK |
| `vmbr1 → vmbr-mgmt (10.10.99.0/24)` | BLOCK |
| `vmbr2 → vmbr-mgmt (10.10.99.0/24)` | BLOCK |
| `vmbr-mgmt → all` | ALLOW |
| `LAN/OPT1/MGMT → OPNsense port 53` | ALLOW |

These rules enforce network segmentation. Relaxing any BLOCK requires explicit user confirmation and a comment explaining the security implication.

---

## Error Handling

- **API 401**: Credentials wrong — stop, report, do not retry
- **API 403**: User lacks permission — stop, report "OPNsense API user needs appropriate privileges"
- **Task failed**: Stop immediately, print the failed task name and error message. Do not continue to the next playbook in a sequence.
- **Connectivity lost to OPNsense mid-run**: Stop, report which tasks completed. The OPNsense config may be partially applied — instruct user to verify via console.

---

## Completion Summary

After a successful apply, print:

```
OPNsense Ansible run complete.

  Playbook:   <name>
  Tasks:      X changed, Y ok, 0 failed
  Firewall:   https://10.10.10.1 (WebUI)

Applied changes — verify in OPNsense:
  - Firewall → Rules → [interface tabs]
  - Services → DHCPv4
  - Services → Unbound DNS → General
  - Services → Intrusion Detection → Administration
```

---

## Debugging Tips

```bash
# Verbose output — show API calls
ansible-playbook -i inventory.yml site.yml -v

# Very verbose — show full HTTP requests/responses
ansible-playbook -i inventory.yml site.yml -vvv

# Run a single role only
ansible-playbook -i inventory.yml site.yml --tags firewall

# List all tasks without running
ansible-playbook -i inventory.yml site.yml --list-tasks
```
