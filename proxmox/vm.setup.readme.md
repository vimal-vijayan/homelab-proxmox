# Install ubuntu 24.04 live server amd64 on a VM with:

- 2 vCPU
- 8 GB RAM
- 20 GB Disk


# Setup unique static IP address, e.g.

## Set static IP for ubuntu 24.04
```bash
sudo nano /etc/netplan/00-installer-config.yaml

network:
  version: 2
  renderer: networkd
  ethernets:
    ens19:
      addresses:
        - 10.50.10.10/24
      nameservers:
          addresses: [8.8.8.8, 1.1.1.1]
      routes:
        - to: default
          via: 10.50.10.1 # adjust the routes according to your setup / no routes instead use default gateway route
```

# Apply the netplan configuration
```bash
sudo netplan apply
```