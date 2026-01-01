# Custom CNI Cilium with K3s


## Overview
This guide provides instructions on how to set up K3s with a custom CNI plugin,

specifically Cilium, by disabling the default Flannel CNI and configuring K3s accordingly.


## Prerequisites
### Remove existing Cilium interfaces
```bash
ip link delete cilium_host
ip link delete cilium_net
ip link delete cilium_vxlan
```

### Remove ip table rules related to cilium
```bash
iptables-save | grep -iv cilium | iptables-restore
ip6tables-save | grep -iv cilium | ip6tables-restore
```



## Step 1: K3s Server setup with Flannel disabled
```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - --flannel-backend none --node-ip=10.50.10.1 --advertise-address=10.50.10.1 --tls-san=192.168.178.53

or 

k3s server --flannel-backend=none --disable-network-policy --node-ip=10.50.10.1 \
  --advertise-address=10.50.10.1  \
  --tls-san=192.168.178.53


or 

sudo mkdir -p /etc/rancher/k3s
sudo tee /etc/rancher/k3s/config.yaml >/dev/null <<'EOF'
flannel-backend: "none"
node-ip: 10.50.10.1
tls-san: 
  - 192.168.178.53
disable:
  - traefik
  - servicelb
EOF

sudo systemctl restart k3s
```

## Step 2: Install Cilium

https://docs.cilium.io/en/stable/installation/k3s/

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--flannel-backend=none --disable-network-policy' sh -
```

### Install Agent Nodes (Optional)

```bash
curl -sfL https://get.k3s.io | K3S_URL='https://${MASTER_IP}:6443' K3S_TOKEN=${NODE_TOKEN} sh -
```
Install Cilium

```bash
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
```

Install Cilium by running:
```bash
  cilium install --version 1.18.5 --set=ipam.operator.clusterPoolIPv4PodCIDRList="10.42.0.0/16" --set kubeProxyReplacement=true

  example :

  cilium install \
  --version 1.18.5 \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=10.50.10.10 \
  --set k8sServicePort=6443 \
  --set ipam.mode=kubernetes \
  --wait
```

Validate the Installation
```bash
cilium status --wait
```

Run the following command to validate that your cluster has proper network connectivity:
```bash
cilium connectivity test
```
