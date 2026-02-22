# K3s HA Setup with Embedded etcd and kube-vip

This guide sets up a 3-node K3s control plane with:

- Embedded etcd (HA control plane)
- `kube-vip` for a highly available Kubernetes API virtual IP (VIP)
- Cilium with kube-proxy replacement

## Target Topology

- `cp01`: `10.50.10.20`
- `cp02`: `10.50.10.21`
- `cp03`: `10.50.10.22`
- API VIP (kube-vip): `10.50.10.200`
- Example DNS SAN: `homelab.cluster.yuxep.com`
- Example LAN SAN: `192.168.178.65`

## Prerequisites

- Ubuntu nodes can reach each other on required Kubernetes/K3s ports.
- `curl` is installed on all control-plane nodes.
- `jq` is installed on the node where you generate kube-vip manifests.
- Use the correct NIC name for your servers (example below uses `ens18`).

## 1) Bootstrap first control-plane node (`cp01`)

Run on `10.50.10.20`:

```bash
curl -sfL https://get.k3s.io | sh -s - server \
  --node-ip=10.50.10.20 \
  --cluster-init \
  --flannel-backend=none \
  --disable-network-policy \
  --disable=traefik \
  --disable=servicelb \
  --disable-kube-proxy \
  --tls-san=192.168.178.65 \
  --tls-san=homelab.cluster.yuxep.com \
  --tls-san=10.50.10.20 \
  --tls-san=10.50.10.200
```

Get the server token from `cp01`:

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

## 2) Join additional control-plane nodes (`cp02`, `cp03`)

Run on `10.50.10.21` (`cp02`):

```bash
curl -sfL https://get.k3s.io | sh -s - server \
  --server https://10.50.10.20:6443 \
  --node-ip=10.50.10.21 \
  --flannel-backend=none \
  --disable-network-policy \
  --disable=traefik \
  --disable=servicelb \
  --disable-kube-proxy \
  --tls-san=192.168.178.65 \
  --tls-san=10.50.10.20 \
  --tls-san=10.50.10.200 \
  --token "<SERVER_TOKEN>"
```

Run on `10.50.10.22` (`cp03`):

```bash
curl -sfL https://get.k3s.io | sh -s - server \
  --server https://10.50.10.20:6443 \
  --node-ip=10.50.10.22 \
  --flannel-backend=none \
  --disable-network-policy \
  --disable=traefik \
  --disable=servicelb \
  --disable-kube-proxy \
  --tls-san=192.168.178.65 \
  --tls-san=10.50.10.20 \
  --tls-san=10.50.10.200 \
  --token "<SERVER_TOKEN>"
```

## 3) Install kube-vip as control-plane load balancer

On a control-plane node (usually `cp01`):

```bash
curl https://kube-vip.io/manifests/rbac.yaml \
  > /var/lib/rancher/k3s/server/manifests/kube-vip-rbac.yaml
```

Set variables:

```bash
export VIP=10.50.10.200
export INTERFACE=ens19
export KVVERSION=$(curl -sL https://api.github.com/repos/kube-vip/kube-vip/releases | jq -r ".[0].name")
echo "$KVVERSION"
```

Create alias:

```bash
alias kube-vip="ctr image pull ghcr.io/kube-vip/kube-vip:$KVVERSION; ctr run --rm --net-host ghcr.io/kube-vip/kube-vip:$KVVERSION vip /kube-vip"
```

Generate and apply kube-vip daemonset manifest:

```bash
kube-vip manifest daemonset \
  --interface "$INTERFACE" \
  --address "$VIP" \
  --inCluster \
  --taint \
  --controlplane \
  --arp \
  --leaderElection \
  | sudo tee /var/lib/rancher/k3s/server/manifests/kube-vip-ds.yaml >/dev/null
```

Check daemonset and pods:

```bash
sudo k3s kubectl -n kube-system get ds kube-vip-ds -o wide
sudo k3s kubectl -n kube-system get pods -l app.kubernetes.io/name=kube-vip-ds -o wide
```

## 4) Test API VIP failover (run once)

1. Identify the node currently holding the VIP.
2. Stop K3s on that node:

```bash
sudo systemctl stop k3s
```

3. Verify another control-plane node acquires the VIP within a few seconds:

```bash
ip -o -4 addr show dev ens19 | grep 10.50.10.200
```

4. Start K3s again on the stopped node:

```bash
sudo systemctl start k3s
```

## 5) K3s Agent (Worker Node) Installation

K3s supports both single-node and multi-node cluster setups.

For home labs and learning environments, it is very common to start with a single-node cluster, where the K3s server acts as both control plane and worker node. In such cases, installing an agent node is optional.

However, when scaling out to a multi-node setup, additional nodes can be joined as agents (workers).

Before installing an agent, retrieve the node token from a control-plane node:

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

On each worker node, join using the HA API endpoint (VIP):

```bash
curl -sfL https://get.k3s.io | sh -s - agent \
  --server https://10.50.10.200:6443 \
  --token "<SERVER_TOKEN>" \
  --node-ip "<WORKER_NODE_IP>"
```

## 6) Install Cilium (initial install via `cp01` endpoint)

Install Cilium first using a real reachable API endpoint, then switch to VIP:

```bash
cilium install --version 1.18.5 \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=10.50.10.20 \
  --set k8sServicePort=6443 \
  --set ipam.operator.clusterPoolIPv4PodCIDRList="10.42.0.0/16"
```

## 7) Confirm VIP assignment and switch Cilium to HA endpoint

Verify VIP exists on the active control-plane node:

```bash
ip -o -4 addr show dev ens18 | grep 10.50.10.200 || true
```

Upgrade Cilium to point to the HA API VIP:

```bash
cilium upgrade --version 1.18.5 \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=10.50.10.200 \
  --set k8sServicePort=6443 \
  --set ipam.operator.clusterPoolIPv4PodCIDRList="10.42.0.0/16"
```

## 8) Restart kube-vip pods

```bash
sudo k3s kubectl -n kube-system delete pod -l app.kubernetes.io/name=kube-vip-ds
sudo k3s kubectl -n kube-system get pods -l app.kubernetes.io/name=kube-vip-ds -o wide
```

## Validation Checklist

- `kubectl get nodes` shows all 3 control-plane nodes `Ready`.
- `kube-vip-ds` is running on control-plane nodes.
- API VIP `10.50.10.200` moves to another control-plane node during failover.
- `cilium status --wait` reports healthy status.
