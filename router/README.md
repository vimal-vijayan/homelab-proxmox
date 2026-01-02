# FritzBox Router Setup for Homelab Access

## Overview

This guide documents the FritzBox router configuration required to access internal applications running on the Kubernetes cluster and other private networks within the Proxmox homelab environment.

## Network Architecture Context

- **Kubernetes and internal networks** run on private networks under Proxmox
- **pfSense** acts as the firewall and router between network segments
- **FritzBox router** provides WiFi and main network connectivity
- To access internal applications from the WiFi network, both router and firewall configurations must be updated

## Prerequisites

- FritzBox router with admin access
- pfSense firewall configured and running
- Knowledge of your internal network topology and IP ranges
- Understanding of which applications/services need to be accessible from WiFi

## Configuration Steps

### 1. Plan Your Network Access

Before making changes, document:
- Internal application IPs/hostnames you want to expose
- Port numbers for each service
- Source networks that need access (e.g., WiFi VLAN)
- Security requirements and access restrictions

### 2. FritzBox Router Configuration

#### 2.1 Access FritzBox Admin Interface
1. Navigate to your FritzBox admin panel (typically `http://fritz.box` or `http://192.168.178.1`)
2. Log in with administrator credentials

#### 2.2 Configure Static Routes (if needed)
If your internal networks use different subnets than the FritzBox network:

1. Go to **Home Network** → **Network** → **Network Settings**
2. Navigate to **IPv4 Routes** section
3. Add static routes for your Proxmox/pfSense networks:
   - Destination: Internal network CIDR (e.g., `10.0.0.0/24`)
   - Gateway: pfSense WAN IP address
   - Click **Apply**

#### 2.3 Configure Port Forwarding (for external access)
If you need external internet access to internal services:

1. Go to **Internet** → **Permit Access** → **Port Forwarding**
2. Click **New Port Forwarding**
3. Configure:
   - **Device**: Select pfSense or specify IP
   - **Port**: External port number
   - **Protocol**: TCP/UDP/Both
   - **To port**: Internal port (if different)
4. Click **OK** to save

#### 2.4 DNS Configuration (optional)
For easier access using hostnames:

1. Go to **Home Network** → **Network** → **Network Settings**
2. Navigate to **DNS** section
3. Add DNS rebind protection exceptions if needed
4. Consider configuring DNS forwarding to pfSense for internal domain resolution

### 3. pfSense Firewall Configuration

#### 3.1 Create Firewall Rules

1. Log into pfSense web interface
2. Navigate to **Firewall** → **Rules**
3. Select the appropriate interface (e.g., WAN or WiFi VLAN)

#### 3.2 Allow Traffic from WiFi to Internal Networks

Create rules to allow access from WiFi network to internal services:

1. Click **Add** (↑ up arrow for top of list)
2. Configure the rule:
   - **Action**: Pass
   - **Interface**: WAN (or WiFi VLAN interface)
   - **Protocol**: TCP/UDP (as needed)
   - **Source**: WiFi network CIDR (e.g., `192.168.178.0/24`)
   - **Destination**: Internal service IP or network
   - **Destination Port**: Service port (e.g., 443 for HTTPS, 80 for HTTP)
   - **Description**: "Allow WiFi to K8s Service - [service name]"
3. Click **Save** and **Apply Changes**

#### 3.3 NAT Configuration (if needed)

If you need NAT/port forwarding through pfSense:

1. Navigate to **Firewall** → **NAT** → **Port Forward**
2. Click **Add** (↑)
3. Configure:
   - **Interface**: WAN
   - **Protocol**: TCP/UDP
   - **Destination**: WAN address
   - **Destination Port**: External port
   - **Redirect target IP**: Internal service IP
   - **Redirect target port**: Internal port
   - **Description**: Service description
4. Click **Save** and **Apply Changes**

### 4. Verification Steps

#### 4.1 Test Connectivity
From a device on the WiFi network:

```bash
# Test ICMP connectivity
ping <internal-service-ip>

# Test specific port
telnet <internal-service-ip> <port>
# or
nc -zv <internal-service-ip> <port>

# Test HTTP/HTTPS services
curl http://<internal-service-ip>:<port>
```

#### 4.2 Check pfSense Logs
1. Navigate to **Status** → **System Logs** → **Firewall**
2. Monitor for blocked/allowed connections
3. Verify your rules are being hit

#### 4.3 Verify MetalLB Load Balancer
If using MetalLB for Kubernetes services:

```bash
# Check MetalLB service IPs
kubectl get svc -A

# Verify IP assignments
kubectl describe svc <service-name> -n <namespace>
```

## Common Configurations

### Example 1: Expose Kubernetes Dashboard

**FritzBox:** No changes needed if on same network
**pfSense Firewall Rule:**
- Source: WiFi VLAN (192.168.178.0/24)
- Destination: K8s Dashboard Service IP (e.g., 10.0.50.10)
- Port: 443
- Protocol: TCP

### Example 2: Access Internal Web Application

**FritzBox Static Route:**
- Destination: 10.0.50.0/24 (K8s services network)
- Gateway: pfSense WAN IP

**pfSense Firewall Rule:**
- Source: Any (WiFi network)
- Destination: MetalLB service IP (e.g., 10.0.50.20)
- Port: 80, 443
- Protocol: TCP

## Security Considerations

1. **Principle of Least Privilege**: Only open necessary ports
2. **Source IP Restrictions**: Limit access to trusted networks when possible
3. **Use HTTPS**: Always prefer encrypted connections
4. **Monitor Logs**: Regularly review pfSense firewall logs
5. **Update Firewall Rules**: Remove unused rules periodically
6. **Consider VPN**: For sensitive services, use VPN instead of direct access
7. **Enable Logging**: Log all firewall rule hits for audit purposes

## Troubleshooting

### Cannot Reach Internal Service from WiFi

1. **Check FritzBox routing table**
   - Verify static routes are configured correctly
   - Confirm gateway IP matches pfSense WAN interface

2. **Verify pfSense firewall rules**
   - Check rule order (pfSense processes top to bottom)
   - Ensure source/destination IPs are correct
   - Verify no block rules above your allow rule

3. **Test from pfSense itself**
   - Use **Diagnostics** → **Ping** to test connectivity
   - Use **Diagnostics** → **Test Port** to verify service availability

4. **Check application logs**
   - Verify the service is running and listening
   - Check for application-level access restrictions

### DNS Not Resolving Internal Hostnames

1. Configure pfSense DNS resolver/forwarder
2. Add DNS override entries in pfSense
3. Update FritzBox to use pfSense as DNS server
4. Add manual DNS entries in FritzBox for internal domains

### Intermittent Connectivity Issues

1. Check for IP conflicts
2. Verify DHCP lease times and reservations
3. Monitor pfSense state table for connection limits
4. Check for MTU mismatches

## Related Documentation

- [Proxmox Setup Guide](../proxmox/docs/proxmox.setup.README.md)
- [pfSense Configuration](../proxmox/terraform/pfsense)
- [K3s Network Setup](../k3s/docs/k3s.network.readme.md)
- [MetalLB Configuration](../metalLB/README.md)

## References

- FritzBox Manual: [https://en.avm.de/service/fritzbox/](https://en.avm.de/service/fritzbox/)
- pfSense Documentation: [https://docs.netgate.com/pfsense/](https://docs.netgate.com/pfsense/)
- pfSense Firewall Rules: [https://docs.netgate.com/pfsense/en/latest/firewall/](https://docs.netgate.com/pfsense/en/latest/firewall/)
