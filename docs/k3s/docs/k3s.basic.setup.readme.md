# K3S Quick Setup Guide 

K3s has become a popular choice for lightweight Kubernetes setups, especially for engineers who want to run Kubernetes outside of large cloud environments. Its reduced footprint, simplified installation, and minimal dependencies make it an excellent fit for home labs, edge deployments, and learning environments.

This article was written during the early phases of my home lab setup, where I am running k3s on Proxmox as the virtualization platform. The goal is to build a realistic, production-style Kubernetes environment at home while still keeping things efficient and manageable. As part of this journey, I chose Cilium as the core networking solution to replace traditional kube-proxy and iptables-based networking.

While this combination is powerful, it also introduces a few non-obvious requirements. In particular, disabling kube-proxy in k3s and enabling kube-proxy replacement in Cilium are not optional — they are fundamental to making the cluster work correctly.

This article explains why these steps are necessary, the problems you will encounter if they are skipped, and how to configure the setup correctly.

### kube-proxy Is Enabled by Default in k3s
By default, kube-proxy is part of every Kubernetes cluster, and k3s is no exception.

### When k3s is installed without additional flags:

* kube-proxy is automatically deployed
* It programs iptables-based service routing
* ClusterIP, NodePort, and LoadBalancer services rely on it
* This means that even if you install Cilium, kube-proxy will continue to exist unless it is explicitly disabled during the k3s installation.

***Installing Cilium alone does not remove kube-proxy.***

## Install k3s server
Firewall considerations

Disable the node-level firewall or
Explicitly allow traffic on port 6443/TCP between all cluster nodes

```bash
ufw disable
ufw status
```
## Install k3s server with kube-proxy disabled

```bash
curl -sfL https://get.k3s.io | sh -s - server \
  --node-ip=10.50.10.10 \ # Your controlplane IP (private ip)
  --advertise-address=10.50.10.10 \ # Your controlplane IP (private ip)
  --tls-san=10.50.10.10 \ # Your controlplane IP (private ip) or additional ip
  --flannel-backend=none \
  --disable-kube-proxy \
  --disable=traefik \
  --disable=servicelb \
  --disable-network-policy
```
## Why Traefik and ServiceLB Are Disabled ?

Traefik and ServiceLB are disabled, not because they are unsuitable, but to keep ingress decoupled from the cluster bootstrap, and ServiceLB is not suitable for Cilium EBPF-based service handling, and also lacks advanced load balancing

## k3s Agent (Worker Node) Installation

K3S supports both single-node and multi-node cluster setups.

For home labs and learning environments, it is very common to start with a single-node cluster, where the k3s server acts as both the control plane and worker node. In such cases, installing an agent node is optional.

However, when scaling out to a multi-node setup, additional nodes can be joined as agents (workers).

Become a member
Before installing an agent, retrieve the node token from the control-plane node:

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

On each worker node:

```bash
curl -sfL https://get.k3s.io | sh -s - agent \
  --server https://<control-plane-ip>:6443 \
  --token <node-token> \
  --node-ip <agent-node-ip>
```

## Installing Cilium as the Core Networking Layer

Once k3s is installed and the control plane is reachable, the next step is to install Cilium as the primary CNI and service routing engine for the cluster.

Cilium is installed after k3s because it depends on a running Kubernetes API server. At this stage, kube-proxy is already disabled, and Cilium will take full ownership of networking.

Export the KUBECONFIG environment variable for the Cilium CLI to connect to the cluster

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

### Install the Cilium CLI
```bash
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
```

```bash
cilium install --version 1.18.5 \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=10.50.10.10 \
  --set k8sServicePort=6443 \
  --set ipam.operator.clusterPoolIPv4PodCIDRList="10.42.0.0/16"
```

### When kubeProxyReplacement=true , Cilium:

- Implements ClusterIP, NodePort, and LoadBalancer services
- Uses eBPF instead of iptables
- Becomes the single source of truth for Kubernetes service routing
- Without this setting, disabling kube-proxy results in broken ClusterIP networking and causes controllers to fail.

Use the 'cilium status' command to view live information about the networking status.

```bash
cilium status --wait
    /¯¯\
 /¯¯\__/¯¯\    Cilium:             OK
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    OK
 \__/¯¯\__/    Hubble Relay:       disabled
    \__/       ClusterMesh:        disabled

DaemonSet              cilium                   Desired: 4, Ready: 4/4, Available: 4/4
DaemonSet              cilium-envoy             Desired: 4, Ready: 4/4, Available: 4/4
Deployment             cilium-operator          Desired: 1, Ready: 1/1, Available: 1/1
Containers:            cilium                   Running: 4
                       cilium-envoy             Running: 4
                       cilium-operator          Running: 1
                       clustermesh-apiserver    
                       hubble-relay             
Cluster Pods:          6/6 managed by Cilium
Helm chart version:    1.18.5
Image versions         cilium             quay.io/cilium/cilium:v1.18.5@sha256:2c92fb05962a346eaf0ce11b912ba434dc10bd54b9989e970416681f4a069628: 4
                       cilium-envoy       quay.io/cilium/cilium-envoy:v1.34.12-1765374555-6a93b0bbba8d6dc75b651cbafeedb062b2997716@sha256:3108521821c6922695ff1f6ef24b09026c94b195283f8bfbfc0fa49356a156e1: 4
                       cilium-operator    quay.io/cilium/operator-generic:v1.18.5@sha256:36c3f6f14c8ced7f45b40b0a927639894b44269dd653f9528e7a0dc363a4eb99: 1
```
### Validate the cluster networking using the
```bash
cilium connectivity test
```
## Additional Notes and Troubleshooting Tips
If you encounter any networking-related issues during or after the setup, always start with the basics before diving into deeper debugging.
* **Verify that Flannel is disabled**: Flannel is enabled by default in k3s and can silently conflict with Cilium if not disabled. This should always be the first networking check when troubleshooting unexpected behavior.
* **Confirm kube-proxy is disabled and not running**: Running kube-proxy alongside Cilium (with kube-proxy replacement enabled) can lead to unpredictable service routing.
* **Check node-to-node connectivity**: Ensure all nodes can reach the Kubernetes API server on port 6443/TCP, and that no firewall rules are blocking inter-node communication.
* **Validate Cilium health early**: Use `cilium status` to verify that all components are running correctly.
