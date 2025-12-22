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

From chatGPT

curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz
sudo tar -C /usr/local/bin -xzf cilium-linux-amd64.tar.gz
cilium version

Install Cilium for k3s API server (yours is 10.50.10.1:6443). Also set a Pod CIDR pool (pick one that doesn’t overlap your LANs):
```bash
cilium install \
  --set k8sServiceHost=10.50.10.1 \
  --set k8sServicePort=6443 \
  --set kubeProxyReplacement=true \
  --set ipam.mode=cluster-pool \
  --set ipam.operator.clusterPoolIPv4PodCIDR=10.52.0.0/16 \
  --set ipam.operator.clusterPoolIPv4MaskSize=24
```

Then wait and check:
```bash
cilium status --wait
sudo kubectl get nodes -o wide
sudo kubectl get pods -A
```

Sanity test
```bash
cilium connectivity test
```

4) Add worker nodes (after Cilium is healthy)
On the server, get the join token:
```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

On each worker:
```bash
curl -sfL https://get.k3s.io | K3S_URL="https://10.50.10.1:6443" K3S_TOKEN="THE_TOKEN" sh -s - \
  --flannel-backend none \
  --node-ip <worker-ip-on-10.50.10.0/24>
```