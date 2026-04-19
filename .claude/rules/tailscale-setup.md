
# Tailscale subnet routers (tailnet) Setup Instructions

# doc: https://tailscale.com/docs/features/subnet-routers?tab=linux

# installation steps
1. Install the Tailscale client
```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

2. Enable IP forwarding
When enabling IP forwarding, ensure your firewall denies traffic forwarding by default. This is the default setting for standard firewalls like ufw and firewalld. Blocking traffic forwarding by default prevents unintended routing of traffic.

IP forwarding is required to use a Linux device as a subnet router. This kernel setting lets the system forward network packets between interfaces, essentially functioning as a router. The process for enabling IP forwarding varies between Linux distributions. However, the following instructions work in most cases.

If your Linux system has a /etc/sysctl.d directory, use:

```bash
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```

Otherwise, use:

```bash
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf
```

3. Advertise subnet routes
After you enable IP forwarding, run tailscale set with the --advertise-routes flag. It accepts a comma-separated list of subnet routes.

```bash
sudo tailscale set --advertise-routes=10.10.10.0/24,10.10.20.0/24,10.10.99.0/24
```

This advertises all three private subnets:
- `10.10.10.0/24` — K8s LAN (vmbr1)
- `10.10.20.0/24` — SIEM lab (vmbr2)
- `10.10.99.0/24` — Management bridge (vmbr-mgmt)

The Tailscale VM sits at `10.10.99.10` on vmbr-mgmt and reaches the internet via OPNsense NAT.

If the device is authenticated by a user who can advertise the specified route in autoApprovers, the subnet router's routes will automatically be approved. You can also advertise any subset of the routes allowed by autoApprovers in the tailnet policy file. If you'd like to expose default routes (0.0.0.0/0 and ::/0), consider using exit nodes instead.